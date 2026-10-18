# MA TRẬN CHỨC NĂNG DỰ ÁN UNICHECK (FEATURE AUDIT MATRIX)
**Mã tài liệu:** AUDIT-FEATURE-MATRIX-2026  
**Ngày kiểm toán:** 15/10/2026  
**Quy ước trạng thái:**
* `DONE`: Hoàn thiện cả giao diện, xử lý nghiệp vụ máy chủ và có kiểm thử tự động xác minh.
* `PARTIAL`: Đã triển khai một phần nhưng còn thiếu các luồng phụ hoặc liên kết giữa các tầng.
* `UI_ONLY`: Mới chỉ có giao diện phía client, chưa có endpoint backend hoặc dữ liệu thật.
* `BACKEND_ONLY`: Đã có Controller/Service/CSDL nhưng chưa có giao diện trên Web/Mobile.
* `MOCK_ONLY`: Chức năng đang trả kết quả giả lập hoặc dữ liệu tĩnh hardcoded.
* `NOT_STARTED`: Chưa được lập trình ở bất kỳ phân hệ nào.
* `BLOCKED`: Bị chặn do thiếu phụ thuộc nền tảng hoặc dịch vụ bên ngoài chưa sẵn sàng.

---

## 1. MA TRẬN TỔNG QUAN CÁC NHÓM NGHIỆP VỤ CHÍNH

| STT | Nhóm Chức Năng | Web Frontend | Backend Core | AI Microservice | Flutter Mobile | Trạng Thái Tổng Thể | Bằng Chứng / File Mã Nguồn |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **1** | **Xác thực hệ thống (Authentication)** | `DONE` | `DONE` | - | `DONE` | **`DONE`** | `LoginPage.tsx`, `AuthController.java`, `auth_controller.dart` |
| **2** | **Xoay vòng Token & Session (RTR)** | `DONE` | `DONE` | - | `DONE` | **`DONE`** | `axios-instance.ts`, `TokenRedisService.java`, `api_client.dart` |
| **3** | **Quên & Đặt lại mật khẩu (OTP)** | `DONE` | `DONE` | - | `NOT_STARTED` | **`DONE` (Web)** | `ForgotPasswordPage.tsx`, `VerifyOtpPage.tsx`, `ResetPasswordPage.tsx`, `AuthServiceImpl.java:L293-L326` |
| **4** | **Đổi mật khẩu cá nhân & Bắt buộc lần đầu** | `DONE` | `DONE` | - | `NOT_STARTED` | **`DONE` (Web)** | `ChangePasswordPage.tsx`, `AuthServiceImpl.java:L276-L290` |
| **5** | **Xem & Cập nhật Hồ sơ cá nhân** | `DONE` | `DONE` | - | `PARTIAL` | **`DONE` (Web)** | `ProfilePage.tsx`, `AuthServiceImpl.java:L239-L272` |
| **6** | **Phân quyền truy cập (RBAC / Method Security)** | `DONE` | `DONE` | - | `DONE` | **`DONE`** | `routes/index.tsx`, `@PreAuthorize`, `role_guard.dart` |
| **7** | **Quản lý Tài khoản (User CRUD)** | `NOT_STARTED` | `DONE` | - | `NOT_STARTED` | **`BACKEND_ONLY`** | `UserController.java`, `UserServiceImpl.java`, `UserManagementIntegrationTest.java` |
| **8** | **Kích hoạt / Khóa tài khoản (Block/Unblock)** | `NOT_STARTED` | `PARTIAL` | - | `NOT_STARTED` | **`PARTIAL`** | Có logic UserStatus trong `User.java`, thiếu API endpoint chuyên biệt |
| **9** | **Phân quyền chi tiết (Assign Permissions)** | `NOT_STARTED` | `PARTIAL` | - | `NOT_STARTED` | **`PARTIAL`** | Entity `UserPermission.java`, thiếu Controller/Service gán quyền |
| **10** | **Import người dùng từ file Excel** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | Đã có thư viện Apache POI trong `pom.xml`, chưa viết service import |
| **11** | **Đăng ký & Cập nhật dữ liệu FaceID** | `NOT_STARTED` | `PARTIAL` | `MOCK_ONLY` | `NOT_STARTED` | **`MOCK_ONLY`** | CSDL có bảng `face_encodings`, `ai-service` trả `[0.0]*128` |
| **12** | **Face Detection (Phát hiện khuôn mặt)** | `NOT_STARTED` | `NOT_STARTED` | `MOCK_ONLY` | `NOT_STARTED` | **`MOCK_ONLY`** | `ai-service` chưa tích hợp OpenCV / MediaPipe thật; Mobile thiếu ML Kit |
| **13** | **Face Embeddings Extraction** | `NOT_STARTED` | `NOT_STARTED` | `MOCK_ONLY` | `NOT_STARTED` | **`MOCK_ONLY`** | `app.py:L21-L37` trả mảng cố định 128 số 0 |
| **14** | **Face Matching (So khớp sinh trắc học)** | `NOT_STARTED` | `NOT_STARTED` | `NOT_STARTED` | `NOT_STARTED` | **`NOT_STARTED`** | Chưa có logic tính Cosine Similarity / khoảng cách Euclidean |
| **15** | **Liveness Detection (Chống gian lận ảnh)** | `NOT_STARTED` | `NOT_STARTED` | `MOCK_ONLY` | `NOT_STARTED` | **`MOCK_ONLY`** | `app.py:L39-L53` trả cố định `is_live: true, liveness_score: 0.96` |
| **16** | **Camera Check-in Mobile** | - | `NOT_STARTED` | `MOCK_ONLY` | `UI_ONLY` | **`UI_ONLY`** | `face_checkin_view.dart` là giao diện tĩnh, chưa kết nối luồng camera |
| **17** | **Dynamic QR Code (Mã QR động xoay vòng)** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | CSDL có bảng `attendance_sessions`, chưa có endpoint sinh QR động |
| **18** | **Wi-Fi BSSID Matching (Vị trí phòng học)** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | CSDL có bảng `wifi_access_points`, chưa có logic đối soát BSSID |
| **19** | **GPS Geofencing (Tọa độ phòng học)** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | Chưa có trường tọa độ GPS trên bảng `rooms` |
| **20** | **Khởi tạo & Quản lý Ca điểm danh** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | Có bảng `attendance_sessions`, chưa có JPA Entity & Controller |
| **21** | **Ghi nhận Điểm danh (Present/Late/Absent)** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | Có bảng `student_attendances`, chưa có JPA Entity & Controller |
| **22** | **Cảnh báo Bất thường & Gian lận** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | Có bảng `alerts`, chưa có service phát hiện bất thường |
| **23** | **Lịch sử điểm danh Sinh viên** | `NOT_STARTED` | `NOT_STARTED` | - | `UI_ONLY` | **`UI_ONLY`** | Mobile có shell tab, chưa có API backend |
| **24** | **Báo cáo & Thống kê Chuyên cần** | `MOCK_ONLY` | `NOT_STARTED` | - | `NOT_STARTED` | **`MOCK_ONLY`** | `DashboardPage.tsx` hiển thị số liệu tĩnh (48 lớp, 384 SV) |
| **25** | **Xuất Báo cáo Excel / PDF** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | Chưa triển khai |
| **26** | **Quản lý Học kỳ & Khung thời gian** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | Có bảng `semesters`, `slot_types`, chưa có JPA Entity & Service |
| **27** | **Quản lý Danh mục Học phần (Courses)** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | Có bảng `courses`, `course_prerequisites`, chưa có JPA Entity |
| **28** | **Quản lý Lớp học phần & Phân công** | `NOT_STARTED` | `NOT_STARTED` | - | `NOT_STARTED` | **`NOT_STARTED`** | Có bảng `class_sections`, `teaching_assignments`, chưa có JPA Entity |
| **29** | **Thời khóa biểu (Timetable)** | `NOT_STARTED` | `NOT_STARTED` | - | `UI_ONLY` | **`UI_ONLY`** | Mobile có menu Thời khóa biểu nhưng chưa có dữ liệu |
| **30** | **Đơn xin nghỉ & Khiếu nại học vụ** | `NOT_STARTED` | `NOT_STARTED` | - | `UI_ONLY` | **`UI_ONLY`** | Mobile có menu Đơn từ nhưng chưa có xử lý backend |
| **31** | **Hệ thống Kiểm toán (Audit Logs)** | `NOT_STARTED` | `PARTIAL` | - | `NOT_STARTED` | **`PARTIAL`** | Backend có `AccessLog`, `SystemLog` ghi nhận login/logout/user CRUD |

---

## 2. BẢNG CHI TIẾT ĐỐI CHIẾU VỚI TÀI LIỆU SDD (21 MODULE)

| Module SDD | Tên Module Trong Đặc Tả | Trạng Thái Hiện Tại | Tồn Tại Code Ở Tầng Nào? | Hạng Mục Còn Thiếu Để Đạt DONE |
| :---: | :--- | :---: | :--- | :--- |
| **3.1** | **Authentication** | **`DONE`** | Web, Backend, Mobile | Hoàn chỉnh 100% (Login, Logout, Token Rotation, Profile, Password Reset) |
| **3.2** | **System Account Management** | **`PARTIAL`** | Backend (`UserController.java`) | Thiếu Web UI, thiếu API Import Excel, Activate, Block, Gán quyền |
| **3.3** | **Notification Management** | **`NOT_STARTED`** | Chỉ có bảng CSDL `notifications` | Chưa có JPA Entity, Controller, Firebase FCM Service |
| **3.4** | **System Monitoring & Audit** | **`PARTIAL`** | Backend Entity & Service | Đã ghi log vào CSDL (`access_logs`, `system_logs`), thiếu UI tra cứu và lọc log |
| **3.5** | **Student Records Management** | **`PARTIAL`** | Backend Entity `StudentProfile` | Mới lưu hồ sơ sinh viên gắn với User, thiếu quản lý chi tiết CTĐT |
| **3.6** | **Lecturer Records Management** | **`PARTIAL`** | Backend Entity `LecturerProfile` | Mới lưu hồ sơ giảng viên gắn với User, thiếu phân công bộ môn |
| **3.7** | **Facility Management (Room/Wifi)** | **`NOT_STARTED`** | Chỉ có bảng CSDL `rooms`, `wifi_access_points` | Chưa có JPA Entity, Controller, Service quản lý phòng học và điểm phát Wi-Fi |
| **3.8** | **Curriculum Management** | **`NOT_STARTED`** | Chỉ có bảng CSDL `majors`, `specializations` | Chưa có JPA Entity, Controller |
| **3.9** | **Course Catalog Management** | **`NOT_STARTED`** | Chỉ có bảng CSDL `courses` | Chưa có JPA Entity, Controller quản lý học phần |
| **3.10** | **Semester Management** | **`NOT_STARTED`** | Chỉ có bảng CSDL `semesters`, `holidays` | Chưa có JPA Entity, Controller quản lý niên khóa / học kỳ |
| **3.11** | **Class Section Management** | **`NOT_STARTED`** | Chỉ có bảng CSDL `class_sections` | Chưa có JPA Entity, Controller quản lý lớp học phần |
| **3.12** | **Enrollment Management** | **`NOT_STARTED`** | Chỉ có bảng CSDL `enrollments` | Chưa có JPA Entity, Controller đăng ký môn học |
| **3.13** | **Timetable Operations** | **`NOT_STARTED`** | Chỉ có bảng CSDL `timetable_slots` | Chưa có JPA Entity, Controller xếp lịch biểu |
| **3.14** | **Academic Request Management** | **`NOT_STARTED`** | Chỉ có bảng CSDL `academic_requests` | Chưa có JPA Entity, Controller duyệt đơn xin nghỉ |
| **3.15** | **Attendance Configuration** | **`NOT_STARTED`** | Chỉ có bảng CSDL `attendance_configs` | Chưa có JPA Entity, Controller cấu hình quy chế chuyên cần |
| **3.16** | **Attendance Taking & Reporting** | **`NOT_STARTED`** | Bảng CSDL `attendance_sessions`, `student_attendances` | Chưa có JPA Entity, Controller xử lý ca điểm danh |
| **3.17** | **Lecturer Teaching Workspace** | **`NOT_STARTED`** | Mobile có giao diện Shell trống | Chưa kết nối API lịch dạy và kích hoạt ca học |
| **3.18** | **Student Learning Workspace** | **`NOT_STARTED`** | Mobile có giao diện Shell trống | Chưa kết nối API danh sách môn học và kết quả chuyên cần |
| **3.19** | **Grading & Assessment** | **`NOT_STARTED`** | Bảng CSDL `grade_components`, `student_grades` | Chưa có JPA Entity, Controller nhập điểm |
| **3.20** | **Class Communication** | **`NOT_STARTED`** | Bảng CSDL `chat_groups`, `chat_messages` | Chưa có JPA Entity, Controller, WebSocket chat |
| **3.21** | **AI Support Service** | **`MOCK_ONLY`** | Flask `app.py` giả lập kết quả | Cần thay thế bằng mô hình Computer Vision thực tế |

---

## 3. ĐỘ LỆCH KIẾN TRÚC CLIENT (REACT WEB VS FLUTTER MULTI-PLATFORM)

Trong repository tồn tại sự khác biệt lớn giữa 2 định hướng kiến trúc:
1. **Định hướng trong `docs/evidence/flutter_web_auth_verification.md`**:
   * Từng tuyên bố Flutter là *"Frontend duy nhất đang phát triển"* cho cả Mobile, Web và Desktop.
   * Biên dịch ứng dụng ra `mobile/build/web`.
2. **Định hướng trong yêu cầu thực tế người dùng & Báo cáo Thiết kế (SDD Table 2 & Table 3)**:
   * Yêu cầu rõ ràng: **React 18, TypeScript 5.6, Vite 5, Tailwind CSS 3** là nền tảng của Cổng Web Quản Trị Học Viện (Desktop Web Portal).
   * **Flutter/Dart** là Ứng dụng Di Động (Native Mobile App) phục vụ Sinh viên và Giảng viên khi lên lớp.
   * Giao diện Web sử dụng nguồn thiết kế 39 màn hình chuẩn mực từ **Google Stitch (Academic Precision)**, vốn chỉ có mã nguồn HTML/Tailwind CSS tương thích trực tiếp với React SPA, không tương thích với widget tree của Flutter.

**Kết luận thẩm định:** Cần duy trì song song ranh giới phân định rõ ràng:
* [`frontend/`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend) (React): Đảm nhiệm Cổng Quản trị, Đào tạo, Tra cứu học vụ, Báo cáo thống kê màn hình lớn.
* [`mobile/`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile) (Flutter): Đảm nhiệm tính năng di động: quét khuôn mặt camera, quét mã QR và lấy thông tin Wi-Fi BSSID tại giảng đường.
