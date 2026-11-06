import argparse
import sys
from pathlib import Path

# Add current dir to python path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from config import (
    NORMALIZED_DIR,
    SEEDS_DIR,
    DEFAULT_TEST_PASSWORD,
    DEFAULT_SEMESTER_CODE,
)
from models import MasterDataset
from scrapers.fptu_scraper import FptuPublicScraper
from generators.synthetic_generator import FptSyntheticGenerator
from transformers.data_validator import DataValidator
from exporters.json_exporter import JsonExporter
from exporters.sql_exporter import SqlSeedExporter

def run_pipeline(dry_run: bool = False, output_sql: str = None, output_json: str = None):
    print("=" * 70)
    print("UNICHECK - FPT DATA PIPELINE (COLLECTION & VALIDATION)")
    print(f"Mode: {'DRY-RUN' if dry_run else 'PRODUCTION BUILD'}")
    print("=" * 70)

    # 1. Scrape verified public catalog
    print("\n[PHASE 1] Scraping & Verifying FPT Public Data...")
    scraper = FptuPublicScraper(dry_run=dry_run)
    majors, specs, courses, prereqs, semesters, slot_types = scraper.scrape_curriculum_catalog()
    print(f"  -> Verified Majors: {len(majors)}")
    print(f"  -> Verified Specializations: {len(specs)}")
    print(f"  -> Verified Courses: {len(courses)}")
    print(f"  -> Verified Prerequisites: {len(prereqs)}")
    print(f"  -> Verified Semesters: {len(semesters)}")
    print(f"  -> Verified Slot Types: {len(slot_types)}")

    # 2. Generate safe synthetic test data
    print("\n[PHASE 2] Generating Safe Synthetic Test Data (Non-PII, Domain @test.unicheck.edu.vn)...")
    generator = FptSyntheticGenerator(password=DEFAULT_TEST_PASSWORD)
    rooms, wifi_aps = generator.generate_rooms_and_wifi()
    users, student_profiles, lecturer_profiles = generator.generate_users()
    classes, enrollments = generator.generate_classes_and_enrollments(users, semester_code=DEFAULT_SEMESTER_CODE)
    timetable_slots, attendance_sessions, student_attendances = generator.generate_timetables_and_attendance(
        classes, enrollments, rooms
    )

    print(f"  -> Rooms (Campus Hoa Lac): {len(rooms)}")
    print(f"  -> WiFi APs: {len(wifi_aps)}")
    print(f"  -> Test Users: {len(users)} (1 Admin, 8 Lecturers, 60 Students)")
    print(f"  -> Student Profiles: {len(student_profiles)}")
    print(f"  -> Lecturer Profiles: {len(lecturer_profiles)}")
    print(f"  -> Class Sections: {len(classes)}")
    print(f"  -> Valid Enrollments: {len(enrollments)}")
    print(f"  -> Conflict-Free Timetable Slots: {len(timetable_slots)}")
    print(f"  -> Attendance Sessions: {len(attendance_sessions)}")
    print(f"  -> Simulated Attendance Records: {len(student_attendances)}")

    # 3. Assemble Master Dataset
    dataset = MasterDataset(
        majors=majors,
        specializations=specs,
        courses=courses,
        course_prerequisites=prereqs,
        semesters=semesters,
        slot_types=slot_types,
        rooms=rooms,
        wifi_aps=wifi_aps,
        users=users,
        student_profiles=student_profiles,
        lecturer_profiles=lecturer_profiles,
        class_sections=classes,
        enrollments=enrollments,
        timetable_slots=timetable_slots,
        attendance_sessions=attendance_sessions,
        student_attendances=student_attendances,
    )

    # 4. Strict Validation
    print("\n[PHASE 3] Validating Integrity, Foreign Keys, Constraints & Metrics...")
    validator = DataValidator(dataset)
    is_valid, errors, warnings = validator.validate_all()

    if warnings:
        for w in warnings:
            print(f"  [WARN] {w}")

    if not is_valid:
        print("\n[VALIDATION FAILED] Found issues:")
        for err in errors:
            print(f"  [ERROR] {err}")
        sys.exit(1)
    else:
        print("  [SUCCESS] All 7 validation suites PASSED with 0 errors!")

    # 5. Export JSON & SQL
    if not dry_run:
        json_path = output_json or str(NORMALIZED_DIR / "fpt_master_demo_dataset.json")
        sql_path = output_sql or str(SEEDS_DIR / "01_fpt_master_demo_seed.sql")

        print("\n[PHASE 4] Exporting Artifacts...")
        JsonExporter.export(dataset, json_path)
        SqlSeedExporter.export(dataset, sql_path)
        print("\n[COMPLETED] Pipeline finished successfully!")
    else:
        print("\n[DRY-RUN COMPLETED] Validation verified, no files written.")

def main():
    parser = argparse.ArgumentParser(description="UniCheck FPT Data Pipeline & Seed Generator")
    parser.add_argument("--dry-run", action="store_true", help="Run without writing files")
    parser.add_argument("--output-sql", type=str, default=None, help="Custom output path for SQL seed")
    parser.add_argument("--output-json", type=str, default=None, help="Custom output path for JSON export")

    args = parser.parse_args()
    run_pipeline(dry_run=args.dry_run, output_sql=args.output_sql, output_json=args.output_json)

if __name__ == "__main__":
    main()
