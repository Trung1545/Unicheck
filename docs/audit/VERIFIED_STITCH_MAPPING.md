# UniCheck — Bảng Ánh Xạ Màn Hình Google Stitch Đã Xác Minh Thực Tế (Verified Stitch Mapping)

> **Mã tài liệu:** AUDIT-VERIFIED-STITCH-2026  
> **Dự án Google Stitch ID:** `3214444012266330806`  
> **Nguồn dữ liệu:** Stitch MCP Server API (`projects/3214444012266330806/screens`)  
> **Ngày xác minh:** 15/10/2026  
> **Quy tắc:** Stitch là nguồn chuẩn duy nhất (Single Source of Truth) về bố cục, Typography, Color Tokens (Academic Precision), Spacing và Components.

---

## 1. Đính Chính Sai Lệch Về Số Lượng & Mã Màn Hình Từ Audit Trước

1. **Số lượng màn hình thực tế trên Stitch: CHÍNH XÁC 39 MÀN HÌNH** (không phải 40).
   - *Nguyên nhân sai lệch trước:* Báo cáo cũ đưa thêm mục phái sinh `"UniCheck - Đặt lại mật khẩu"` (mã React `ResetPasswordPage.tsx` phát triển dựa trên màn hình Quên mật khẩu & Đổi mật khẩu) vào giữa bảng và đánh số STT thứ 6, làm số thứ tự bị đẩy lên 40.
2. **Khắc phục các mã Stitch Screen ID bị hư cấu (Hallucinated IDs):**
   - Loại bỏ hoàn toàn các mã ID không tồn tại trong dự án: `060370631d8745588efc3fa00cb31238`, `c5fbb20c328f416ba4ea4904bf03a0ef`, `4c5db70c9dd942f6aa1cc738a1f81d11`, `6bc265c71bba4fe7946927da8e15d8f6`, `0ff325e0192e44d59178ad3a6fc4d334`, `b2c58a5da7994917992797e87df3323a`, `173367f0f6664d6dbef20a232777b720`, `75f63d043f654b9d885a5be7f6f595df`, `9b42247fb42646b998cf7784013ffeb8`, `1f531aa938c8452394cb58dd88800539`.
   - Toàn bộ 39 màn hình dưới đây đều được truy xuất trực tiếp từ máy chủ Google Stitch thông qua lệnh `list_screens(projectId: "3214444012266330806")`.

---

## 2. Bảng Danh Mục 39 Màn Hình Stitch Đã Xác Minh & Ánh Xạ React Web

| STT | Stitch Screen ID | Tên Thiết Kế Chính Xác (Stitch Title) | Kích Thước | Vai Trò (Role) | Tuyến Đường React (Route) | React Component Tương Ứng | API Backend Phụ Thuộc | Trạng Thái |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- | :--- | :---: |
| **1** | `41e9fae8d8d44fac8260cc17252be377` | UniCheck - Đăng nhập hệ thống | 2560x2048 | ALL | `/login` | [LoginPage.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/auth/LoginPage.tsx) | `POST /auth/login` (ACTIVE) | **DONE** |
| **2** | `bdeeb9ad8e6e48eb830753c46c0718eb` | UniCheck - Quên mật khẩu | 2560x2048 | ALL | `/forgot-password` | [ForgotPasswordPage.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/auth/ForgotPasswordPage.tsx) | `POST /auth/forgot-password` (ACTIVE) | **DONE** |
| **3** | `a82fccdfa56d4efa8dec59a3a636a0ff` | UniCheck - Xác thực mã OTP | 2560x2048 | ALL | `/verify-otp` | [VerifyOtpPage.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/auth/VerifyOtpPage.tsx) | `POST /auth/verify-otp` (ACTIVE) | **DONE** |
| **4** | `a982502abde84a82927fbde7620c59c5` | UniCheck - Đổi mật khẩu | 2560x2276 | ALL | `/change-password` | [ChangePasswordPage.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/auth/ChangePasswordPage.tsx) | `POST /auth/change-password` (ACTIVE) | **DONE** |
| **5** | `1c85a287b68c437e8e7fe5f9f829bc16` | UniCheck - Thông tin cá nhân | 2560x2624 | ALL | `/profile` | [ProfilePage.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/profile/ProfilePage.tsx) | `GET /auth/me`, `PUT /auth/profile` (ACTIVE) | **DONE** |
| **6** | `3b9a0eb0bbfe4fcb86c092384f9b2220` | UniCheck - Bảng điều khiển điều hành & Điểm danh AI | 2560x3948 | ADMIN | `/dashboard` | [DashboardPage.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/dashboard/DashboardPage.tsx) | `GET /admin/dashboard/stats` (PLANNED) | **MOCK_ONLY** |
| **7** | `509f654c8f3d4d28bcb51b4770539e8b` | UniCheck - Tổng quan hệ thống | 2560x4034 | ADMIN | `/admin/overview` | `src/pages/admin/SystemOverviewPage.tsx` | `GET /admin/system/metrics` (PLANNED) | `NOT_STARTED` |
| **8** | `21275607791c43e58ee6a5b2db656d20` | UniCheck - Quản lý người dùng | 3600x3418 | ADMIN | `/admin/users` | `src/pages/admin/UserManagementPage.tsx` | `GET /users`, `POST /users`, `PUT /users/{id}`, `PATCH /users/{id}/status`, `POST /users/import-csv` (ACTIVE) | `NOT_STARTED` *(P0 Sẵn Sàng BE)* |
| **9** | `8e1010eda64348f98bd95f7c01648bef` | UniCheck - Quản lý sinh viên | 2560x3670 | ADMIN | `/admin/students` | `src/pages/admin/StudentManagementPage.tsx` | `GET /users?role=STUDENT` (ACTIVE), `GET /students/{id}/academic-profile` (PLANNED) | `NOT_STARTED` |
| **10** | `3c68af65d6ae4a0f9509aed6e9ea81be` | UniCheck - Quản lý giảng viên | 3904x2746 | ADMIN | `/admin/lecturers` | `src/pages/admin/LecturerManagementPage.tsx` | `GET /users?role=LECTURER` (ACTIVE), `GET /lecturers/{id}/teaching-profile` (PLANNED) | `NOT_STARTED` |
| **11** | `495a21f075ca479698f5f5075cee8a41` | UniCheck - Quản lý lớp học phần | 2560x3018 | ADMIN | `/admin/classes` | `src/pages/admin/ClassSectionPage.tsx` | `GET /classes`, `POST /classes` (PLANNED) | `NOT_STARTED` |
| **12** | `a9f520acd00440c8a26633aec9a8799c` | UniCheck - Danh mục học phần | 3904x3044 | ADMIN | `/admin/courses` | `src/pages/admin/CourseCatalogPage.tsx` | `GET /courses`, `POST /courses` (PLANNED) | `NOT_STARTED` |
| **13** | `4f0245590b1b4c6ab231b412b5ba845d` | UniCheck - Học kỳ & Niên khóa | 2560x2878 | ADMIN | `/admin/semesters` | `src/pages/admin/SemesterManagementPage.tsx` | `GET /semesters`, `POST /semesters` (PLANNED) | `NOT_STARTED` |
| **14** | `e796d9e992364bfcbf8a32a6330927ce` | UniCheck - Phòng học & Wi-Fi AP | 3904x3470 | ADMIN | `/admin/facilities` | `src/pages/admin/FacilitiesWifiPage.tsx` | `GET /facilities/rooms`, `GET /facilities/wifi-ap` (PLANNED) | `NOT_STARTED` |
| **15** | `1a99da032e154d86b432c579ec4e4bf1` | UniCheck - Ghi danh & Đăng ký | 2560x3508 | ADMIN | `/admin/enrollments` | `src/pages/admin/EnrollmentManagementPage.tsx` | `GET /enrollments`, `POST /enrollments` (PLANNED) | `NOT_STARTED` |
| **16** | `ac1b85bea7f6478e9c77fd6a4e9594f9` | UniCheck - Thời khóa biểu | 2560x3132 | ADMIN | `/admin/timetable` | `src/pages/admin/MasterTimetablePage.tsx` | `GET /timetable/slots` (PLANNED) | `NOT_STARTED` |
| **17** | `4f83098c7b904d4389563c28f54e1c48` | UniCheck - Quản lý phiên điểm danh | 2560x3244 | ADMIN | `/admin/attendance/sessions` | `src/pages/admin/AttendanceSessionAdminPage.tsx` | `GET /attendance/sessions` (PLANNED) | `NOT_STARTED` |
| **18** | `300c3071598340e5981a9a5f5097f909` | UniCheck - Cấu hình cơ chế điểm danh | 2560x3172 | ADMIN | `/admin/attendance/configs` | `src/pages/admin/AttendanceConfigPage.tsx` | `GET /attendance/configs`, `PUT /attendance/configs` (PLANNED) | `NOT_STARTED` |
| **19** | `c9523d6727af4088a7135067d379c570` | UniCheck - Báo cáo & Thống kê chuyên cần | 2560x4362 | ADMIN | `/admin/reports/attendance` | `src/pages/admin/AttendanceAnalyticsPage.tsx` | `GET /reports/attendance`, `GET /reports/export/excel` (PLANNED) | `NOT_STARTED` |
| **20** | `769ce5a775bd429cb46ee5e447868e98` | UniCheck - Lịch sử điểm danh toàn trường | 2560x3068 | ADMIN | `/admin/attendance/history` | `src/pages/admin/CampusAttendanceHistoryPage.tsx` | `GET /attendance/history` (PLANNED) | `NOT_STARTED` |
| **21** | `dd2b950932464528a607e4ebd490f5e1` | UniCheck - Cảnh báo an ninh & Bất thường | 2560x3248 | ADMIN | `/admin/alerts` | `src/pages/admin/SecurityAlertsPage.tsx` | `GET /alerts`, `PATCH /alerts/{id}/resolve` (PLANNED) | `NOT_STARTED` |
| **22** | `6dd3388036ab44f5bf221a5f6e7f24e0` | UniCheck - Nhật ký kiểm toán | 2560x3428 | ADMIN | `/admin/audit-logs` | `src/pages/admin/AuditLogViewerPage.tsx` | `GET /admin/system-logs`, `GET /admin/access-logs` (PLANNED) | `NOT_STARTED` |
| **23** | `0d390145e7e14c498c170acf8ed21778` | UniCheck - Quản lý Bài tập & Đồ án | 2560x2908 | ADMIN | `/admin/assignments` | `src/pages/admin/AssignmentAdminPage.tsx` | `GET /assignments` (PLANNED) | `NOT_STARTED` |
| **24** | `ef5d3e2ef1f14d349f4f732efcee4e55` | UniCheck - Sổ điểm & Đánh giá học phần | 2560x2626 | ADMIN | `/admin/grades` | `src/pages/admin/GradeBookAdminPage.tsx` | `GET /grades`, `PUT /grades` (PLANNED) | `NOT_STARTED` |
| **25** | `ef7e12816fa44ec387f5b605b9df08ff` | UniCheck - Trung tâm thông báo | 2560x4948 | ALL | `/notifications` | `src/pages/notifications/NotificationCenterPage.tsx` | `GET /notifications`, `PATCH /notifications/{id}/read` (PLANNED) | `NOT_STARTED` |
| **26** | `d8c0e3365a78453f95c9eef4d99c8ba9` | UniCheck Giảng viên - Bảng điều khiển | 2560x3992 | LECTURER | `/lecturer/dashboard` | `src/pages/lecturer/LecturerDashboardPage.tsx` | `GET /lecturer/dashboard/stats` (PLANNED) | `NOT_STARTED` |
| **27** | `bd31d3594ab14b2b87223f9134cf0982` | UniCheck Giảng viên - Lớp học phần phụ trách | 2560x2588 | LECTURER | `/lecturer/classes` | `src/pages/lecturer/LecturerClassesPage.tsx` | `GET /lecturer/classes` (PLANNED) | `NOT_STARTED` |
| **28** | `48b3b59ffd0c4038a7dad1e14812b5f6` | UniCheck Giảng viên - Thời khóa biểu giảng dạy | 2560x2752 | LECTURER | `/lecturer/timetable` | `src/pages/lecturer/LecturerTimetablePage.tsx` | `GET /lecturer/timetable` (PLANNED) | `NOT_STARTED` |
| **29** | `5c0df9af4d2545919e8f774c1159e7da` | UniCheck Giảng viên - Khởi tạo phiên & QR động | 2560x3508 | LECTURER | `/lecturer/session/qr` | `src/pages/lecturer/SessionQrCodePage.tsx` | `POST /attendance/sessions`, `GET /attendance/sessions/{id}/qr-token` (PLANNED) | `NOT_STARTED` |
| **30** | `c20e515d6d0940379d90ea268522b07e` | UniCheck Giảng viên - Giám sát điểm danh trực tiếp | 2560x2048 | LECTURER | `/lecturer/session/monitor` | `src/pages/lecturer/LiveMonitorPage.tsx` | `GET /attendance/sessions/{id}/attendees` + WebSocket `/topic/session.{id}` (PLANNED) | `NOT_STARTED` |
| **31** | `dbeb7a8d359c4fbaa1363673ceac548e` | UniCheck Giảng viên - Báo cáo & Lịch sử điểm danh | 2560x5144 | LECTURER | `/lecturer/reports` | `src/pages/lecturer/LecturerReportsPage.tsx` | `GET /lecturer/reports/attendance` (PLANNED) | `NOT_STARTED` |
| **32** | `f3fad431243448f4a7758c9ced16b695` | UniCheck Giảng viên - Xét duyệt đơn học vụ & Nghỉ phép | 2560x3300 | LECTURER | `/lecturer/requests` | `src/pages/lecturer/LecturerRequestsPage.tsx` | `GET /requests/pending`, `PATCH /requests/{id}/approve` (PLANNED) | `NOT_STARTED` |
| **33** | `099bfb7b8c5b4eddad24a315b641136e` | UniCheck Sinh viên - Bảng điều khiển | 2560x3922 | STUDENT | `/student/dashboard` | `src/pages/student/StudentDashboardPage.tsx` | `GET /student/dashboard/summary` (PLANNED) | `NOT_STARTED` |
| **34** | `e489c26939c544de946dc0a26b3b422e` | UniCheck Sinh viên - Thời khóa biểu tuần | 2560x3378 | STUDENT | `/student/timetable` | `src/pages/student/StudentTimetablePage.tsx` | `GET /student/timetable/week` (PLANNED) | `NOT_STARTED` |
| **35** | `b802d76468b843919de0808f802f075e` | UniCheck Sinh viên - Lớp học phần của tôi | 2560x4838 | STUDENT | `/student/classes` | `src/pages/student/MyClassesPage.tsx` | `GET /student/enrollments` (PLANNED) | `NOT_STARTED` |
| **36** | `9a5615c27e8a4b2ca49a2588ab94cfa7` | UniCheck Sinh viên - Điểm danh buổi học | 2560x3068 | STUDENT | `/student/check-in` | `src/pages/student/StudentCheckinPage.tsx` | `POST /attendance/check-in` (PLANNED) | `NOT_STARTED` |
| **37** | `9ba51f6ecd70421582816363439f4530` | UniCheck Sinh viên - Lịch sử điểm danh | 2560x3148 | STUDENT | `/student/history` | `src/pages/student/StudentHistoryPage.tsx` | `GET /student/attendance/history` (PLANNED) | `NOT_STARTED` |
| **38** | `c7ac82956cfe41b3b762e7aaabc2bcfa` | UniCheck Sinh viên - Đơn xin nghỉ & Khiếu nại học vụ | 2560x3548 | STUDENT | `/student/requests` | `src/pages/student/StudentRequestsPage.tsx` | `GET /student/requests`, `POST /student/requests` (PLANNED) | `NOT_STARTED` |
| **39** | `a17db05b39144990b49bee366c1e3b43` | UniCheck Sinh viên - Đăng ký & Cập nhật Face-ID | 2560x2864 | STUDENT | `/student/face-id` | `src/pages/student/FaceRegistrationPage.tsx` | `POST /attendance/register-face` (PLANNED) | `NOT_STARTED` |

---

## 3. Phân Nhóm 39 Màn Hình Theo Vai Trò (Role Distribution)

* **Chung cho mọi vai trò (ALL - 6 màn hình):** `LoginPage` (1), `ForgotPasswordPage` (2), `VerifyOtpPage` (3), `ChangePasswordPage` (4), `ProfilePage` (5), `NotificationCenterPage` (25).
* **Quản trị viên (ADMIN - 19 màn hình):** Màn hình 6 đến 24 (Bảng điều khiển, Quản lý người dùng/sinh viên/giảng viên, Lớp học phần, Học kỳ, Phòng học, Wi-Fi, Thời khóa biểu, Điểm danh, Báo cáo, Cảnh báo an ninh, Nhật ký kiểm toán, Bài tập, Sổ điểm).
* **Giảng viên (LECTURER - 7 màn hình):** Màn hình 26 đến 32 (Dashboard giảng viên, Lớp phụ trách, Lịch dạy, Khởi tạo QR động, Giám sát trực tiếp realtime, Báo cáo chuyên cần, Xét duyệt đơn từ).
* **Sinh viên (STUDENT - 7 màn hình):** Màn hình 33 đến 39 (Dashboard sinh viên, Thời khóa biểu, Lớp của tôi, Điểm danh, Lịch sử chuyên cần, Gửi đơn xin nghỉ, Đăng ký Face-ID).
