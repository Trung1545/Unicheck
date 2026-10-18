# UniCheck — Bảng Ánh Xạ Cơ Sở Dữ Liệu Flyway Đã Xác Minh Thực Tế (Verified Database Mapping)

> **Mã tài liệu:** AUDIT-VERIFIED-DATABASE-2026  
> **Phiên bản:** 2.0.0 (Đối chiếu trực tiếp 3 tệp SQL Flyway V1, V2, V3)  
> **Ngày xác minh:** 15/10/2026  
> **Tác giả:** Senior Software Architect & Spring Boot Engineer  
> **Nguyên tắc bất biến:** Schema PostgreSQL là chuẩn mực dữ liệu. Tuyệt đối không tự ý đặt tên bảng theo phỏng đoán. Khi viết JPA Entity, bắt buộc sử dụng annotation `@Table(name = "...")` đúng với tên bảng thực tế trong Flyway.

---

## 1. Cảnh Báo Sửa Lỗi Tên Bảng (Critical Schema Discrepancy Corrections)

Trong các bản phân tích trước, đã có sự phỏng đoán tên bảng dẫn đến nguy cơ sai lệch nghiêm trọng khi sinh mã JPA Entities:

| Tên Bảng Bị Gọi Sai (Cũ) | Tên Bảng THẬT Trong Flyway | Tệp Migration | Khóa Chính (Primary Key) | Ghi Chú Kỹ Thuật Quan Trọng |
| :--- | :--- | :---: | :--- | :--- |
| `course_classes` ❌ | **`class_sections`** ✅ | `V3` | `class_name VARCHAR(50)` | Khóa chính là chuỗi ký tự `class_name` (ví dụ: `SE1801-PRJ301`), KHÔNG dùng `BIGSERIAL id`. |
| `class_enrollments` ❌ | **`enrollments`** ✅ | `V3` | `id BIGSERIAL` | Tham chiếu ngoại: `class_name REFERENCES class_sections(class_name)` và `student_id REFERENCES users(id)`. |
| `schedules` ❌ | **`timetable_slots`** ✅ | `V3` | `id BIGSERIAL` | Chứa `class_name`, `room_id`, `slot_type_id`, `date`, `day_of_week`, `slot_number`. |
| `room_wifis` ❌ | **`room_wifi_access_points`** ✅<br/>và **`wifi_access_points`** ✅ | `V1` | `id BIGSERIAL` | Schema chuẩn hóa quan hệ nhiều - nhiều giữa `rooms` và `wifi_access_points` qua bảng trung gian. |

---

## 2. Danh Mục 50 Bảng Flyway Thực Tế & Hiện Trạng JPA Entity

### Phân Vùng 1: Flyway V1 — Danh Mục Học Thuật & Cơ Sở Vật Chất (`V1__init_academic_catalog.sql` — 16 Bảng)

| STT | Tên Bảng Thực Tế | Khóa Chính | Khóa Ngoại Chính | JPA Entity Tương Ứng | Trạng Thái Entity |
| :---: | :--- | :--- | :--- | :--- | :---: |
| 1 | `majors` | `id BIGSERIAL` | Không | *Chưa tạo* (`Major.java`) | `PLANNED` |
| 2 | `specializations` | `id BIGSERIAL` | `major_id -> majors(id)` | *Chưa tạo* (`Specialization.java`) | `PLANNED` |
| 3 | `sub_specializations` | `id BIGSERIAL` | `specialization_id -> specializations(id)` | *Chưa tạo* (`SubSpecialization.java`) | `PLANNED` |
| 4 | `courses` | `id BIGSERIAL` | Không | *Chưa tạo* (`Course.java`) | `PLANNED` |
| 5 | `course_prerequisites` | `(course_id, prerequisite_id)` | `course_id, prerequisite_id -> courses(id)` | *Chưa tạo* (`CoursePrerequisite.java`) | `PLANNED` |
| 6 | `specialization_courses` | `id BIGSERIAL` | `specialization_id, course_id` | *Chưa tạo* (`SpecializationCourse.java`) | `PLANNED` |
| 7 | `sub_specialization_courses` | `id BIGSERIAL` | `sub_specialization_id, course_id` | *Chưa tạo* (`SubSpecializationCourse.java`) | `PLANNED` |
| 8 | `semesters` | `id BIGSERIAL` | Không | *Chưa tạo* (`Semester.java`) | `PLANNED` |
| 9 | `semester_configs` | `id BIGSERIAL` | `semester_id -> semesters(id)` | *Chưa tạo* (`SemesterConfig.java`) | `PLANNED` |
| 10 | `semester_weekdays` | `id BIGSERIAL` | `semester_id -> semesters(id)` | *Chưa tạo* (`SemesterWeekday.java`) | `PLANNED` |
| 11 | `holidays` | `id BIGSERIAL` | `semester_id -> semesters(id)` | *Chưa tạo* (`Holiday.java`) | `PLANNED` |
| 12 | `slot_types` | `id BIGSERIAL` | `semester_id -> semesters(id)` | *Chưa tạo* (`SlotType.java`) | `PLANNED` |
| 13 | `rooms` | `id BIGSERIAL` | Không | *Chưa tạo* (`Room.java`) | `PLANNED` |
| 14 | `wifi_access_points` | `id BIGSERIAL` | Không (bssid UNIQUE) | *Chưa tạo* (`WifiAccessPoint.java`) | `PLANNED` |
| 15 | `room_wifi_access_points` | `id BIGSERIAL` | `room_id, wifi_access_point_id` | *Chưa tạo* (`RoomWifiAccessPoint.java`) | `PLANNED` |
| 16 | `attendance_configs` | `id BIGSERIAL` | Không (config_key UNIQUE) | *Chưa tạo* (`AttendanceConfig.java`) | `PLANNED` |

---

### Phân Vùng 2: Flyway V2 — Người Dùng, Hồ Sơ & Bảo Mật (`V2__init_users_and_profiles.sql` — 9 Bảng)

| STT | Tên Bảng Thực Tế | Khóa Chính | Khóa Ngoại Chính | JPA Entity Tương Ứng | Trạng Thái Entity |
| :---: | :--- | :--- | :--- | :--- | :---: |
| 17 | `users` | `id BIGSERIAL` | Không (username, email UNIQUE) | [User.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/User.java) | **DONE** |
| 18 | `student_profiles` | `user_id BIGINT` | `user_id -> users(id)` | [StudentProfile.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/StudentProfile.java) | **DONE** |
| 19 | `lecturer_profiles` | `user_id BIGINT` | `user_id -> users(id)` | [LecturerProfile.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/LecturerProfile.java) | **DONE** |
| 20 | `lecturer_grade_otps` | `user_id BIGINT` | `user_id -> users(id)` | [LecturerGradeOtp.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/LecturerGradeOtp.java) | **DONE** |
| 21 | `user_permissions` | `id BIGSERIAL` | `user_id -> users(id)` | [UserPermission.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/UserPermission.java) | **DONE** |
| 22 | `user_device_tokens` | `id BIGSERIAL` | `user_id -> users(id)` | [UserDeviceToken.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/UserDeviceToken.java) | **DONE** |
| 23 | `user_sessions` | `id BIGSERIAL` | `user_id -> users(id)` | [UserSession.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/UserSession.java) | **DONE** |
| 24 | `access_logs` | `id BIGSERIAL` | `user_id -> users(id)` | [AccessLog.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/AccessLog.java) | **DONE** |
| 25 | `face_encodings` | `id BIGSERIAL` | `user_id -> users(id)` | [FaceEncoding.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/FaceEncoding.java) | **DONE** |

---

### Phân Vùng 3: Flyway V3 — Lớp Học Phần, Điểm Danh, Điểm Số & Vận Hành (`V3__init_classes_attendance_and_operations.sql` — 25 Bảng)

| STT | Tên Bảng Thực Tế | Khóa Chính | Khóa Ngoại Chính | JPA Entity Tương Ứng | Trạng Thái Entity |
| :---: | :--- | :--- | :--- | :--- | :---: |
| 26 | `class_sections` | `class_name VARCHAR(50)` | `course_id, semester_id, lecturer_id` | *Chưa tạo* (`ClassSection.java`) | `PLANNED` |
| 27 | `teaching_assignments` | `id BIGSERIAL` | `lecturer_id, course_id, semester_id` | *Chưa tạo* (`TeachingAssignment.java`) | `PLANNED` |
| 28 | `enrollments` | `id BIGSERIAL` | `class_name -> class_sections, student_id -> users` | *Chưa tạo* (`Enrollment.java`) | `PLANNED` |
| 29 | `timetable_slots` | `id BIGSERIAL` | `class_name, room_id, slot_type_id` | *Chưa tạo* (`TimetableSlot.java`) | `PLANNED` |
| 30 | `grade_components` | `id BIGSERIAL` | `course_id -> courses(id)` | *Chưa tạo* (`GradeComponent.java`) | `PLANNED` |
| 31 | `student_grades` | `id BIGSERIAL` | `enrollment_id, grade_component_id` | *Chưa tạo* (`StudentGrade.java`) | `PLANNED` |
| 32 | `attendance_sessions` | `id BIGSERIAL` | `timetable_slot_id, lecturer_id` | *Chưa tạo* (`AttendanceSession.java`) | `PLANNED` |
| 33 | `student_attendances` | `id BIGSERIAL` | `session_id, student_id` | *Chưa tạo* (`StudentAttendance.java`) | `PLANNED` |
| 34 | `assignments` | `id BIGSERIAL` | `class_name, created_by_id, timetable_slot_id` | *Chưa tạo* (`Assignment.java`) | `PLANNED` |
| 35 | `assignment_submissions` | `id BIGSERIAL` | `assignment_id, student_id, enrollment_id` | *Chưa tạo* (`AssignmentSubmission.java`) | `PLANNED` |
| 36 | `chat_groups` | `id BIGSERIAL` | `class_name, created_by_id` | *Chưa tạo* (`ChatGroup.java`) | `PLANNED` |
| 37 | `chat_group_members` | `id BIGSERIAL` | `chat_group_id, user_id` | *Chưa tạo* (`ChatGroupMember.java`) | `PLANNED` |
| 38 | `chat_messages` | `id BIGSERIAL` | `chat_group_id, sender_id, reply_to_id` | *Chưa tạo* (`ChatMessage.java`) | `PLANNED` |
| 39 | `chat_message_reads` | `id BIGSERIAL` | `message_id, user_id` | *Chưa tạo* (`ChatMessageRead.java`) | `PLANNED` |
| 40 | `chat_message_reactions` | `id BIGSERIAL` | `message_id, user_id` | *Chưa tạo* (`ChatMessageReaction.java`) | `PLANNED` |
| 41 | `ai_chat_sessions` | `id BIGSERIAL` | `user_id -> users(id)` | *Chưa tạo* (`AiChatSession.java`) | `PLANNED` |
| 42 | `ai_chat_messages` | `id BIGSERIAL` | `session_id -> ai_chat_sessions(id)` | *Chưa tạo* (`AiChatMessage.java`) | `PLANNED` |
| 43 | `notifications` | `id BIGSERIAL` | Không | *Chưa tạo* (`Notification.java`) | `PLANNED` |
| 44 | `news` | `id BIGSERIAL` | `sender_id -> users(id)` | *Chưa tạo* (`News.java`) | `PLANNED` |
| 45 | `news_attachments` | `id BIGSERIAL` | `news_id -> news(id)` | *Chưa tạo* (`NewsAttachment.java`) | `PLANNED` |
| 46 | `academic_requests` | `id BIGSERIAL` | `student_id, semester_id, course_id, class_section_id` | *Chưa tạo* (`AcademicRequest.java`) | `PLANNED` |
| 47 | `schedule_requests` | `id BIGSERIAL` | `requester_id, class_name, original_slot_id, requested_slot_id` | *Chưa tạo* (`ScheduleRequest.java`) | `PLANNED` |
| 48 | `alerts` | `id BIGSERIAL` | `user_id, resolved_by -> users(id)` | *Chưa tạo* (`Alert.java`) | `PLANNED` |
| 49 | `system_logs` | `id BIGSERIAL` | `performer_id -> users(id)` | [SystemLog.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/SystemLog.java) | **DONE** |
| 50 | `import_jobs` | `id BIGSERIAL` | Không (job_id UNIQUE) | *Chưa tạo* (`ImportJob.java`) | `PLANNED` |

---

## 3. Tổng Hợp Tỷ Lệ Bao Phủ JPA Entities Hiện Tại

* **Tổng số bảng trong Database Schema:** **50 bảng**.
* **Đã có JPA Entity (`DONE`):** **10 bảng (20%)** — Tập trung toàn bộ ở phân vùng User, Security, Audit Log và Face Encoding Metadata.
* **Chưa có JPA Entity (`PLANNED`):** **40 bảng (80%)** — Sẽ được hiện thực hóa theo từng Vertical Slice trong lộ trình phát triển.
