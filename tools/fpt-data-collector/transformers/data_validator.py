from typing import Dict, List, Set, Tuple
from models import MasterDataset

class DataValidator:
    def __init__(self, dataset: MasterDataset):
        self.dataset = dataset
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def validate_all(self) -> Tuple[bool, List[str], List[str]]:
        self.errors.clear()
        self.warnings.clear()

        self._validate_keys_and_uniqueness()
        self._validate_foreign_keys()
        self._validate_timetable_conflicts()
        self._validate_enrollment_capacities()
        self._validate_semester_boundaries()
        self._validate_dataset_metrics()

        is_valid = len(self.errors) == 0
        return is_valid, self.errors, self.warnings

    def _validate_keys_and_uniqueness(self):
        # Major codes
        maj_codes = set()
        for m in self.dataset.majors:
            if m.code in maj_codes:
                self.errors.append(f"Duplicate major code: {m.code}")
            maj_codes.add(m.code)

        # Spec codes
        spec_codes = set()
        for s in self.dataset.specializations:
            if s.code in spec_codes:
                self.errors.append(f"Duplicate specialization code: {s.code}")
            spec_codes.add(s.code)

        # Course codes
        c_codes = set()
        for c in self.dataset.courses:
            if c.code in c_codes:
                self.errors.append(f"Duplicate course code: {c.code}")
            c_codes.add(c.code)

        # Usernames & Emails
        usernames = set()
        emails = set()
        for u in self.dataset.users:
            if u.username in usernames:
                self.errors.append(f"Duplicate username: {u.username}")
            usernames.add(u.username)

            if u.email in emails:
                self.errors.append(f"Duplicate email: {u.email}")
            emails.add(u.email)

        # Room codes
        room_codes = set()
        for r in self.dataset.rooms:
            if r.code in room_codes:
                self.errors.append(f"Duplicate room code: {r.code}")
            room_codes.add(r.code)

        # Enrollment uniqueness: (class_name, student_username)
        enr_pairs = set()
        for enr in self.dataset.enrollments:
            pair = (enr.class_name, enr.student_username)
            if pair in enr_pairs:
                self.errors.append(f"Duplicate enrollment: student {enr.student_username} in class {enr.class_name}")
            enr_pairs.add(pair)

    def _validate_foreign_keys(self):
        maj_codes = {m.code for m in self.dataset.majors}
        spec_codes = {s.code for s in self.dataset.specializations}
        c_codes = {c.code for c in self.dataset.courses}
        u_names = {u.username for u in self.dataset.users}
        r_codes = {r.code for r in self.dataset.rooms}
        sem_codes = {s.code for s in self.dataset.semesters}
        class_names = {cls.class_name for cls in self.dataset.class_sections}

        # Specs -> Majors
        for s in self.dataset.specializations:
            if s.major_code not in maj_codes:
                self.errors.append(f"Specialization {s.code} references non-existent major {s.major_code}")

        # Prereqs -> Courses
        for p in self.dataset.course_prerequisites:
            if p.course_code not in c_codes:
                self.errors.append(f"Prerequisite references non-existent course {p.course_code}")
            if p.prerequisite_code not in c_codes:
                self.errors.append(f"Prerequisite references non-existent prereq {p.prerequisite_code}")

        # ClassSections -> Courses, Semesters, Users (Lecturers)
        for cls in self.dataset.class_sections:
            if cls.course_code not in c_codes:
                self.errors.append(f"Class {cls.class_name} references non-existent course {cls.course_code}")
            if cls.semester_code not in sem_codes:
                self.errors.append(f"Class {cls.class_name} references non-existent semester {cls.semester_code}")
            if cls.lecturer_username not in u_names:
                self.errors.append(f"Class {cls.class_name} references non-existent lecturer {cls.lecturer_username}")

        # Enrollments -> ClassSections, Users
        for enr in self.dataset.enrollments:
            if enr.class_name not in class_names:
                self.errors.append(f"Enrollment references non-existent class {enr.class_name}")
            if enr.student_username not in u_names:
                self.errors.append(f"Enrollment references non-existent student {enr.student_username}")

        # TimetableSlots -> ClassSections, Rooms
        for slot in self.dataset.timetable_slots:
            if slot.class_name not in class_names:
                self.errors.append(f"Timetable slot references non-existent class {slot.class_name}")
            if slot.room_code not in r_codes:
                self.errors.append(f"Timetable slot references non-existent room {slot.room_code}")

    def _validate_timetable_conflicts(self):
        # 1 Room cannot have 2 classes at the same (date, slot_number)
        room_slot_map: Dict[Tuple[str, str, int], str] = {}
        # 1 Lecturer cannot teach 2 classes at the same (date, slot_number)
        cls_to_lec = {cls.class_name: cls.lecturer_username for cls in self.dataset.class_sections}
        lec_slot_map: Dict[Tuple[str, str, int], str] = {}

        for slot in self.dataset.timetable_slots:
            r_key = (slot.room_code, slot.date, slot.slot_number)
            if r_key in room_slot_map:
                prev_cls = room_slot_map[r_key]
                self.errors.append(f"Room conflict: Room {slot.room_code} booked by {prev_cls} and {slot.class_name} on {slot.date} slot {slot.slot_number}")
            room_slot_map[r_key] = slot.class_name

            lec = cls_to_lec.get(slot.class_name)
            if lec:
                l_key = (lec, slot.date, slot.slot_number)
                if l_key in lec_slot_map:
                    prev_cls = lec_slot_map[l_key]
                    self.errors.append(f"Lecturer conflict: Lecturer {lec} assigned to {prev_cls} and {slot.class_name} on {slot.date} slot {slot.slot_number}")
                lec_slot_map[l_key] = slot.class_name

    def _validate_enrollment_capacities(self):
        # Count enrollments per class
        counts: Dict[str, int] = {}
        for enr in self.dataset.enrollments:
            counts[enr.class_name] = counts.get(enr.class_name, 0) + 1

        for cls in self.dataset.class_sections:
            actual = counts.get(cls.class_name, 0)
            if actual > cls.max_students:
                self.errors.append(f"Class {cls.class_name} exceeds max capacity: {actual} > {cls.max_students}")
            if actual != cls.current_enrollment:
                self.errors.append(f"Class {cls.class_name} current_enrollment mismatch: header={cls.current_enrollment}, actual={actual}")

    def _validate_semester_boundaries(self):
        sem_map = {s.code: (s.start_date, s.end_date) for s in self.dataset.semesters}
        cls_to_sem = {cls.class_name: cls.semester_code for cls in self.dataset.class_sections}

        for slot in self.dataset.timetable_slots:
            sem_code = cls_to_sem.get(slot.class_name)
            if sem_code in sem_map:
                s_start, s_end = sem_map[sem_code]
                if not (s_start <= slot.date <= s_end):
                    self.errors.append(f"Slot date {slot.date} for class {slot.class_name} falls outside semester {sem_code} ({s_start} to {s_end})")

    def _validate_dataset_metrics(self):
        lecs = [u for u in self.dataset.users if u.role == "LECTURER"]
        stus = [u for u in self.dataset.users if u.role == "STUDENT"]

        if len(lecs) != 8:
            self.errors.append(f"Expected exactly 8 test lecturers, got {len(lecs)}")
        if len(stus) != 60:
            self.errors.append(f"Expected exactly 60 test students, got {len(stus)}")
        if len(self.dataset.class_sections) != 8:
            self.errors.append(f"Expected exactly 8 class sections, got {len(self.dataset.class_sections)}")
        if len(self.dataset.enrollments) != 200:
            self.errors.append(f"Expected exactly 200 enrollments, got {len(self.dataset.enrollments)}")
        if len(self.dataset.timetable_slots) != 120:
            self.errors.append(f"Expected exactly 120 timetable slots, got {len(self.dataset.timetable_slots)}")
        if len(self.dataset.attendance_sessions) != 40:
            self.errors.append(f"Expected exactly 40 attendance sessions, got {len(self.dataset.attendance_sessions)}")
        if len(self.dataset.student_attendances) != 800:
            self.errors.append(f"Expected exactly 800 student attendances, got {len(self.dataset.student_attendances)}")
