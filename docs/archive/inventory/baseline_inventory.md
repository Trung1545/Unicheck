# UNICHECK - BASELINE INVENTORY AUDIT (TASK P00)
**Thời điểm khóa baseline**: 2026-10-13  
**Commit SHA**: `0ad5e70db2e03b4d67d9dabd06fb49aae0c08306`  
**Nhánh Git**: `develop`  
**Trạng thái Repository**: Clean (`working tree clean`)

---

## 1. TỔNG QUAN HIỆN TRẠNG KIẾN TRÚC

UniCheck là hệ thống điểm danh sinh trắc học tích hợp nhận diện khuôn mặt và kiểm tra vị trí (Wi-Fi/QR) dành cho trường đại học.
- **Backend**: Spring Boot 3.3.4, Java 21/22, PostgreSQL 15 (`ddl-auto=validate`), Redis 7, Flyway Migrations (V1, V2, V3).
- **AI Service**: Python 3.11, Flask, OpenCV (Hiện đang ở trạng thái Mocking endpoint, chưa chạy mô hình sinh trắc học thực tế).
- **Mobile Client**: Flutter 3.47.3, Dart 3.13.3, GetX state management (Frontend duy nhất phát triển cho Mobile/Web/Desktop).
- **Web Client (Legacy)**: React 18, Vite, Tailwind CSS (Được giữ nguyên làm tài liệu tham chiếu, không phát triển thêm).

---

## 2. MA TRẬN PHÂN LOẠI THÀNH PHẦN (COMPONENT STATUS MATRIX)

Phân loại:
- `VERIFIED`: Đã kiểm chứng trong mã nguồn thực tế, có code và test chạy đạt.
- `REPORTED`: Có định nghĩa trong tài liệu hoặc schema Flyway nhưng chưa có JPA Entity / code backend.
- `MOCK`: Code đang trả dữ liệu giả lập hoặc hardcode kết quả.
- `MISSING`: Chưa có mã nguồn hoặc thiếu thư viện bổ trợ.

### 2.1. Cơ sở dữ liệu (Flyway Schema & JPA Entities)
Tổng số bảng Flyway: **50 bảng**.  
Tổng số JPA Entity: **10 entities**.

| STT | Tên bảng CSDL | File Migration & Dòng | JPA Entity | Phân loại | Ghi chú |
| :---: | :--- | :--- | :--- | :---: | :--- |
| 1 | `majors` | V1:L7 | *Chưa có* | `REPORTED` | Chuyên ngành học |
| 2 | `specializations` | V1:L19 | *Chưa có* | `REPORTED` | Ngành đào tạo |
| 3 | `sub_specializations` | V1:L31 | *Chưa có* | `REPORTED` | Chuyên sâu |
| 4 | `courses` | V1:L43 | *Chưa có* | `REPORTED` | Học phần |
| 5 | `course_prerequisites` | V1:L57 | *Chưa có* | `REPORTED` | Học phần tiên quyết |
| 6 | `specialization_courses` | V1:L64 | *Chưa có* | `REPORTED` | Khung CTĐT ngành |
| 7 | `sub_specialization_courses` | V1:L76 | *Chưa có* | `REPORTED` | Khung CTĐT chuyên sâu |
| 8 | `semesters` | V1:L88 | *Chưa có* | `REPORTED` | Học kỳ |
| 9 | `semester_configs` | V1:L101 | *Chưa có* | `REPORTED` | Cấu hình học kỳ |
| 10 | `semester_weekdays` | V1:L113 | *Chưa có* | `REPORTED` | Ngày học trong tuần |
| 11 | `holidays` | V1:L120 | *Chưa có* | `REPORTED` | Ngày nghỉ lễ |
| 12 | `slot_types` | V1:L129 | *Chưa có* | `REPORTED` | Loại tiết học |
| 13 | `rooms` | V1:L143 | *Chưa có* | `REPORTED` | Phòng học |
| 14 | `wifi_access_points` | V1:L162 | *Chưa có* | `REPORTED` | Điểm phát Wi-Fi |
| 15 | `room_wifi_access_points` | V1:L174 | *Chưa có* | `REPORTED` | Wi-Fi liên kết phòng học |
| 16 | `attendance_configs` | V1:L186 | *Chưa có* | `REPORTED` | Cấu hình điểm danh |
| 17 | `users` | V2:L7 | `User.java` | `VERIFIED` | Tài khoản hệ thống |
| 18 | `student_profiles` | V2:L29 | `StudentProfile.java` | `VERIFIED` | Hồ sơ sinh viên |
| 19 | `lecturer_profiles` | V2:L39 | `LecturerProfile.java` | `VERIFIED` | Hồ sơ giảng viên |
| 20 | `lecturer_grade_otps` | V2:L47 | `LecturerGradeOtp.java` | `VERIFIED` | OTP khóa điểm giảng viên |
| 21 | `user_permissions` | V2:L56 | `UserPermission.java` | `VERIFIED` | Bảng phân quyền chi tiết |
| 22 | `user_device_tokens` | V2:L65 | `UserDeviceToken.java` | `VERIFIED` | Token thiết bị FCM |
| 23 | `user_sessions` | V2:L76 | `UserSession.java` | `VERIFIED` | Quản lý phiên làm việc |
| 24 | `access_logs` | V2:L92 | `AccessLog.java` | `VERIFIED` | Nhật ký truy cập API |
| 25 | `face_encodings` | V2:L103 | `FaceEncoding.java` | `VERIFIED` | Vector đặc trưng khuôn mặt |
| 26 | `class_sections` | V3:L7 | *Chưa có* | `REPORTED` | Lớp học phần |
| 27 | `teaching_assignments` | V3:L30 | *Chưa có* | `REPORTED` | Phân công giảng dạy |
| 28 | `enrollments` | V3:L38 | *Chưa có* | `REPORTED` | Sinh viên đăng ký lớp |
| 29 | `timetable_slots` | V3:L49 | *Chưa có* | `REPORTED` | Lịch biểu thời khóa biểu |
| 30 | `grade_components` | V3:L64 | *Chưa có* | `REPORTED` | Đầu điểm thành phần |
| 31 | `student_grades` | V3:L78 | *Chưa có* | `REPORTED` | Điểm số của sinh viên |
| 32 | `attendance_sessions` | V3:L91 | *Chưa có* | `REPORTED` | Buổi điểm danh |
| 33 | `student_attendances` | V3:L102 | *Chưa có* | `REPORTED` | Nhật ký điểm danh chi tiết |
| 34 | `assignments` | V3:L125 | *Chưa có* | `REPORTED` | Bài tập giao |
| 35 | `assignment_submissions` | V3:L142 | *Chưa có* | `REPORTED` | Nộp bài tập |
| 36 | `chat_groups` | V3:L158 | *Chưa có* | `REPORTED` | Nhóm thảo luận lớp |
| 37 | `chat_group_members` | V3:L168 | *Chưa có* | `REPORTED` | Thành viên nhóm chat |
| 38 | `chat_messages` | V3:L178 | *Chưa có* | `REPORTED` | Tin nhắn trao đổi |
| 39 | `chat_message_reads` | V3:L192 | *Chưa có* | `REPORTED` | Trạng thái đọc tin nhắn |
| 40 | `chat_message_reactions` | V3:L200 | *Chưa có* | `REPORTED` | Tương tác thả cảm xúc |
| 41 | `ai_chat_sessions` | V3:L209 | *Chưa có* | `REPORTED` | Phiên trò chuyện trợ lý AI |
| 42 | `ai_chat_messages` | V3:L220 | *Chưa có* | `REPORTED` | Lịch sử chat trợ lý AI |
| 43 | `notifications` | V3:L233 | *Chưa có* | `REPORTED` | Thông báo gửi người dùng |
| 44 | `news` | V3:L245 | *Chưa có* | `REPORTED` | Bảng tin nhà trường |
| 45 | `news_attachments` | V3:L264 | *Chưa có* | `REPORTED` | Tệp đính kèm bảng tin |
| 46 | `academic_requests` | V3:L271 | *Chưa có* | `REPORTED` | Đơn từ khiếu nại đào tạo |
| 47 | `schedule_requests` | V3:L296 | *Chưa có* | `REPORTED` | Đơn xin đổi lịch/học bù |
| 48 | `alerts` | V3:L317 | *Chưa có* | `REPORTED` | Cảnh báo học vụ & chuyên cần |
| 49 | `system_logs` | V3:L330 | `SystemLog.java` | `VERIFIED` | Nhật ký thao tác hệ thống |
| 50 | `import_jobs` | V3:L345 | *Chưa có* | `REPORTED` | Lô xử lý import dữ liệu |

---

### 2.2. Backend API & Business Services

| Chức năng | Endpoint Canonical | File Code Hiện Có | Trạng thái |
| :--- | :--- | :--- | :---: |
| **Login** | `POST /api/v1/auth/login` | `AuthController.java:L20` | `VERIFIED` |
| **Logout** | `POST /api/v1/auth/logout` | `AuthController.java:L28` | `VERIFIED` |
| **Refresh Token** | `POST /api/v1/auth/refresh-token` | `AuthController.java:L33` | `VERIFIED` |
| **View Profile** | `GET /api/v1/auth/me` | `AuthController.java:L39` | `VERIFIED` |
| **Update Profile** | `PUT /api/v1/auth/profile` | `AuthController.java:L45` | `VERIFIED` |
| **Change Password** | `POST /api/v1/auth/change-password` | `AuthController.java:L51` | `VERIFIED` |
| **Forgot Password** | `POST /api/v1/auth/forgot-password` | `AuthController.java:L57` | `VERIFIED` |
| **Reset Password** | `POST /api/v1/auth/reset-password` | `AuthController.java:L64` | `VERIFIED` |
| **Create User (3.2.4)** | `POST /api/v1/users` | `UserController.java:L32` | `VERIFIED` |
| **Get User Detail (3.2.5)** | `GET /api/v1/users/{id}` | `UserController.java:L44` | `VERIFIED` |
| **Update User (3.2.6)** | `PUT /api/v1/users/{id}` | `UserController.java:L54` | `VERIFIED` |
| **Delete User (3.2.7)** | `DELETE /api/v1/users/{id}` | `UserController.java:L66` | `VERIFIED` |
| **List Users (3.2.5,8,9)** | `GET /api/v1/users` | `UserController.java:L76` | `VERIFIED` |
| **Active Users** | `GET /api/v1/users/active` | `UserController.java:L90` | `VERIFIED` |
| **Inactive Users** | `GET /api/v1/users/inactive` | `UserController.java:L102` | `VERIFIED` |
| **Import Users (3.2.2)** | `POST /api/v1/users/import` | *Chưa có* | `MISSING` |
| **Activate User (3.2.3)** | `POST /api/v1/users/{id}/activate` | *Chưa có* | `MISSING` |
| **Block/Unblock (3.2.7)** | `PATCH /api/v1/users/{id}/status` | *Chưa có* | `MISSING` |
| **Assign Perm (3.2.8)** | `POST /api/v1/users/{id}/permissions` | *Chưa có* | `MISSING` |

---

### 2.3. AI Microservice (ai-service/)

| Endpoint | Chức năng dự kiến | Hiện trạng thực tế | Phân loại |
| :--- | :--- | :--- | :---: |
| `GET /health` | Kiểm tra tình trạng dịch vụ | Trả JSON `{status: "UP"}` | `VERIFIED` |
| `POST /api/v1/face/extract-embedding` | Trích xuất vector 128 chiều từ ảnh | Trả cố định mảng `[0.0] * 128`, confidence `0.98` | `MOCK` |
| `POST /api/v1/face/check-liveness` | Kiểm tra liveness chớp mắt/quay đầu | Trả cố định `is_live: true`, score `0.96` | `MOCK` |

---

### 2.4. Mobile Client (Flutter/Dart trong mobile/)

| Hạng mục | Hiện trạng | Phân loại | Bằng chứng |
| :--- | :--- | :---: | :--- |
| **Framework & DI** | Flutter 3.47.3, GetX, Dio, SecureStorage | `VERIFIED` | `pubspec.yaml:L9-L18` |
| **Màn hình Đăng nhập** | Form đăng nhập, kết nối API backend | `VERIFIED` | `lib/feature/auth/views/login_view.dart` |
| **Camera Check-in UI** | Khung hiển thị giả lập UI điểm danh | `MOCK` | `face_checkin_view.dart:L111-L117` |
| **Plugin ML Kit Face Detection** | Chưa tích hợp thư viện nhận diện trên máy | `MISSING` | Thiếu trong `pubspec.yaml` |
| **Plugin Wi-Fi BSSID** | Chưa tích hợp thư viện quét mạng Wi-Fi | `MISSING` | Thiếu trong `pubspec.yaml` |
| **Plugin Quét mã QR** | Chưa tích hợp thư viện quét QR code | `MISSING` | Thiếu trong `pubspec.yaml` |

---

## 3. DANH MỤC LỖ HỔNG BẢO MẬT & THỨ TỰ KHẮC PHỤC (BLOCKERS & REMEDIATION)

### Ưu tiên 1 (Critical Security - Cần xử lý đầu tiên trước khi ra Production):
1. **Rò rỉ mã OTP thô ra log**: `EmailServiceImpl.java:L16` in toàn bộ mã OTP 6 chữ số vào log hệ thống. Cần che giấu dạng `[******]`.
2. **Rò rỉ JWT thô khi Redis lỗi**: `TokenRedisService.java:L37, L48` in key chứa toàn bộ JWT token khi Redis failover. Cần chuyển key sang mã băm SHA-256 hoặc `jti`.
3. **Gỡ bỏ Mock Confidence trên Mobile**: `face_checkin_view.dart:L111-L117` hardcode độ chính xác 99.2%. Cần xóa mock snackbar này và chuyển sang thông báo trạng thái "Tính năng camera đang được đồng bộ với AI Service".

### Ưu tiên 2 (Hoàn thiện Module 3.2 còn thiếu):
4. Triển khai API Block/Unblock chuyên biệt và thu hồi token tức thời (`3.2.7`).
5. Triển khai API Phân quyền chi tiết (`3.2.8 Assign User Permission`).
6. Triển khai API Kích hoạt tài khoản (`3.2.3 Active User Account`).
7. Triển khai Batch Import tài khoản từ Excel (`3.2.2 Import List of User Inactive`).

### Ưu tiên 3 (Chuẩn bị Sinh trắc học & Điểm danh):
8. Tích hợp mô hình AI thực tế (FaceNet/dlib/InsightFace) vào `ai-service` thay thế mock.
9. Bổ sung Flutter plugins: `google_mlkit_face_detection`, `network_info_plus`, `mobile_scanner`.
