import random
from datetime import date, datetime, timedelta
from typing import Dict, List, Tuple
import bcrypt

from config import (
    SYNTHETIC_EMAIL_DOMAIN,
    DEFAULT_TEST_PASSWORD,
    DEFAULT_SEMESTER_CODE,
)
from models import (
    RoomRecord,
    WifiApRecord,
    UserRecord,
    StudentProfileRecord,
    LecturerProfileRecord,
    ClassSectionRecord,
    EnrollmentRecord,
    TimetableSlotRecord,
    AttendanceSessionRecord,
    StudentAttendanceRecord,
)

class FptSyntheticGenerator:
    def __init__(self, password: str = DEFAULT_TEST_PASSWORD):
        self.password = password
        # Compute real BCrypt hash compatible with Spring Security BCryptPasswordEncoder
        salt = bcrypt.gensalt(10)
        self.password_hash = bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")

    def generate_rooms_and_wifi(self) -> Tuple[List[RoomRecord], List[WifiApRecord]]:
        rooms: List[RoomRecord] = []
        wifi_aps: List[WifiApRecord] = []

        buildings = [
            ("AL", "Alpha", 4),
            ("BE", "Beta", 4),
            ("GA", "Gamma", 4),
            ("DE", "Delta", 4),
        ]
        ap_idx = 1
        for b_code, b_name, num_floors in buildings:
            for fl in range(1, num_floors + 1):
                r_code = f"{b_code}-L{fl}01"
                r_type = "LAB" if b_code in ("BE", "GA") and fl in (1, 2) else "THEORY"
                rooms.append(RoomRecord(
                    code=r_code,
                    name=f"Phòng học {r_code} - Tòa {b_name} Tầng {fl}",
                    capacity=35,
                    building=b_name,
                    floor=fl,
                    type=r_type,
                    status="AVAILABLE",
                    verification_status="SYNTHETIC"
                ))

            # 2 WiFi APs per building
            for ap_sub in (1, 2):
                mac = f"00:1A:2B:3C:{ap_idx:02X}:{ap_sub:02X}"
                wifi_aps.append(WifiApRecord(
                    ssid=f"FU-Student-{b_code}",
                    bssid=mac,
                    name=f"AP Tòa {b_name} Tầng {ap_sub}",
                    location=f"Tòa nhà {b_name}, Khu CNC Hòa Lạc",
                    status="ACTIVE",
                    room_code=f"{b_code}-L{ap_sub}01",
                    verification_status="SYNTHETIC"
                ))
            ap_idx += 1

        return rooms, wifi_aps

    def generate_users(self) -> Tuple[
        List[UserRecord],
        List[StudentProfileRecord],
        List[LecturerProfileRecord],
    ]:
        users: List[UserRecord] = []
        student_profiles: List[StudentProfileRecord] = []
        lecturer_profiles: List[LecturerProfileRecord] = []

        # 1. Admin account
        users.append(UserRecord(
            code="TEST_ADM_01",
            username="admin",
            password_hash=self.password_hash,
            full_name="Quản Trị Viên Hệ Thống",
            email=f"admin@{SYNTHETIC_EMAIL_DOMAIN}",
            dob="1990-01-01",
            phone="0900000001",
            sex="OTHER",
            role="ADMIN",
            status="ACTIVE",
            face_data_status="NOT_REGISTERED",
            verification_status="SYNTHETIC"
        ))

        # 2. Exactly 8 test lecturers
        lecturer_defs = [
            ("TEST_LEC_01", "gv_sonnt", "Nguyễn Tấn Sơn", "sonnt", "MALE", "Bộ môn Kỹ thuật phần mềm", "Java Enterprise, Kiến trúc Microservices"),
            ("TEST_LEC_02", "gv_dunglnt", "Lê Ngọc Tuấn Dũng", "dunglnt", "MALE", "Bộ môn Kỹ thuật phần mềm", "Cấu trúc dữ liệu & Giải thuật, C/C++"),
            ("TEST_LEC_03", "gv_tuanvm", "Vũ Minh Tuấn", "tuanvm", "MALE", "Bộ môn Khoa học máy tính", "Machine Learning, Deep Learning & Vision AI"),
            ("TEST_LEC_04", "gv_khanhkt", "Kiều Trọng Khánh", "khanhkt", "MALE", "Bộ môn Kỹ thuật phần mềm", "Agile Project Management, Full-stack DevOps"),
            ("TEST_LEC_05", "gv_chunglq", "Lê Quang Chung", "chunglq", "MALE", "Bộ môn Kỹ thuật phần mềm", ".NET Core Cross-Platform, C#"),
            ("TEST_LEC_06", "gv_trangvtt", "Võ Thị Thu Trang", "trangvtt", "FEMALE", "Bộ môn An toàn thông tin", "Cyber Security, Mạng máy tính & Mật mã học"),
            ("TEST_LEC_07", "gv_namph", "Phạm Hữu Nam", "namph", "MALE", "Bộ môn Quản trị kinh doanh", "Kinh tế vi mô, Quản trị chiến lược số"),
            ("TEST_LEC_08", "gv_haont", "Nguyễn Thành Hảo", "haont", "MALE", "Bộ môn Hệ thống thông tin", "Cơ sở dữ liệu quan hệ, SQL & Phân tích DL"),
        ]
        for c, u, fn, em_prefix, s, dept, exp in lecturer_defs:
            users.append(UserRecord(
                code=c,
                username=u,
                password_hash=self.password_hash,
                full_name=fn,
                email=f"{em_prefix}@{SYNTHETIC_EMAIL_DOMAIN}",
                dob="1985-05-15",
                phone=f"0901000{len(users):03d}",
                sex=s,
                role="LECTURER",
                status="ACTIVE",
                face_data_status="NOT_REGISTERED",
                verification_status="SYNTHETIC"
            ))
            lecturer_profiles.append(LecturerProfileRecord(
                username=u,
                department=dept,
                expertise=exp,
                bio=f"Giảng viên thỉnh giảng/cơ hữu thuộc {dept}.",
                verification_status="SYNTHETIC"
            ))

        # 3. Exactly 60 test students
        first_names = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ"]
        middle_names = ["Văn", "Thị", "Bảo", "Minh", "Gia", "Đức", "Thành", "Hoàng", "Quốc", "Phương"]
        last_names = ["An", "Bình", "Cường", "Dũng", "Em", "Phúc", "Giang", "Huy", "Khoa", "Linh", "Minh", "Nam", "Phát", "Quân", "Sơn", "Tài", "Thịnh", "Uyên", "Việt", "Xuân"]

        random.seed(42)  # Deterministic seed for reproducible testing
        for i in range(1, 61):
            stu_code = f"HE18{i:04d}"
            stu_user = f"sv_he18{i:04d}"
            fn = f"{random.choice(first_names)} {random.choice(middle_names)} {random.choice(last_names)}"
            sex = "FEMALE" if "Thị" in fn or "Phương" in fn or "Uyên" in fn else "MALE"
            is_se = i <= 40
            spec = "SE" if is_se else "AI"
            course_batch = "K18" if is_se else "K19"
            gpa = round(random.uniform(2.80, 3.85), 2)

            users.append(UserRecord(
                code=stu_code,
                username=stu_user,
                password_hash=self.password_hash,
                full_name=fn,
                email=f"he18{i:04d}@{SYNTHETIC_EMAIL_DOMAIN}",
                dob=f"2004-{(i % 12) + 1:02d}-{(i % 28) + 1:02d}",
                phone=f"0902000{i:03d}",
                sex=sex,
                role="STUDENT",
                status="ACTIVE",
                face_data_status="NOT_REGISTERED",  # Strictly NOT_REGISTERED per privacy rule
                verification_status="SYNTHETIC"
            ))
            student_profiles.append(StudentProfileRecord(
                username=stu_user,
                course=course_batch,
                gpa=gpa,
                major_code="7480201",
                specialization_code=spec,
                verification_status="SYNTHETIC"
            ))

        return users, student_profiles, lecturer_profiles

    def generate_classes_and_enrollments(
        self,
        students: List[UserRecord],
        semester_code: str = DEFAULT_SEMESTER_CODE
    ) -> Tuple[List[ClassSectionRecord], List[EnrollmentRecord]]:
        classes: List[ClassSectionRecord] = []
        enrollments: List[EnrollmentRecord] = []

        # Exactly 8 classes
        class_specs = [
            ("SE1801-PRJ301", "PRJ301", "gv_sonnt", 30),
            ("SE1802-CSD201", "CSD201", "gv_dunglnt", 30),
            ("SE1803-SWP391", "SWP391", "gv_khanhkt", 30),
            ("SE1804-PRN211", "PRN211", "gv_chunglq", 30),
            ("AI1801-AIL101", "AIL101", "gv_tuanvm", 30),
            ("AI1802-AIP391", "AIP391", "gv_tuanvm", 30),
            ("IA1801-IAE101", "IAE101", "gv_trangvtt", 30),
            ("IS1801-DBI202", "DBI202", "gv_haont", 30),
        ]

        # Allocate exactly 25 distinct students per class -> exactly 200 enrollments
        stu_list = [s for s in students if s.role == "STUDENT"]
        # Group 1: students 0..24
        # Group 2: students 20..44
        # Group 3: students 10..34
        # Group 4: students 30..54
        # Group 5: students 35..59
        # Group 6: students 0..24
        # Group 7: students 15..39
        # Group 8: students 25..49
        slice_offsets = [0, 20, 10, 30, 35, 5, 15, 25]

        for idx, (c_name, c_code, lec_user, n_slots) in enumerate(class_specs):
            offset = slice_offsets[idx]
            class_students: List[UserRecord] = []
            for j in range(25):
                stu_idx = (offset + j) % len(stu_list)
                class_students.append(stu_list[stu_idx])

            classes.append(ClassSectionRecord(
                class_name=c_name,
                course_code=c_code,
                semester_code=semester_code,
                lecturer_username=lec_user,
                number_of_slots=n_slots,
                max_students=30,
                current_enrollment=len(class_students),
                status="OPEN",
                verification_status="SYNTHETIC"
            ))

            for stu in class_students:
                enrollments.append(EnrollmentRecord(
                    class_name=c_name,
                    student_code=stu.code,
                    student_username=stu.username,
                    status="ENROLLED",
                    verification_status="SYNTHETIC"
                ))

        return classes, enrollments

    def generate_timetables_and_attendance(
        self,
        classes: List[ClassSectionRecord],
        enrollments: List[EnrollmentRecord],
        rooms: List[RoomRecord]
    ) -> Tuple[
        List[TimetableSlotRecord],
        List[AttendanceSessionRecord],
        List[StudentAttendanceRecord],
    ]:
        timetable_slots: List[TimetableSlotRecord] = []
        attendance_sessions: List[AttendanceSessionRecord] = []
        student_attendances: List[StudentAttendanceRecord] = []

        # Conflict-free schedule configuration
        # 8 classes, each has 15 slots (8 * 15 = 120 timetable slots)
        # Class 1: AL-L201, Mon & Thu, Slot 1
        # Class 2: AL-L301, Tue & Fri, Slot 2
        # Class 3: BE-L201, Wed & Sat, Slot 3
        # Class 4: BE-L301, Mon & Thu, Slot 4
        # Class 5: GA-L201, Tue & Fri, Slot 1
        # Class 6: GA-L301, Wed & Sat, Slot 4
        # Class 7: DE-L201, Mon & Thu, Slot 2
        # Class 8: DE-L301, Tue & Fri, Slot 3
        sched_configs = [
            ("AL-L201", 1, [1, 4]),  # Mon, Thu
            ("AL-L301", 2, [2, 5]),  # Tue, Fri
            ("BE-L201", 3, [3, 6]),  # Wed, Sat
            ("BE-L301", 4, [1, 4]),  # Mon, Thu
            ("GA-L201", 1, [2, 5]),  # Tue, Fri
            ("GA-L301", 4, [3, 6]),  # Wed, Sat
            ("DE-L201", 2, [1, 4]),  # Mon, Thu
            ("DE-L301", 3, [2, 5]),  # Tue, Fri
        ]

        # Semester starts Monday 2026-10-19 (FALL2026)
        sem_start = date(2026, 10, 19)
        # Map class_name to its enrolled students
        class_to_students: Dict[str, List[str]] = {}
        for enr in enrollments:
            class_to_students.setdefault(enr.class_name, []).append(enr.student_username)

        # Slot time mapping
        slot_times = {
            1: ("07:30:00", "09:00:00"),
            2: ("09:10:00", "10:40:00"),
            3: ("10:50:00", "12:20:00"),
            4: ("12:50:00", "14:20:00"),
            5: ("14:30:00", "16:00:00"),
            6: ("16:10:00", "17:40:00"),
        }

        random.seed(123)
        # Build 15 slots per class
        for c_idx, cls in enumerate(classes):
            room_code, slot_num, days = sched_configs[c_idx]
            slots_generated = 0
            cur_week = 0

            while slots_generated < 15:
                for day_offset in days:
                    # Calculate date
                    # Monday of cur_week is sem_start + cur_week * 7 days
                    # day_offset is 1..6 (1 = Mon -> offset 0 days)
                    slot_date = sem_start + timedelta(days=(cur_week * 7 + (day_offset - 1)))
                    d_str = slot_date.isoformat()
                    slot_key = f"{cls.class_name}_{d_str}_SLOT{slot_num}"

                    # Status: slots 0..3 are COMPLETED (past in Oct 2026),
                    # slots 4..14 are SCHEDULED (active session status is handled by attendance_sessions)
                    if slots_generated < 4:
                        s_status = "COMPLETED"
                    else:
                        s_status = "SCHEDULED"

                    timetable_slots.append(TimetableSlotRecord(
                        class_name=cls.class_name,
                        room_code=room_code,
                        slot_number=slot_num,
                        date=d_str,
                        day_of_week=day_offset,
                        status=s_status,
                        note=f"Buổi học số {slots_generated + 1}/15 môn {cls.course_code}",
                        verification_status="SYNTHETIC"
                    ))

                    # Exactly 40 sessions: first 5 slots of each of the 8 classes (8 * 5 = 40)
                    if slots_generated < 5:
                        start_t, end_t = slot_times[slot_num]
                        if slots_generated < 4:
                            # 32 CLOSED sessions
                            sess_status = "CLOSED"
                            op_at = f"{d_str}T{start_t}"
                            cl_at = f"{d_str}T{end_t}"
                        elif slots_generated == 4 and c_idx in (0, 1):
                            # 2 OPEN sessions for live QR/Face testing
                            sess_status = "OPEN"
                            op_at = f"{d_str}T{start_t}"
                            cl_at = None
                        else:
                            # 6 CREATED sessions
                            sess_status = "CREATED"
                            op_at = None
                            cl_at = None

                        attendance_sessions.append(AttendanceSessionRecord(
                            slot_key=slot_key,
                            lecturer_username=cls.lecturer_username,
                            opened_at=op_at,
                            closed_at=cl_at,
                            status=sess_status,
                            verification_status="SYNTHETIC"
                        ))

                        # For CLOSED sessions, generate student attendance history
                        # Exactly 32 closed sessions * 25 students = 800 student attendances!
                        if sess_status == "CLOSED":
                            stus = class_to_students.get(cls.class_name, [])
                            for s_user in stus:
                                p_rand = random.random()
                                if p_rand < 0.88:
                                    att_status = "PRESENT"
                                    # 70% Face, 30% QR
                                    method = "FACE_RECOGNITION" if random.random() < 0.7 else "DYNAMIC_QR"
                                    check_min = random.randint(1, 12)
                                    check_time = f"{d_str}T07:{30 + check_min:02d}:00" if slot_num == 1 else f"{d_str}T{start_t}"
                                    conf = round(random.uniform(0.85, 0.94), 4) if method == "FACE_RECOGNITION" else None
                                    wifi_mac = "00:1A:2B:3C:01:01"
                                    wifi_rssi = random.randint(-65, -45)
                                elif p_rand < 0.96:
                                    att_status = "LATE"
                                    method = "MANUAL"
                                    check_time = f"{d_str}T07:44:00" if slot_num == 1 else f"{d_str}T{start_t}"
                                    conf = None
                                    wifi_mac = None
                                    wifi_rssi = None
                                else:
                                    att_status = "ABSENT"
                                    method = None
                                    check_time = None
                                    conf = None
                                    wifi_mac = None
                                    wifi_rssi = None

                                student_attendances.append(StudentAttendanceRecord(
                                    slot_key=slot_key,
                                    student_username=s_user,
                                    status=att_status,
                                    method=method,
                                    check_in_time=check_time,
                                    face_confidence=conf,
                                    wifi_bssid=wifi_mac,
                                    wifi_rssi=wifi_rssi,
                                    verification_status="SYNTHETIC"
                                ))

                    slots_generated += 1
                    if slots_generated >= 15:
                        break
                cur_week += 1

        return timetable_slots, attendance_sessions, student_attendances
