# BẢNG TỔNG HỢP VÀ ĐỐI CHIẾU MÀN HÌNH GOOGLE STITCH (STITCH SCREEN INVENTORY)
**Mã tài liệu:** AUDIT-STITCH-SCREENS-2026  
**Dự án Google Stitch ID:** `3214444012266330806`  
**Bộ nhận diện thiết kế:** Academic Precision (Xanh đậm Royal Blue `#1D4ED8`, Xanh ngọc Emerald `#10B981`, Teal `#14B8A6`)  
**Ngày kiểm toán:** 15/10/2026  

---

## 1. TỔNG QUAN TÌNH TRẠNG CHUYỂN ĐỔI (CONVERSION OVERVIEW)

* **Tổng số màn hình thiết kế trên Stitch:** **39 màn hình**.
* **Đã chuyển đổi hoàn chỉnh thành React Component (`DONE`):** **5 màn hình** (kèm 1 màn hình dẫn xuất Đặt lại mật khẩu Reset Password).
* **Đang ở trạng thái Mock/Bản nháp tĩnh (`MOCK_ONLY`):** **1 màn hình** (`DashboardPage.tsx`).
* **Chưa chuyển đổi (`NOT_STARTED`):** **33 màn hình**.

---

## 2. BẢNG CHI TIẾT 39 MÀN HÌNH STITCH VÀ ÁNH XẠ REACT ROUTE

| STT | Stitch Screen ID | Tiêu Đề Thiết Kế Trên Stitch | Kích Thước | Vai Trò (Role) | Phân Loại Nghiệp Vụ | Tệp React Component Tương Ứng | Trạng Thái Tích Hợp |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- | :---: |
| 1 | `41e9fae8d8d44fac8260cc17252be377` | UniCheck - Đăng nhập hệ thống | 2560x2048 | ALL | 3.1 Authentication | `pages/auth/LoginPage.tsx` | **`DONE`** |
| 2 | `bdeeb9ad8e6e48eb830753c46c0718eb` | UniCheck - Quên mật khẩu | 2560x2048 | ALL | 3.1 Authentication | `pages/auth/ForgotPasswordPage.tsx` | **`DONE`** |
| 3 | `a82fccdfa56d4efa8dec59a3a636a0ff` | UniCheck - Xác thực mã OTP | 2560x2048 | ALL | 3.1 Authentication | `pages/auth/VerifyOtpPage.tsx` | **`DONE`** |
| 4 | `a982502abde84a82927fbde7620c59c5` | UniCheck - Đổi mật khẩu | 2560x2276 | ALL | 3.1 Authentication | `pages/auth/ChangePasswordPage.tsx` | **`DONE`** |
| 5 | `1c85a287b68c437e8e7fe5f9f829bc16` | UniCheck - Thông tin cá nhân | 2560x2624 | ALL | 3.1 Profile | `pages/profile/ProfilePage.tsx` | **`DONE`** |
| 6 | *(Dẫn xuất từ 4 & 2)* | UniCheck - Đặt lại mật khẩu | 2560x2276 | ALL | 3.1 Reset Password | `pages/auth/ResetPasswordPage.tsx` | **`DONE`** |
| 7 | `3b9a0eb0bbfe4fcb86c092384f9b2220` | UniCheck - Bảng điều khiển điều hành & Điểm danh AI | 2560x3948 | ADMIN | 3.4 Monitoring | `pages/dashboard/DashboardPage.tsx` | **`MOCK_ONLY`** |
| 8 | `509f654c8f3d4d28bcb51b4770539e8b` | UniCheck - Tổng quan hệ thống | 2560x4034 | ADMIN | 3.4 Monitoring | *Chưa ánh xạ* | `NOT_STARTED` |
| 9 | `21275607791c43e58ee6a5b2db656d20` | UniCheck - Quản lý người dùng | 3600x3418 | ADMIN | 3.2 User Management | *Dự kiến: `pages/users/UserListPage.tsx`* | `NOT_STARTED` |
| 10 | `8e1010eda64348f98bd95f7c01648bef` | UniCheck - Quản lý sinh viên | 2560x3670 | ADMIN | 3.5 Student Records | *Dự kiến: `pages/students/StudentListPage.tsx`* | `NOT_STARTED` |
| 11 | `3c68af65d6ae4a0f9509aed6e9ea81be` | UniCheck - Quản lý giảng viên | 3904x2746 | ADMIN | 3.6 Lecturer Records | *Dự kiến: `pages/lecturers/LecturerListPage.tsx`* | `NOT_STARTED` |
| 12 | `495a21f075ca479698f5f5075cee8a41` | UniCheck - Quản lý lớp học phần | 2560x3018 | ADMIN | 3.11 Class Sections | *Dự kiến: `pages/classes/ClassListPage.tsx`* | `NOT_STARTED` |
| 13 | `a9f520acd00440c8a26633aec9a8799c` | UniCheck - Danh mục học phần | 3904x3044 | ADMIN | 3.9 Course Catalog | *Dự kiến: `pages/courses/CourseCatalogPage.tsx`* | `NOT_STARTED` |
| 14 | `4f0245590b1b4c6ab231b412b5ba845d` | UniCheck - Học kỳ & Niên khóa | 2560x2878 | ADMIN | 3.10 Semesters | *Dự kiến: `pages/semesters/SemesterPage.tsx`* | `NOT_STARTED` |
| 15 | `e796d9e992364bfcbf8a32a6330927ce` | UniCheck - Phòng học & Wi-Fi AP | 3904x3470 | ADMIN | 3.7 Facilities | *Dự kiến: `pages/facilities/RoomsWifiPage.tsx`* | `NOT_STARTED` |
| 16 | `4f83098c7b904d4389563c28f54e1c48` | UniCheck - Quản lý phiên điểm danh | 2560x3244 | ADMIN | 3.16 Attendance Admin | *Dự kiến: `pages/attendance/SessionManagementPage.tsx`* | `NOT_STARTED` |
| 17 | `300c3071598340e5981a9a5f5097f909` | UniCheck - Cấu hình cơ chế điểm danh | 2560x3172 | ADMIN | 3.15 Configuration | *Dự kiến: `pages/attendance/AttendanceConfigPage.tsx`* | `NOT_STARTED` |
| 18 | `c9523d6727af4088a7135067d379c570` | UniCheck - Báo cáo & Thống kê chuyên cần | 2560x4362 | ADMIN | 3.16 Reporting | *Dự kiến: `pages/reports/AttendanceReportPage.tsx`* | `NOT_STARTED` |
| 19 | `769ce5a775bd429cb46ee5e447868e98` | UniCheck - Lịch sử điểm danh toàn trường | 2560x3068 | ADMIN | 3.16 Attendance History| *Dự kiến: `pages/reports/CampusHistoryPage.tsx`* | `NOT_STARTED` |
| 20 | `dd2b950932464528a607e4ebd490f5e1` | UniCheck - Cảnh báo an ninh & Bất thường | 2560x3248 | ADMIN | 3.4 Monitoring | *Dự kiến: `pages/alerts/SecurityAlertsPage.tsx`* | `NOT_STARTED` |
| 21 | `6dd3388036ab44f5bf221a5f6e7f24e0` | UniCheck - Nhật ký kiểm toán | 2560x3428 | ADMIN | 3.4 Audit Trail | *Dự kiến: `pages/audit/AuditLogsPage.tsx`* | `NOT_STARTED` |
| 22 | `1a99da032e154d86b432c579ec4e4bf1` | UniCheck - Ghi danh & Đăng ký | 2560x3508 | ADMIN | 3.12 Enrollment | *Dự kiến: `pages/enrollment/EnrollmentPage.tsx`* | `NOT_STARTED` |
| 23 | `ac1b85bea7f6478e9c77fd6a4e9594f9` | UniCheck - Thời khóa biểu | 2560x3132 | ADMIN | 3.13 Timetable | *Dự kiến: `pages/timetable/AdminTimetablePage.tsx`* | `NOT_STARTED` |
| 24 | `0d390145e7e14c498c170acf8ed21778` | UniCheck - Quản lý Bài tập & Đồ án | 2560x2908 | ADMIN | 3.19 Assessment | *Dự kiến: `pages/assignments/AssignmentPage.tsx`* | `NOT_STARTED` |
| 25 | `ef5d3e2ef1f14d349f4f732efcee4e55` | UniCheck - Sổ điểm & Đánh giá học phần | 2560x2626 | ADMIN | 3.19 Grading | *Dự kiến: `pages/grades/GradeBookPage.tsx`* | `NOT_STARTED` |
| 26 | `ef7e12816fa44ec387f5b605b9df08ff` | UniCheck - Trung tâm thông báo | 2560x4948 | ALL | 3.3 Notifications | *Dự kiến: `pages/notifications/NotificationCenterPage.tsx`* | `NOT_STARTED` |
| 27 | `d8c0e3365a78453f95c9eef4d99c8ba9` | UniCheck Giảng viên - Bảng điều khiển | 2560x3992 | LECTURER | 3.17 Workspace | *Dự kiến: `pages/lecturer/LecturerDashboardPage.tsx`* | `NOT_STARTED` |
| 28 | `bd31d3594ab14b2b87223f9134cf0982` | UniCheck Giảng viên - Lớp học phần phụ trách | 2560x2588 | LECTURER | 3.17 Classes | *Dự kiến: `pages/lecturer/MyClassesPage.tsx`* | `NOT_STARTED` |
| 29 | `48b3b59ffd0c4038a7dad1e14812b5f6` | UniCheck Giảng viên - Thời khóa biểu giảng dạy | 2560x2752 | LECTURER | 3.17 Timetable | *Dự kiến: `pages/lecturer/LecturerTimetablePage.tsx`* | `NOT_STARTED` |
| 30 | `5c0df9af4d2545919e8f774c1159e7da` | UniCheck Giảng viên - Khởi tạo phiên & QR động | 2560x3508 | LECTURER | 3.16 QR Generation | *Dự kiến: `pages/lecturer/ActiveSessionQRPage.tsx`* | `NOT_STARTED` |
| 31 | `c20e515d6d0940379d90ea268522b07e` | UniCheck Giảng viên - Giám sát điểm danh trực tiếp | 2560x2048 | LECTURER | 3.16 Live Monitor | *Dự kiến: `pages/lecturer/LiveMonitorPage.tsx`* | `NOT_STARTED` |
| 32 | `dbeb7a8d359c4fbaa1363673ceac548e` | UniCheck Giảng viên - Báo cáo & Lịch sử điểm danh | 2560x5144 | LECTURER | 3.16 Class Reports | *Dự kiến: `pages/lecturer/LecturerReportsPage.tsx`* | `NOT_STARTED` |
| 33 | `f3fad431243448f4a7758c9ced16b695` | UniCheck Giảng viên - Xét duyệt đơn học vụ & Nghỉ phép | 2560x3300 | LECTURER | 3.14 Requests | *Dự kiến: `pages/lecturer/ApproveRequestsPage.tsx`* | `NOT_STARTED` |
| 34 | `099bfb7b8c5b4eddad24a315b641136e` | UniCheck Sinh viên - Bảng điều khiển | 2560x3922 | STUDENT | 3.18 Workspace | *Dự kiến: `pages/student/StudentDashboardPage.tsx`* | `NOT_STARTED` |
| 35 | `e489c26939c544de946dc0a26b3b422e` | UniCheck Sinh viên - Thời khóa biểu tuần | 2560x3378 | STUDENT | 3.18 Timetable | *Dự kiến: `pages/student/StudentTimetablePage.tsx`* | `NOT_STARTED` |
| 36 | `b802d76468b843919de0808f802f075e` | UniCheck Sinh viên - Lớp học phần của tôi | 2560x4838 | STUDENT | 3.18 Classes | *Dự kiến: `pages/student/MyCoursesPage.tsx`* | `NOT_STARTED` |
| 37 | `9a5615c27e8a4b2ca49a2588ab94cfa7` | UniCheck Sinh viên - Điểm danh buổi học | 2560x3068 | STUDENT | 3.16 Checkin | *Dự kiến: `pages/student/StudentCheckinPage.tsx`* | `NOT_STARTED` |
| 38 | `9ba51f6ecd70421582816363439f4530` | UniCheck Sinh viên - Lịch sử điểm danh | 2560x3148 | STUDENT | 3.16 History | *Dự kiến: `pages/student/StudentHistoryPage.tsx`* | `NOT_STARTED` |
| 39 | `c7ac82956cfe41b3b762e7aaabc2bcfa` | UniCheck Sinh viên - Đơn xin nghỉ & Khiếu nại học vụ | 2560x3548 | STUDENT | 3.14 Requests | *Dự kiến: `pages/student/StudentRequestsPage.tsx`* | `NOT_STARTED` |
| 40 | `a17db05b39144990b49bee366c1e3b43` | UniCheck Sinh viên - Đăng ký & Cập nhật Face-ID | 2560x2864 | STUDENT | 3.21 Biometrics | *Dự kiến: `pages/student/RegisterFaceIdPage.tsx`* | `NOT_STARTED` |

---

## 3. ĐÁNH GIÁ MỨC ĐỘ SẴN SÀNG CỦA THIẾT KẾ STITCH

1. **Tính hoàn chỉnh của thiết kế:** Thiết kế Stitch có độ chi tiết rất cao, đầy đủ các trạng thái rỗng (empty state), phân trang (pagination), bộ lọc nâng cao, biểu đồ phân tích và bảng dữ liệu học thuật chuẩn hóa.
2. **Khả năng tái sử dụng Atomic UI:** Toàn bộ 33 màn hình còn lại đều có thể lắp ráp nhanh chóng từ 16 Atomic Component sẵn có trong thư mục [`frontend/src/common-ui/`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/common-ui) mà không cần viết lại CSS từ đầu.
3. **Phân chia theo phân hệ phát triển (Giai đoạn 4 trở đi):**
   * **Giai đoạn 4 (Ưu tiên số 1):** Triển khai Quản lý Người dùng (Màn hình `21275607791c43e58ee6a5b2db656d20`, `8e1010eda64348f98bd95f7c01648bef`, `3c68af65d6ae4a0f9509aed6e9ea81be`) vì Backend đã có sẵn Controller/Service.
   * **Giai đoạn 5 (Ưu tiên số 2):** Triển khai Quản lý Đào tạo & Lớp học phần (`495a21f075ca479698f5f5075cee8a41`, `a9f520acd00440c8a26633aec9a8799c`, `4f0245590b1b4c6ab231b412b5ba845d`, `e796d9e992364bfcbf8a32a6330927ce`).
   * **Giai đoạn 6 (Ưu tiên số 3):** Triển khai Không gian Giảng viên & Khởi tạo phiên điểm danh QR (`d8c0e3365a78453f95c9eef4d99c8ba9`, `5c0df9af4d2545919e8f774c1159e7da`, `c20e515d6d0940379d90ea268522b07e`).
