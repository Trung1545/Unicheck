import sys
from pathlib import Path
import pytest
import bcrypt

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config import DEFAULT_TEST_PASSWORD, SYNTHETIC_EMAIL_DOMAIN
from scrapers.fptu_scraper import FptuPublicScraper
from generators.synthetic_generator import FptSyntheticGenerator
from transformers.data_validator import DataValidator
from exporters.sql_exporter import SqlSeedExporter
from models import MasterDataset, TimetableSlotRecord

def test_password_hash_bcrypt_compatibility():
    generator = FptSyntheticGenerator(password=DEFAULT_TEST_PASSWORD)
    # Verify BCrypt verification works
    assert bcrypt.checkpw(DEFAULT_TEST_PASSWORD.encode("utf-8"), generator.password_hash.encode("utf-8"))

def test_synthetic_counts_and_domain_safety():
    scraper = FptuPublicScraper(dry_run=True)
    majors, specs, courses, prereqs, semesters, slot_types = scraper.scrape_curriculum_catalog()

    generator = FptSyntheticGenerator(password=DEFAULT_TEST_PASSWORD)
    rooms, wifi_aps = generator.generate_rooms_and_wifi()
    users, student_profiles, lecturer_profiles = generator.generate_users()
    classes, enrollments = generator.generate_classes_and_enrollments(users)
    timetable_slots, attendance_sessions, student_attendances = generator.generate_timetables_and_attendance(
        classes, enrollments, rooms
    )

    lecs = [u for u in users if u.role == "LECTURER"]
    stus = [u for u in users if u.role == "STUDENT"]

    # Exact metrics required by prompt
    assert len(lecs) == 8, f"Expected 8 lecturers, got {len(lecs)}"
    assert len(stus) == 60, f"Expected 60 students, got {len(stus)}"
    assert len(classes) == 8, f"Expected 8 classes, got {len(classes)}"
    assert len(enrollments) == 200, f"Expected 200 enrollments, got {len(enrollments)}"
    assert len(timetable_slots) == 120, f"Expected 120 slots, got {len(timetable_slots)}"
    assert len(attendance_sessions) == 40, f"Expected 40 sessions, got {len(attendance_sessions)}"
    assert len(student_attendances) == 800, f"Expected 800 attendances, got {len(student_attendances)}"

    # Domain safety: NO synthetic account can use @fpt.edu.vn
    for u in users:
        assert not u.email.endswith("@fpt.edu.vn"), f"Account {u.username} illegally uses @fpt.edu.vn!"
        assert u.email.endswith(f"@{SYNTHETIC_EMAIL_DOMAIN}"), f"Account {u.username} does not use testing domain!"
        # FaceID default NOT_REGISTERED
        if u.role == "STUDENT":
            assert u.face_data_status == "NOT_REGISTERED", f"Student {u.username} must be NOT_REGISTERED initially!"

def test_validator_detects_timetable_conflict():
    scraper = FptuPublicScraper(dry_run=True)
    majors, specs, courses, prereqs, semesters, slot_types = scraper.scrape_curriculum_catalog()
    generator = FptSyntheticGenerator()
    rooms, wifi_aps = generator.generate_rooms_and_wifi()
    users, student_profiles, lecturer_profiles = generator.generate_users()
    classes, enrollments = generator.generate_classes_and_enrollments(users)
    timetable_slots, attendance_sessions, student_attendances = generator.generate_timetables_and_attendance(
        classes, enrollments, rooms
    )

    # Inject conflict into timetable_slots: same room & date & slot
    conflicting_slot = TimetableSlotRecord(
        class_name=classes[1].class_name,
        room_code=timetable_slots[0].room_code,
        slot_number=timetable_slots[0].slot_number,
        date=timetable_slots[0].date,
        day_of_week=timetable_slots[0].day_of_week,
        status="SCHEDULED",
        note="Conflict test",
        verification_status="SYNTHETIC"
    )
    bad_slots = timetable_slots + [conflicting_slot]

    dataset = MasterDataset(
        majors=majors, specializations=specs, courses=courses, course_prerequisites=prereqs,
        semesters=semesters, slot_types=slot_types, rooms=rooms, wifi_aps=wifi_aps,
        users=users, student_profiles=student_profiles, lecturer_profiles=lecturer_profiles,
        class_sections=classes, enrollments=enrollments, timetable_slots=bad_slots,
        attendance_sessions=attendance_sessions, student_attendances=student_attendances
    )
    validator = DataValidator(dataset)
    is_valid, errors, _ = validator.validate_all()
    assert not is_valid, "Validator should fail on room conflict!"
    assert any("Room conflict" in e for e in errors)

def test_sql_export_idempotency_and_transaction(tmp_path):
    scraper = FptuPublicScraper(dry_run=True)
    majors, specs, courses, prereqs, semesters, slot_types = scraper.scrape_curriculum_catalog()
    generator = FptSyntheticGenerator()
    rooms, wifi_aps = generator.generate_rooms_and_wifi()
    users, student_profiles, lecturer_profiles = generator.generate_users()
    classes, enrollments = generator.generate_classes_and_enrollments(users)
    timetable_slots, attendance_sessions, student_attendances = generator.generate_timetables_and_attendance(
        classes, enrollments, rooms
    )

    dataset = MasterDataset(
        majors=majors, specializations=specs, courses=courses, course_prerequisites=prereqs,
        semesters=semesters, slot_types=slot_types, rooms=rooms, wifi_aps=wifi_aps,
        users=users, student_profiles=student_profiles, lecturer_profiles=lecturer_profiles,
        class_sections=classes, enrollments=enrollments, timetable_slots=timetable_slots,
        attendance_sessions=attendance_sessions, student_attendances=student_attendances
    )

    out_sql = tmp_path / "test_seed.sql"
    SqlSeedExporter.export(dataset, str(out_sql))

    content = out_sql.read_text(encoding="utf-8")
    assert "BEGIN;" in content
    assert "COMMIT;" in content
    assert "ON CONFLICT (code) DO NOTHING;" in content
    assert "ON CONFLICT (username) DO NOTHING;" in content
    assert "setval('users_id_seq'" in content


def test_enum_compliance_for_java_jpa():
    """Verify that all generated data strictly matches backend Java enum constants."""
    scraper = FptuPublicScraper(dry_run=True)
    majors, specs, courses, prereqs, semesters, slot_types = scraper.scrape_curriculum_catalog()
    generator = FptSyntheticGenerator()
    rooms, wifi_aps = generator.generate_rooms_and_wifi()
    users, student_profiles, lecturer_profiles = generator.generate_users()
    classes, enrollments = generator.generate_classes_and_enrollments(users)
    timetable_slots, attendance_sessions, student_attendances = generator.generate_timetables_and_attendance(
        classes, enrollments, rooms
    )

    VALID_SEMESTER_STATUSES = {"ACTIVE", "UPCOMING", "CLOSED", "ARCHIVED"}
    VALID_SLOT_STATUSES = {"SCHEDULED", "COMPLETED", "CANCELLED", "RESCHEDULED"}
    VALID_SESSION_STATUSES = {"CREATED", "OPEN", "CLOSED", "CANCELLED"}
    VALID_ATTENDANCE_STATUSES = {"PRESENT", "ABSENT", "LATE"}
    VALID_USER_ROLES = {"ADMIN", "LECTURER", "STUDENT"}
    VALID_USER_STATUSES = {"ACTIVE", "INACTIVE", "SUSPENDED"}
    VALID_FACE_STATUSES = {"NOT_REGISTERED", "PENDING_APPROVAL", "REGISTERED", "REJECTED"}

    # 1. Semesters: must be in valid statuses and never "COMPLETED" (BUG-01 regression check)
    for s in semesters:
        assert s.status in VALID_SEMESTER_STATUSES, f"Invalid semester status: {s.status}"
        assert s.status != "COMPLETED", "Semester status cannot be COMPLETED (must be CLOSED for concluded semesters)"

    # 2. Timetable Slots: must be in valid statuses and never "IN_PROGRESS" (BUG-02 regression check)
    for slot in timetable_slots:
        assert slot.status in VALID_SLOT_STATUSES, f"Invalid slot status: {slot.status}"
        assert slot.status != "IN_PROGRESS", "TimetableSlot status cannot be IN_PROGRESS (active execution is on session)"

    # 3. Attendance Sessions
    for session in attendance_sessions:
        assert session.status in VALID_SESSION_STATUSES, f"Invalid session status: {session.status}"

    # 4. Student Attendances
    for att in student_attendances:
        assert att.status in VALID_ATTENDANCE_STATUSES, f"Invalid attendance status: {att.status}"

    # 5. Users
    for u in users:
        assert u.role in VALID_USER_ROLES, f"Invalid user role: {u.role}"
        assert u.status in VALID_USER_STATUSES, f"Invalid user status: {u.status}"
        assert u.face_data_status in VALID_FACE_STATUSES, f"Invalid face status: {u.face_data_status}"

