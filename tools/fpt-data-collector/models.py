from datetime import date, datetime
from typing import List, Literal, Optional
from pydantic import BaseModel, Field

VerificationStatus = Literal["VERIFIED_PUBLIC", "AUTHORIZED_IMPORT", "SYNTHETIC"]

class MajorRecord(BaseModel):
    code: str
    name: str
    description: Optional[str] = None
    program_duration: Optional[str] = "4 năm (9 học kỳ)"
    status: str = "ACTIVE"
    source_url: str
    retrieved_at: str
    verification_status: VerificationStatus = "VERIFIED_PUBLIC"

class SpecializationRecord(BaseModel):
    code: str
    name: str
    description: Optional[str] = None
    major_code: str
    status: str = "ACTIVE"
    source_url: str
    retrieved_at: str
    verification_status: VerificationStatus = "VERIFIED_PUBLIC"

class CourseRecord(BaseModel):
    code: str
    name: str
    description: Optional[str] = None
    credits: int = 3
    number_of_slots: int = 30
    status: str = "ACTIVE"
    is_calculated_in_gpa: bool = True
    source_url: str
    retrieved_at: str
    verification_status: VerificationStatus = "VERIFIED_PUBLIC"

class CoursePrerequisiteRecord(BaseModel):
    course_code: str
    prerequisite_code: str
    source_url: str
    retrieved_at: str
    verification_status: VerificationStatus = "VERIFIED_PUBLIC"

class SemesterRecord(BaseModel):
    code: str
    name: str
    start_date: str
    end_date: str
    status: Literal["ACTIVE", "UPCOMING", "CLOSED", "ARCHIVED"] = "ACTIVE"
    description: Optional[str] = None
    source_url: str
    retrieved_at: str
    verification_status: VerificationStatus = "VERIFIED_PUBLIC"

class SlotTypeRecord(BaseModel):
    name: str
    slot_index: int
    start_time: str
    end_time: str
    duration: str = "90m"
    description: Optional[str] = None
    verification_status: VerificationStatus = "VERIFIED_PUBLIC"

class RoomRecord(BaseModel):
    code: str
    name: str
    capacity: int = 35
    building: str
    floor: int
    type: str = "THEORY"
    status: str = "AVAILABLE"
    verification_status: VerificationStatus = "SYNTHETIC"

class WifiApRecord(BaseModel):
    ssid: str
    bssid: str
    name: str
    location: str
    status: str = "ACTIVE"
    room_code: Optional[str] = None
    verification_status: VerificationStatus = "SYNTHETIC"

class UserRecord(BaseModel):
    code: str
    username: str
    password_hash: str
    full_name: str
    email: str
    dob: Optional[str] = None
    phone: Optional[str] = None
    sex: str = "OTHER"
    role: Literal["ADMIN", "LECTURER", "STUDENT"]
    status: str = "ACTIVE"
    face_data_status: str = "NOT_REGISTERED"
    verification_status: VerificationStatus = "SYNTHETIC"

class StudentProfileRecord(BaseModel):
    username: str
    course: str
    gpa: float = 0.0
    major_code: str
    specialization_code: str
    verification_status: VerificationStatus = "SYNTHETIC"

class LecturerProfileRecord(BaseModel):
    username: str
    department: str
    expertise: str
    bio: Optional[str] = None
    verification_status: VerificationStatus = "SYNTHETIC"

class ClassSectionRecord(BaseModel):
    class_name: str
    course_code: str
    semester_code: str
    lecturer_username: str
    number_of_slots: int = 30
    max_students: int = 30
    current_enrollment: int = 0
    status: str = "OPEN"
    verification_status: VerificationStatus = "SYNTHETIC"

class EnrollmentRecord(BaseModel):
    class_name: str
    student_code: str
    student_username: str
    status: str = "ENROLLED"
    verification_status: VerificationStatus = "SYNTHETIC"

class TimetableSlotRecord(BaseModel):
    class_name: str
    room_code: str
    slot_number: int
    date: str
    day_of_week: int
    status: Literal["SCHEDULED", "COMPLETED", "CANCELLED", "RESCHEDULED"] = "SCHEDULED"
    note: Optional[str] = None
    verification_status: VerificationStatus = "SYNTHETIC"

class AttendanceSessionRecord(BaseModel):
    slot_key: str  # class_name + date + slot_number
    lecturer_username: str
    opened_at: Optional[str] = None
    closed_at: Optional[str] = None
    status: str = "CREATED"
    verification_status: VerificationStatus = "SYNTHETIC"

class StudentAttendanceRecord(BaseModel):
    slot_key: str
    student_username: str
    status: str = "ABSENT"
    method: Optional[str] = None
    check_in_time: Optional[str] = None
    face_confidence: Optional[float] = None
    wifi_bssid: Optional[str] = None
    wifi_rssi: Optional[int] = None
    verification_status: VerificationStatus = "SYNTHETIC"

class MasterDataset(BaseModel):
    majors: List[MajorRecord] = []
    specializations: List[SpecializationRecord] = []
    courses: List[CourseRecord] = []
    course_prerequisites: List[CoursePrerequisiteRecord] = []
    semesters: List[SemesterRecord] = []
    slot_types: List[SlotTypeRecord] = []
    rooms: List[RoomRecord] = []
    wifi_aps: List[WifiApRecord] = []
    users: List[UserRecord] = []
    student_profiles: List[StudentProfileRecord] = []
    lecturer_profiles: List[LecturerProfileRecord] = []
    class_sections: List[ClassSectionRecord] = []
    enrollments: List[EnrollmentRecord] = []
    timetable_slots: List[TimetableSlotRecord] = []
    attendance_sessions: List[AttendanceSessionRecord] = []
    student_attendances: List[StudentAttendanceRecord] = []
