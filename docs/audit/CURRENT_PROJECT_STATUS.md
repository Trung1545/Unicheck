# BÁO CÁO TOÀN DIỆN VỀ HIỆN TRẠNG DỰ ÁN UNICHECK
**Mã kiểm toán:** AUDIT-2026-Q4-FULL  
**Ngày thực hiện:** 15/10/2026  
**Vai trò thực hiện:** Senior Full-Stack Architect, AI Engineer & QA Lead  
**Phạm vi:** Toàn bộ repository (`frontend/`, `backend/`, `mobile/`, `ai-service/`, `docs/`, `docker-compose.yml`)

---

## 1. TỔNG QUAN HỆ THỐNG & TỶ LỆ HOÀN THIỆN THỰC TẾ

UniCheck là hệ thống điểm danh tự giác kết hợp nhận diện sinh trắc học khuôn mặt (AI FaceID), mã QR động xoay vòng và kiểm định vị trí kết nối mạng (Wi-Fi BSSID / GPS Geofencing) dành cho cơ sở giáo dục đại học.

Dựa trên đối chiếu giữa **Báo cáo Thiết kế Phần mềm (SDD 21 module)** tại [`docs/UniCheck_Software_Design_Document.md`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/docs/UniCheck_Software_Design_Document.md) và mã nguồn thực tế:
* **Tỷ lệ hoàn thành tổng thể:** ~**22%** (chủ yếu tập trung ở khung hạ tầng, cơ chế xác thực đa nền tảng và quản lý tài khoản cơ bản).
* **Trạng thái phân hệ:**
  * **Web Frontend (`frontend/`):** **PARTIAL** (Đã hoàn thiện Module Authentication với 6 màn hình Stitch, Atomic UI Design System Academic Precision; toàn bộ các phân hệ nghiệp vụ Quản trị, Giảng viên, Sinh viên, Điểm danh vẫn ở trạng thái Mock/Chưa bắt đầu).
  * **Backend Core (`backend/`):** **PARTIAL** (Spring Boot 3.3.4, Java 21/22, JPA, Flyway, Redis. Đã xong Controller/Service cho Auth & User CRUD. Tuy nhiên, 40/50 bảng CSDL chưa có JPA Entity và Service xử lý nghiệp vụ).
  * **AI Microservice (`ai-service/`):** **MOCK_ONLY** (Flask server chỉ trả về vector 128 số 0 `[0.0] * 128` và điểm liveness cố định `0.96`. Chưa tải mô hình FaceNet/InsightFace thực tế).
  * **Mobile App (`mobile/`):** **PARTIAL** (Flutter/Dart với GetX & Dio. Đã hoàn thiện xác thực API thật, lưu token an toàn và Route Guards. Tuy nhiên, màn hình điểm danh camera chỉ là placeholder giao diện tĩnh; chưa tích hợp plugin camera thực tế, ML Kit Face Detection, QR Scanner hay Wi-Fi BSSID).
  * **Hạ tầng (`docker-compose.yml`):** **PARTIAL** (Cấu hình Docker Compose hợp lệ nhưng Docker Desktop daemon trên máy host đang tắt; fallback JWT secret bị gán cứng trong file cấu hình).

---

## 2. XÁC MINH CÔNG NGHỆ VÀ PHIÊN BẢN (EMPIRICAL VERIFICATION)

| Phân hệ / Công cụ | Phiên bản theo tài liệu | Phiên bản thực tế xác minh qua CLI/Config | Trạng thái xác minh |
| :--- | :--- | :--- | :---: |
| **Hệ điều hành Host** | Windows 11 Enterprise | Windows 11 Enterprise (amd64, build 10.0) | `VERIFIED` |
| **Java Development Kit** | Java 21 LTS | Java 22.0.2 (Oracle JDK-22) | `VERIFIED` |
| **Apache Maven** | Maven 3.9+ | Apache Maven 3.9.11 | `VERIFIED` |
| **Spring Boot Backend** | 3.3.4 | Spring Boot 3.3.4 (`pom.xml:L9`) | `VERIFIED` |
| **Node.js** | Node 18+ | Node.js v24.16.0 (Hỗ trợ native strip-types) | `VERIFIED` |
| **React Web** | React 18 | React 18.3.1, TypeScript 5.6.2, Vite 5.4.21 (`package.json`) | `VERIFIED` |
| **Tailwind CSS** | Tailwind 3 | Tailwind CSS 3.4.13 (`package.json`) | `VERIFIED` |
| **Flutter SDK** | Flutter 3.x | Flutter 3.47.3 (channel stable, Dart 3.13.3) | `VERIFIED` |
| **Python AI Engine** | Python 3.11 | Chưa cài đặt trên Windows host (Chạy container hóa) | `DOCKER_DEPENDENT` |
| **PostgreSQL** | PostgreSQL 15 | postgres:15-alpine (`docker-compose.yml`) | `CONFIGURED` |
| **Redis In-Memory** | Redis 7 | redis:7-alpine (`docker-compose.yml`) | `CONFIGURED` |
| **Flyway Migration** | 10.x | Flyway Core 10.18.0 (3 migration scripts: V1, V2, V3) | `VERIFIED` |

---

## 3. TÌNH TRẠNG CHI TIẾT TỪNG PHÂN HỆ

### 3.1. Web Frontend (`frontend/`)
* **Kiến trúc:** React 18 SPA với Vite 5, Tailwind CSS 3, Zustand 5, Axios Interceptor, React Router v6.
* **Design System:** Tuân thủ chuẩn *Academic Precision* trích xuất từ Google Stitch Project `3214444012266330806`.
* **Atomic Components (`frontend/src/common-ui/`):** 16 components hoàn chỉnh: `Button`, `Input`, `Select`, `Badge`, `StatCard`, `DataTable`, `Modal`, `Pagination`, `LoadingSpinner`, `Skeleton`, `EmptyState`, `ErrorState`, `Alert`, `SearchInput`, `FilterBar`.
* **Giao diện Stitch đã tích hợp (DONE):**
  * Đăng nhập (`41e9fae8d8d44fac8260cc17252be377`) -> [`LoginPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/auth/LoginPage.tsx)
  * Quên mật khẩu (`bdeeb9ad8e6e48eb830753c46c0718eb`) -> [`ForgotPasswordPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/auth/ForgotPasswordPage.tsx)
  * Xác thực OTP (`a82fccdfa56d4efa8dec59a3a636a0ff`) -> [`VerifyOtpPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/auth/VerifyOtpPage.tsx)
  * Đổi mật khẩu (`a982502abde84a82927fbde7620c59c5`) -> [`ChangePasswordPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/auth/ChangePasswordPage.tsx)
  * Thông tin cá nhân (`1c85a287b68c437e8e7fe5f9f829bc16`) -> [`ProfilePage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/profile/ProfilePage.tsx)
  * Đặt lại mật khẩu (Reset Password DTO) -> [`ResetPasswordPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/auth/ResetPasswordPage.tsx)
* **Giao diện Mock:**
  * Bảng điều khiển (`3b9a0eb0bbfe4fcb86c092384f9b2220`) -> [`DashboardPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/dashboard/DashboardPage.tsx) (Dữ liệu tĩnh hardcoded, chưa gọi API nghiệp vụ lớp học phần hay điểm danh).
* **Giao diện chưa triển khai:** 33 màn hình Stitch nghiệp vụ còn lại (Quản lý người dùng, sinh viên, giảng viên, lớp học phần, phòng học/wifi, phiên điểm danh, báo cáo chuyên cần...).

### 3.2. Backend Core (`backend/`)
* **Controllers hiện có (2 controllers):**
  * [`AuthController.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/controller/AuthController.java): 11 endpoints hoàn chỉnh (login, logout, refresh-token, me/profile, change-password, forgot-password, reset-password, 3 test role endpoints).
  * [`UserController.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/controller/UserController.java): 7 endpoints (create, get detail, update, delete, list paged, active, inactive).
* **Controllers chưa có:** Thiếu hoàn toàn controller cho các phân hệ: `AttendanceSessionController`, `StudentAttendanceController`, `ClassSectionController`, `CourseController`, `SemesterController`, `RoomController`, `WifiAccessPointController`, `AcademicRequestController`, `ReportController`, `AuditLogController`.
* **Cơ sở dữ liệu (Flyway vs JPA):**
  * Flyway có 3 file di chuyển tổng cộng 50 bảng.
  * Chỉ có 10 JPA Entities: `User`, `StudentProfile`, `LecturerProfile`, `UserSession`, `UserPermission`, `UserDeviceToken`, `AccessLog`, `SystemLog`, `FaceEncoding`, `LecturerGradeOtp`.
  * 40 bảng còn lại (học phần, lớp học, điểm danh, bài tập, chat, thông báo...) chưa có Entity tương ứng trong mã nguồn Java.

### 3.3. AI Microservice (`ai-service/`)
* **Endpoint:**
  * `GET /health`: Hoạt động (`status: "UP"`).
  * `POST /api/v1/face/extract-embedding`: Giả lập dữ liệu trả về `embedding: [0.0] * 128`, `confidence: 0.98`.
  * `POST /api/v1/face/check-liveness`: Giả lập dữ liệu trả về `is_live: true`, `liveness_score: 0.96`.
* **Mô hình AI:** Chưa tích hợp OpenCV Haar/DNN, MediaPipe, dlib hay FaceNet; chưa có logic phát hiện nhiều khuôn mặt hoặc góc quay mặt.

### 3.4. Mobile Client (`mobile/`)
* **Framework:** Flutter 3.47.3, GetX, Dio, Flutter Secure Storage.
* **Tính năng hoàn thành:** Form đăng nhập gọi API thật, Single-flight refresh token mutex khi gặp 401, Route Guards theo vai trò (`AdminShellView`, `LecturerShellView`, `StudentShellView`).
* **Tính năng Mock/Chưa bắt đầu:**
  * Màn hình điểm danh [`face_checkin_view.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/attendance/views/face_checkin_view.dart) chỉ là placeholder giao diện tĩnh; nút bấm hiển thị thông báo "Tính năng camera sinh trắc học đang được đồng bộ với AI Service".
  * `pubspec.yaml` chưa khai báo thư viện xử lý ML Kit Face Detection, quét mã QR, hay lấy BSSID Wi-Fi phòng học.

---

## 4. BẰNG CHỨNG THỰC THI KIỂM THỬ AN TOÀN (TEST EXECUTION EVIDENCE)

### 4.1. Kiểm thử Backend (`mvn test`)
* **Kết quả:** `Tests run: 44, Failures: 0, Errors: 0, Skipped: 0` (Thời gian: 20.217s).
* **Bao phủ:**
  * `AuthenticationIntegrationTest`: 10 tests (đăng nhập, sai mật khẩu, tài khoản khóa, rate limit, logout, refresh token).
  * `RouteAliasCompatibilityContractTest`: Đảm bảo đồng nhất giữa route canonical `/api/v1/...` và route tương thích ngược `/api/...`.
  * `UserManagementIntegrationTest`: Tạo người dùng, cập nhật, phân trang, lọc vai trò.
  * `SecuritySanitizationTest`: Đảm bảo không in mật khẩu, JWT token hoặc OTP ra log máy chủ.
  * `PostgresCleanDatabaseStartupTest`: Kiểm tra khả năng tương thích của migration Flyway.

### 4.2. Kiểm thử Web Frontend (`npm test` & `npm run build`)
* **Kết quả Unit Test:** `tests: 10, pass: 10, fail: 0` (Node 24 native test runner).
* **Bao phủ:** Hợp đồng DTO phẳng, lưu trữ token, xoay vòng RTR, dọn dẹp logout, regex email, độ mạnh mật khẩu, ràng buộc 6 số OTP, cờ bắt buộc đổi mật khẩu, không chỉnh sửa role/permissions từ profile, ánh xạ ErrorCode tiếng Việt.
* **Kết quả Build Bundle:** `npm run build` hoàn thành trong 8.34s, tạo bundle production 391kB, 0 lỗi TypeScript.

### 4.3. Kiểm thử Mobile Client (`flutter analyze` & `flutter test`)
* **Phân tích tĩnh:** `flutter analyze` báo cáo `No issues found! (ran in 32.7s)`.
* **Kết quả Widget & Unit Test:** `flutter test` chạy đạt **24/24 tests** (ApiClient error mapping, AuthController login/logout/restore session, Route Guards, TokenStorage platform adapter, Widget tests cho các mã lỗi 401/403).

### 4.4. Kiểm tra cấu hình Docker Compose (`docker compose config`)
* **Kết quả:** Tệp cấu hình [`docker-compose.yml`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/docker-compose.yml) hợp lệ cú pháp 100%.
* **Ghi chú môi trường:** Docker daemon Linux engine trên máy phát triển đang tạm thời tắt; cổng TCP 8080 và 5432 hiện không có tiến trình lắng nghe.

---

## 5. CÁC RỦI RO KỸ THUẬT & LỖ HỔNG PHÁT HIỆN ĐƯỢC

1. **Rủi ro phân mảnh kiến trúc (Architectural Divergence):**
   * Tài liệu `docs/evidence/flutter_web_auth_verification.md` ghi nhận Flutter từng được biên dịch cho cả Web (`build/web`), trong khi tài liệu yêu cầu người dùng và các giai đoạn gần nhất yêu cầu phát triển cổng Web bằng React 18 + Vite + Stitch Design System. Cần thống nhất dứt khoát: **React Web** đảm nhiệm Cổng Quản trị & Đào tạo trên Desktop; **Flutter Mobile** đảm nhiệm Ứng dụng Di động cho Sinh viên & Giảng viên.
2. **Khoảng cách CSDL (JPA Entity Gap):**
   * Đang có độ lệch lớn giữa Schema 50 bảng của Flyway và 10 JPA Entities hiện có. Cần bổ sung các thực thể JPA cốt lõi (`ClassSection`, `AttendanceSession`, `StudentAttendance`, `Course`, `Room`) trước khi có thể triển khai nghiệp vụ điểm danh.
3. **AI Service chưa có lõi xử lý thật:**
   * Việc `ai-service` trả dữ liệu giả lập cản trở kiểm thử tích hợp nhận diện khuôn mặt thật từ client.
4. **Hardcoded Secrets trong Docker Configuration:**
   * Tệp `docker-compose.yml` có gán cứng fallback JWT secret `4c9a58b29f7e1b3d5c7a9e0f2b4d6e8a0c2e4f6a8b0d2e4f6a8b0d2e4f6a8b0d`. Cần đưa vào file `.env` bảo mật khi đưa lên môi trường Staging/Production.
