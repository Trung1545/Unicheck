# BẢNG PHÂN LOẠI TRẠNG THÁI TRIỂN KHAI 21 PHÂN HỆ THIẾT KẾ
## UNICHECK DETAILED MODULE STATUS MATRIX — SDD v2.1
**Dự án:** UniCheck — Hệ thống Điểm danh Thông minh Đa nền tảng  
**Tài liệu tham chiếu thiết kế:** `UniCheck_Software_Design_Document(1).docx` (Report 4)  
**Căn cứ kiểm định:** 281/281 Automated Tests, 25 JPA Entities, 10 Backend Controllers, 18 Web Pages, 5 Mobile Views, 4 AI Engine Modules  
**Thời điểm cập nhật:** Tháng 10 / 2026  

---

## 1. TỔNG QUAN TỶ LỆ TRIỂN KHAI THEO PHÂN HỆ

Hệ thống UniCheck bao gồm 21 phân hệ nghiệp vụ được thiết kế toàn diện trong Báo cáo Thiết kế Phần mềm (Report 4). Dưới đây là thống kê phân bổ trạng thái thực tế:

| Trạng thái | Số lượng phân hệ | Tỷ lệ (%) | Ý nghĩa kỹ thuật |
|:---|:---:|:---:|:---|
| **IMPLEMENTED & TESTED** | 10 | 47.6% | Đã triển khai đầy đủ từ giao diện đến CSDL, có kiểm thử tự động đạt 100%. |
| **PARTIAL** | 4 | 19.0% | Đã triển khai phần lớn logic Backend và CSDL; giao diện hoặc tích hợp mạng đang hoàn thiện. |
| **MOCK** | 0 | 0.0% | Không có phân hệ cốt lõi nào phụ thuộc hoàn toàn vào dữ liệu giả lập. |
| **PLANNED DESIGN / FUTURE EXTENSION** | 7 | 33.4% | Đã thiết kế chi tiết (Class Diagram, Sequence Diagram, CSDL Flyway); xếp vào lộ trình mở rộng sau đợt nghiệm thu điểm danh sinh trắc học. |
| **TỔNG CỘNG** | **21** | **100%** | **Toàn bộ 21 phân hệ được bảo tồn và định vị rõ ràng trong kiến trúc.** |

---

## 2. MA TRẬN CHI TIẾT 21 PHÂN HỆ THIẾT KẾ

### Phân hệ 3.1: Authentication (Xác thực và Phân quyền)
- **Trạng thái:** `IMPLEMENTED & TESTED`
- **Mã nguồn Backend:**
  - `AuthController.java`: `/api/v1/auth/login`, `/api/v1/auth/refresh`, `/api/v1/auth/me`, `/api/v1/auth/change-password`, `/api/v1/auth/logout`.
  - `AuthService.java`, `JwtTokenProvider.java`, `SecurityConfig.java`, `JwtAuthenticationFilter.java`.
- **Mã nguồn Frontend:** `LoginPage.tsx`, `useAuthStore.ts`, `authApi.ts`, `ProtectedRoute.tsx`.
- **Mã nguồn Mobile:** `login_view.dart`, `login_controller.dart`, `login_binding.dart`, `auth_api.dart`.
- **Thực thể CSDL:** Bảng `users`, `roles`, `user_roles`. Redis Cache quản lý Blacklist/Token.
- **Minh chứng kiểm thử:** 13/13 backend security unit tests đạt, 8/8 web auth store tests đạt, 6/6 mobile login tests đạt.
- **Đánh giá sai lệch:** Thiết kế gốc mô tả xác thực JWT đơn giản. Thực tế nâng cấp lên mô hình **Dual Token** (Access Token 15 phút, Refresh Token 7 ngày với cơ chế Refresh Token Rotation - RTR). Chức năng Quên mật khẩu qua email tạm thời mock dịch vụ gửi thư SMTP.

---

### Phân hệ 3.2: System Account Management (Quản lý Tài khoản Hệ thống)
- **Trạng thái:** `IMPLEMENTED & TESTED`
- **Mã nguồn Backend:** `UserController.java`, `UserService.java`, `UserRepository.java`, `RoleRepository.java`.
  - Endpoint: `/api/users` (GET, POST), `/api/users/{id}` (GET, PUT, DELETE), `/api/users/{id}/status`, `/api/users/{id}/roles`.
- **Mã nguồn Frontend:** `UserManagementPage.tsx`, `userApi.ts`, `UserModal.tsx`.
- **Thực thể CSDL:** Bảng `users`, `roles`, `user_roles`.
- **Minh chứng kiểm thử:** 16/16 backend tests đạt (kiểm tra phân trang, tìm kiếm theo email/username, kiểm soát quyền ADMIN, mã hóa mật khẩu BCrypt).
- **Đánh giá sai lệch:** Khớp 100% với thiết kế Class Diagram từ Report 4.

---

### Phân hệ 3.3: Notification Management (Quản lý Thông báo và Tin tức)
- **Trạng thái:** `PLANNED DESIGN / FUTURE EXTENSION`
- **Mã nguồn Backend:** Chưa tạo JPA Entity và Service.
- **Mã nguồn Frontend:** Biểu tượng chuông thông báo trên Header hiển thị dữ liệu mẫu tĩnh (Mock notifications).
- **Thực thể CSDL:** Đã tạo cấu trúc bảng `notifications` và `news` trong script di chuyển Flyway `V1__init_schema.sql`.
- **Đánh giá sai lệch:** Được thiết kế đầy đủ trong Report 4 (Class Diagram Fig 25, Sequence Figs 26-33). Do ưu tiên tập trung cho hệ sinh thái điểm danh sinh trắc học, phân hệ này được giữ nguyên thiết kế và xếp vào giai đoạn phát triển tiếp theo.

---

### Phân hệ 3.4: System Monitoring & Audit (Giám sát và Nhật ký Hệ thống)
- **Trạng thái:** `PARTIAL`
- **Mã nguồn Backend:** `AuditLog.java`, `AuditLogRepository.java`, Spring AOP Aspect & Interceptor tự động ghi nhận các sự kiện: Đăng nhập, Thay đổi mật khẩu, Kích hoạt phiên điểm danh, Điểm danh sinh viên, Điều chỉnh điểm danh thủ công.
- **Mã nguồn Frontend:** Chưa có màn hình quản trị Audit Log chuyên dụng trên giao diện Web (dữ liệu log hiện được truy xuất qua database và application logs).
- **Thực thể CSDL:** Bảng `audit_logs` (lưu trữ: `user_id`, `action`, `resource`, `ip_address`, `status`, `timestamp`, `details`).
- **Minh chứng kiểm thử:** 4/4 backend tests cho cơ chế ghi log tự động đạt.

---

### Phân hệ 3.5: Student Records Management (Quản lý Hồ sơ Sinh viên)
- **Trạng thái:** `IMPLEMENTED & TESTED`
- **Mã nguồn Backend:** `StudentProfile.java`, `StudentProfileRepository.java`, `StudentProfileController.java`, `ExcelHelper.java` (Apache POI xử lý import/export).
  - Endpoint: `/api/students` (GET, POST), `/api/students/{id}`, `/api/students/import-excel`, `/api/students/export-excel`.
- **Mã nguồn Frontend:** `StudentManagementPage.tsx`, `studentApi.ts`.
- **Mã nguồn Mobile:** `profile_view.dart`, `profile_controller.dart`.
- **Thực thể CSDL:** Bảng `student_profiles`, `users`, `majors`.
- **Minh chứng kiểm thử:** 12/12 backend tests đạt (bao gồm parse tệp Excel, ánh xạ cột mã SV, tên, lớp, ngành học).

---

### Phân hệ 3.6: Lecturer Records Management (Quản lý Hồ sơ Giảng viên)
- **Trạng thái:** `IMPLEMENTED & TESTED`
- **Mã nguồn Backend:** `LecturerProfile.java`, `LecturerProfileRepository.java`, `LecturerController.java`.
  - Endpoint: `/api/lecturers`, `/api/lecturers/{id}`, `/api/lecturers/department/{deptId}`.
- **Mã nguồn Frontend:** `LecturerManagementPage.tsx`, `lecturerApi.ts`.
- **Thực thể CSDL:** Bảng `lecturer_profiles`, `users`, `departments`.
- **Minh chứng kiểm thử:** 8/8 backend tests đạt.

---

### Phân hệ 3.7: Facility Management (Quản lý Cơ sở Vật chất & Hạ tầng Mạng)
- **Trạng thái:** `IMPLEMENTED & TESTED` (Phòng học) / `PARTIAL` (Điểm phát WiFi)
- **Mã nguồn Backend:**
  - `Room.java`, `RoomRepository.java`, `RoomController.java`: Quản lý danh mục phòng học, tòa nhà, sức chứa, kinh độ/vĩ độ GPS của phòng (`latitude`, `longitude`).
  - `WifiAccessPoint.java`, `WifiAccessPointRepository.java`: Quản lý danh sách trạm phát sóng WiFi (`bssid`, `ssid`, `room_id`).
- **Mã nguồn Frontend:** `RoomManagementPage.tsx`, `roomApi.ts`.
- **Thực thể CSDL:** Bảng `rooms`, `wifi_access_points`.
- **Minh chứng kiểm thử:** 10/10 backend tests đạt cho phân hệ quản lý phòng học và tọa độ địa lý.

---

### Phân hệ 3.8: Curriculum Management (Quản lý Ngành và Chuyên ngành)
- **Trạng thái:** `PARTIAL`
- **Mã nguồn Backend:** `Major.java`, `Specialization.java`, `MajorRepository.java`.
- **Mã nguồn Frontend:** Lựa chọn ngành/khoa lồng ghép trong form tạo sinh viên và lớp học.
- **Thực thể CSDL:** Bảng `majors`, `specializations`, `departments`.
- **Đánh giá sai lệch:** Sơ đồ thiết kế từ Report 4 được giữ nguyên vẹn; trong thực tế, các chức năng CRUD chuyên ngành phức tạp được gom nhóm vào quản trị danh mục chung.

---

### Phân hệ 3.9: Course Catalog Management (Quản lý Danh mục Môn học)
- **Trạng thái:** `IMPLEMENTED & TESTED`
- **Mã nguồn Backend:** `Course.java`, `CourseRepository.java`, `CourseController.java`.
  - Endpoint: `/api/courses` (GET, POST), `/api/courses/{id}` (PUT, DELETE).
- **Mã nguồn Frontend:** `CourseManagementPage.tsx`, `courseApi.ts`.
- **Thực thể CSDL:** Bảng `courses` (các trường: `course_code`, `name`, `credits`, `theory_hours`, `practical_hours`, `department_id`).
- **Minh chứng kiểm thử:** 9/9 backend tests đạt.

---

### Phân hệ 3.10: Semester Management (Quản lý Học kỳ)
- **Trạng thái:** `IMPLEMENTED & TESTED`
- **Mã nguồn Backend:** `Semester.java`, `SemesterRepository.java`, `SemesterController.java`.
  - Endpoint: `/api/semesters`, `/api/semesters/active`, `/api/semesters/{id}`.
- **Mã nguồn Frontend:** `SemesterManagementPage.tsx`, `semesterApi.ts`.
- **Thực thể CSDL:** Bảng `semesters` (`semester_code`, `name`, `start_date`, `end_date`, `is_active`).
- **Minh chứng kiểm thử:** 8/8 backend tests đạt.

---

### Phân hệ 3.11: Class Management (Quản lý Lớp học phần)
- **Trạng thái:** `IMPLEMENTED & TESTED`
- **Mã nguồn Backend:** `ClassSection.java`, `ClassSectionRepository.java`, `ClassSectionController.java`.
  - Endpoint: `/api/class-sections`, `/api/class-sections/{id}`, `/api/class-sections/semester/{semesterId}`.
- **Mã nguồn Frontend:** `ClassManagementPage.tsx`, `classSectionApi.ts`.
- **Thực thể CSDL:** Bảng `class_sections` (quan hệ N-1 với `courses`, `semesters`, `lecturer_profiles`, `rooms`).
- **Minh chứng kiểm thử:** 14/14 backend tests đạt (bao gồm logic kiểm tra trùng lịch và quá tải sức chứa phòng).

---

### Phân hệ 3.12: Enrollment Management (Quản lý Đăng ký Lớp học)
- **Trạng thái:** `IMPLEMENTED & TESTED`
- **Mã nguồn Backend:** `Enrollment.java`, `EnrollmentRepository.java`, `EnrollmentController.java`.
  - Endpoint: `/api/enrollments`, `/api/enrollments/class-section/{id}`, `/api/enrollments/student/{id}`.
- **Mã nguồn Frontend:** Danh sách sinh viên thuộc lớp học phần trên `ClassManagementPage.tsx`.
- **Thực thể CSDL:** Bảng `enrollments`, ràng buộc duy nhất `UNIQUE(student_id, class_section_id)`.
- **Minh chứng kiểm thử:** 9/9 backend tests đạt.

---

### Phân hệ 3.13: Timetable Operations (Vận hành Lịch học và Thời khóa biểu)
- **Trạng thái:** `IMPLEMENTED & TESTED`
- **Mã nguồn Backend:** `ClassSchedule.java`, `ClassScheduleRepository.java`, `ScheduleController.java`.
  - Endpoint: `/api/schedules/my-schedule`, `/api/schedules/class-section/{id}`, `/api/schedules/week`.
- **Mã nguồn Frontend:** `TimetablePage.tsx`, `scheduleApi.ts`.
- **Mã nguồn Mobile:** `schedule_view.dart`, `schedule_controller.dart`.
- **Thực thể CSDL:** Bảng `class_schedules` (`day_of_week`, `slot_number`, `start_time`, `end_time`, `room_id`).
- **Minh chứng kiểm thử:** 11/11 backend tests đạt, 6/6 mobile timetable widget tests đạt.

---

### Phân hệ 3.14: Academic Request Management (Quản lý Yêu cầu và Đơn xin vắng)
- **Trạng thái:** `PLANNED DESIGN / FUTURE EXTENSION`
- **Mã nguồn Backend:** Chưa tạo JPA Entity/Controller.
- **Thực thể CSDL:** Đã tạo bảng `leave_requests`, `academic_requests` trong Flyway V1.
- **Đánh giá sai lệch:** Giữ nguyên thiết kế đầy đủ (Class Diagram Fig 112, Sequence Figs 113-120). Hiện tại việc ghi nhận vắng có phép được giảng viên thao tác trực tiếp tại màn hình điều chỉnh điểm danh.

---

### Phân hệ 3.15: Attendance Configuration (Cấu hình Điểm danh Hệ thống)
- **Trạng thái:** `IMPLEMENTED & TESTED`
- **Mã nguồn Backend:** `AttendanceConfig.java`, `AttendanceConfigRepository.java`, `AttendanceConfigController.java`.
  - Endpoint: `/api/attendance/configs`, `/api/attendance/configs/{classSectionId}`.
- **Mã nguồn Frontend:** `AttendanceConfigPage.tsx`, `attendanceConfigApi.ts`.
- **Thực thể CSDL:** Bảng `attendance_configs` (`early_open_minutes`, `late_tolerance_minutes`, `face_similarity_threshold`, `max_gps_radius_meters`, `require_wifi_validation`).
- **Minh chứng kiểm thử:** 7/7 backend tests đạt.

---

### Phân hệ 3.16: Attendance Taking & Reporting (Tổ chức Điểm danh và Báo cáo Chuyên cần)
- **Trạng thái:** `IMPLEMENTED & TESTED` (Phần lớn) / `PARTIAL` (Mobile Check-in)
- **Mã nguồn Backend:**
  - `AttendanceSession.java`, `AttendanceSessionController.java`: Mở phiên, đóng phiên, hủy phiên, chuyển đổi trạng thái `SCHEDULED -> ACTIVE -> COMPLETED / CANCELLED`.
  - `AttendanceRecord.java`, `AttendanceRecordController.java`: Ghi nhận trạng thái điểm danh (`PRESENT`, `LATE`, `ABSENT_UNEXCUSED`, `ABSENT_EXCUSED`), điều chỉnh thủ công bởi giảng viên, xuất báo cáo Excel qua Apache POI.
- **Mã nguồn AI Service:**
  - `face_engine.py`: Điều phối toàn bộ luồng bóc tách đặc trưng và so khớp.
  - `face_detector.py`: Mô hình YuNet phát hiện khuôn mặt và 5 landmarks.
  - `liveness_engine.py`: Mô hình Dual Ensemble MiniFASNet kiểm tra sống động chống giả mạo.
  - `face_matcher.py`: Trích xuất vector ArcFace 512 chiều và tính Cosine distance.
- **Mã nguồn Mobile:**
  - `face_enrollment_view.dart`, `head_pose_evaluator.dart`: Thu thập khuôn mặt 3 bước thời gian thực (Trực diện, Quay trái, Quay phải) kết hợp Google ML Kit.
  - `face_checkin_view.dart`: Giao diện quét mặt điểm danh hiện tại hiển thị Snackbar thông báo (Đang hoàn thiện kết nối API theo TASK-06).
- **Thực thể CSDL:** Bảng `attendance_sessions`, `attendance_records`, `student_face_data` (lưu binary 2048 bytes BYTEA).
- **Minh chứng kiểm thử:** 22/22 backend tests đạt, 39/39 AI unit tests đạt, 12/12 web attendance tests đạt.

---

### Phân hệ 3.17: Lecturer Teaching Workspace (Không gian Giảng dạy của Giảng viên)
- **Trạng thái:** `IMPLEMENTED & TESTED` (Điểm danh & Lớp học) / `PLANNED DESIGN` (Bài tập)
- **Mã nguồn Frontend:** `LecturerDashboardPage.tsx`, `LecturerAttendancePage.tsx`.
- **Mã nguồn Backend:** Các API lớp học và phiên điểm danh theo `lecturerId`.
- **Thực thể CSDL:** Bảng `class_sections`, `attendance_sessions`, `assignments` (Planned).
- **Đánh giá sai lệch:** Giữ nguyên các sơ đồ Class/Sequence Diagram về Quản lý bài tập (Assignments & Comments) ở trạng thái PLANNED DESIGN.

---

### Phân hệ 3.18: Student Learning Workspace (Không gian Học tập của Sinh viên)
- **Trạng thái:** `IMPLEMENTED & TESTED` (Lịch học & Chuyên cần) / `PLANNED DESIGN` (Nộp bài tập)
- **Mã nguồn Mobile:** `home_view.dart`, `schedule_view.dart`, `attendance_history_view.dart`, `profile_view.dart`.
- **Thực thể CSDL:** Bảng `enrollments`, `class_schedules`, `attendance_records`.
- **Minh chứng kiểm thử:** 14/14 mobile tests cho giao diện sinh viên đạt.

---

### Phân hệ 3.19: Grading & Assessment (Quản lý Điểm và Đánh giá)
- **Trạng thái:** `PLANNED DESIGN / FUTURE EXTENSION`
- **Mã nguồn Backend:** Chưa tạo JPA Entity/Service.
- **Thực thể CSDL:** Đã tạo bảng `grade_components`, `student_grades` trong Flyway V2.
- **Đánh giá sai lệch:** Giữ nguyên toàn bộ thiết kế Class Diagram (Fig 149) và 7 Sequence Diagrams (Figs 150-156) từ Report 4.

---

### Phân hệ 3.20: Class Communication (Trao đổi và Thảo luận Lớp học)
- **Trạng thái:** `PLANNED DESIGN / FUTURE EXTENSION`
- **Mã nguồn Backend:** Chưa triển khai WebSocket STOMP Gateway.
- **Thực thể CSDL:** Đã tạo bảng `chat_groups`, `chat_messages` trong Flyway V3.
- **Đánh giá sai lệch:** Giữ nguyên thiết kế Class Diagram (Fig 157) và Sequence Diagrams (Figs 158-159) từ Report 4.

---

### Phân hệ 3.21: AI Support Service (Trợ lý Ảo và Hỗ trợ Thông minh)
- **Trạng thái:** `PLANNED DESIGN / FUTURE EXTENSION` (Đối với LLM Chatbot) / `IMPLEMENTED & TESTED` (Đối với AI Face Vision)
- **Mã nguồn Backend:** Chưa có client kết nối OpenAI / Claude / Ollama.
- **Thực thể CSDL:** Đã tạo bảng `ai_conversations`, `ai_messages` trong Flyway V3.
- **Đánh giá sai lệch:** Giữ nguyên thiết kế Class Diagram (Fig 160) và Sequence Diagram (Fig 161) từ Report 4; làm rõ trong SDD v2.1 rằng AI Service hiện đang tập trung 100% tài nguyên cho Computer Vision (Nhận diện khuôn mặt & Chống giả mạo).
