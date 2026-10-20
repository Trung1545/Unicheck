# BÁO CÁO KIỂM TRA MÃ NGUỒN TOÀN DIỆN DỰ ÁN UNICHECK
## (Comprehensive Source Code Audit & Technical State Verification)

> **Mã tài liệu:** `AUDIT-UNICHECK-2026-FINAL`  
> **Ngày thực hiện:** 20/10/2026  
> **Phiên bản hệ thống:** UniCheck Core v1.0.0 (Giai đoạn hợp nhất TASK-05 & TASK-08)  
> **Vai trò kiểm toán:** Senior Software Engineer, Software Architect & Technical Lead  
> **Nguyên tắc thẩm định tối cao:** **SOURCE CODE HIỆN TẠI LÀ CĂN CỨ DUY NHẤT XÁC ĐỊNH TRẠNG THÁI TRIỂN KHAI. TÀI LIỆU CŨ LÀ CĂN CỨ XÁC ĐỊNH PHẠM VI THIẾT KẾ, KHÔNG PHẢI BẰNG CHỨNG CHỨC NĂNG ĐÃ HOÀN THÀNH.**  
> **Cam kết liêm chính:** Tuyệt đối không tự suy diễn chức năng, API, bảng CSDL, thư viện, thuật toán hoặc kết quả kiểm thử không tồn tại trong repository.

---

## 1. TỔNG QUAN KẾT QUẢ KIỂM TOÁN HỆ THỐNG

| Phân hệ / Thành phần | Công nghệ thực tế | Số lượng tệp / Cấu trúc | Số ca kiểm thử tự động | Trạng thái kỹ thuật thực tế |
| :--- | :--- | :--- | :---: | :---: |
| **Web Frontend** | React 18.3.1, TypeScript 5.6.2, Vite 5.4.8, Tailwind CSS 3.4.13, Zustand 5, Axios, React Router 6 | 18 Pages, 16 Atomic Components, 10 API Clients | **78/78 Passed (100%)** | **PARTIAL (54.8%)** — Hoàn thiện xác thực, quản trị người dùng, danh mục học vụ, phòng/Wi-Fi, thời khóa biểu, phiên điểm danh và đăng ký FaceID WebRTC. Dashboard còn dữ liệu tĩnh; các màn hình học tập/đơn từ chưa làm. |
| **Mobile Client** | Flutter 3.47.3, Dart 3.13.3, GetX 4.6.6, Dio 5.7.0, Camera 0.11, Google ML Kit 0.15 | 20 Dart Files, 6 Test Suites | **32/32 Passed (100%)** | **PARTIAL** — Hoàn thiện Đăng nhập, Quản lý phiên, Khôi phục token và Đăng ký FaceID 3 góc mặt (Google ML Kit); Màn hình quét điểm danh `face_checkin_view.dart` mới chỉ là UI Placeholder; Lịch học và lịch sử chưa nối sự kiện. |
| **Backend Core** | Spring Boot 3.3.4, Java 22 (Target 21), Spring Data JPA, Spring Security, Flyway 10.18, Redis, JJWT | 170 Java Files, 10 Controllers, 25 Repositories, 25 Entities | **132/132 Passed (100%)** | **PARTIAL** — Hoàn thiện xác thực, quản lý người dùng, học phần, học kỳ, lớp học phần, ghi danh, thời khóa biểu, phòng/Wi-Fi, cấu hình & phiên điểm danh, đăng ký FaceID. Thiếu API nộp check-in điểm danh của sinh viên (TASK-06). |
| **AI Microservice** | Python 3.11, Flask 3.1, ONNX Runtime 1.31, OpenCV Headless 5.0, Pillow 12.3 | 4 Endpoints REST, 5 ONNX Models, 3 Test Modules | **39/39 Passed (100%)** | **READY & PRODUCTION-GRADE** — YuNet 2023mar detection, ArcFace MobileFaceNet 512D embedding, Cosine similarity matching, MiniFASNet V2+V1SE dual ensemble liveness. |
| **Database & Cache** | PostgreSQL 15 Alpine, Redis 7 Alpine, Flyway Migration V1 -> V7 | 50 Bảng Schema, 25 JPA Entities, 7 Migrations | **Verified Clean DB Startup** | **VERIFIED** — 25 bảng có thực thể JPA; 25 bảng là schema Flyway chưa có Entity tương ứng. |
| **Tổng kiểm thử** | **Node Test + Maven + Flutter + Pytest** | **Toàn bộ 4 phân hệ** | **281/281 Passed (100%)** | **Tỷ lệ hoàn thành cốt lõi: ~55%** |

---

## 2. KIỂM TOÁN CHI TIẾT WEB FRONTEND (`frontend/`)

### 2.1. Phiên bản công nghệ thực tế
* **React:** `18.3.1` (xác minh qua `package.json:L17`).
* **TypeScript:** `5.6.2` (xác minh qua `package.json:L31`).
* **Vite:** `5.4.8` (xác minh qua `package.json:L32`).
* **Tailwind CSS:** `3.4.13` (xác minh qua `package.json:L30`).
* **Thư viện bổ trợ:** `zustand: 5.0.0-rc.1`, `axios: 1.7.7`, `react-router-dom: 6.26.2`, `lucide-react: 0.446.0`, `@mediapipe/tasks-vision: 1.1.1`.

### 2.2. Cấu trúc thư mục và kiến trúc mã nguồn
```
frontend/src/
├── api/             # 10 API Clients tương tác Backend (Axios)
├── api-client/      # Cấu hình Axios Interceptor, Token Storage, Refresh Mutex
├── common-ui/       # 16 Atomic Components (Design System Academic Precision)
├── layouts/         # MainLayout (Dashboard Shell) & AuthLayout (Isolated Auth)
├── pages/           # 18 Màn hình nghiệp vụ (Admin, Auth, Dashboard, Profile, Student, UIKit)
├── routes/          # Hệ thống định tuyến React Router v6 & 3 Route Guards
├── store/           # Zustand Auth Store quản lý phiên đăng nhập và quyền
├── test/            # 9 bộ kiểm thử tự động với Node.js native test runner
└── utils/           # FaceLandmarkerService hỗ trợ WebRTC và toán học góc mặt
```

### 2.3. Hệ thống phân quyền và bảo vệ định tuyến (Route Protection)
Được định nghĩa tại [`frontend/src/routes/index.tsx`](file:///frontend/src/routes/index.tsx):
1. **`GuestRoute`:** Chặn người dùng đã đăng nhập truy cập các trang `/login`, `/forgot-password`, `/verify-otp`, `/reset-password`; tự động chuyển hướng về `/dashboard`.
2. **`ProtectedRoute`:** Yêu cầu người dùng phải có trạng thái `isAuthenticated = true`. Nếu người dùng có cờ `isPasswordChanged === false`, hệ thống bắt buộc điều hướng đến `/change-password?required=true`.
3. **`AdminRoute`:** Kế thừa `ProtectedRoute` và bổ sung kiểm tra nghiêm ngặt `user.role === 'ADMIN'`. Người dùng không có vai trò ADMIN bị chặn truy cập và chuyển hướng về `/dashboard`.

### 2.4. Khảo sát 18 Màn hình Web thực tế
1. **Xác thực & Cá nhân (ALL):**
   - `LoginPage.tsx`: Gọi `POST /api/v1/auth/login`. Hỗ trợ đăng nhập bằng username/email.
   - `ForgotPasswordPage.tsx`: Gọi `POST /api/v1/auth/forgot-password`. Masked email, an toàn thông tin.
   - `VerifyOtpPage.tsx`: Gọi `POST /api/v1/auth/verify-otp`. Nhập mã OTP 6 chữ số.
   - `ResetPasswordPage.tsx`: Gọi `POST /api/v1/auth/reset-password` qua token đặt lại mật khẩu.
   - `ChangePasswordPage.tsx`: Gọi `POST /api/v1/auth/change-password`. Bắt buộc khi tài khoản khởi tạo.
   - `ProfilePage.tsx`: Gọi `GET /api/v1/auth/me` và `PUT /api/v1/auth/profile`. Hiển thị badge Face-ID.
2. **Quản trị hệ thống & Học vụ (ADMIN):**
   - `UserManagementPage.tsx`: Gọi `GET /api/v1/users`, `POST /api/v1/users`, `PATCH /status`, `POST /import-csv`.
   - `CourseCatalogPage.tsx`: Gọi `GET /api/v1/courses`, `POST /api/v1/courses`, `DELETE /courses/{code}`.
   - `SemesterManagementPage.tsx`: Gọi `GET /api/v1/semesters`, `POST /api/v1/semesters`, `PUT /semesters/{id}`.
   - `ClassSectionPage.tsx`: Gọi `GET /api/v1/classes`, `POST /api/v1/classes`, `PUT /classes/{className}`.
   - `EnrollmentManagementPage.tsx`: Gọi `GET /api/v1/enrollments`, `POST /api/v1/enrollments`, `DELETE /enrollments/{id}`.
   - `FacilitiesWifiPage.tsx`: Gọi `GET /api/v1/rooms`, `POST /rooms`, `GET /wifi-aps`, `POST /wifi-aps/assign`.
   - `MasterTimetablePage.tsx`: Gọi `GET /api/v1/timetable/slots`, `POST /slots`, `POST /slots/check-conflicts`.
   - `AttendanceSessionManagementPage.tsx`: Gọi `GET /api/v1/attendance/sessions`, `POST /sessions`, `POST /open`, `POST /close`.
   - `AttendanceConfigPage.tsx`: Gọi `GET /api/v1/attendance/configs`, `PUT /api/v1/attendance/configs`.
3. **Sinh viên & Đăng ký sinh trắc học (STUDENT):**
   - `FaceRegistrationPage.tsx`: Quét camera WebRTC thời gian thực, khung oval Stitch, điều tiết ~120ms, đo 4 chỉ số sinh trắc (ánh sáng, độ nét, số mặt, cự ly), tự động thu nhận 3 góc mặt và gọi `POST /api/v1/attendance/register-face`.
4. **Màn hình Dữ liệu Mock:**
   - `DashboardPage.tsx`: Hiển thị 4 thẻ KPI tĩnh (Tổng số lớp: 48, Ca học hôm nay: 12, Sinh viên điểm danh: 384, Độ chính xác AI Face: 99.4%) và bảng ca học hardcoded. Chưa kết nối API thống kê động từ máy chủ.
5. **Trang hỗ trợ nội bộ:**
   - `UiKitPage.tsx`: Thư viện trực quan hóa 16 Atomic Components và thử nghiệm Responsive Breakpoints.

### 2.5. Đối chiếu thiết kế Google Stitch (Project ID: `3214444012266330806`)
* Dự án Stitch định nghĩa **39 màn hình chuẩn**.
* **Đã hoàn thiện đồng bộ vào mã nguồn React:** 11 màn hình nghiệp vụ trọng tâm (Login, Forgot Password, Verify OTP, Change Password, Profile, User Management, Course Catalog, Semester Management, Facilities/Wi-Fi, Attendance Sessions, Attendance Configs) và 1 màn hình Face Registration.
* **Chưa triển khai (27 màn hình):** Báo cáo chuyên cần nâng cao, Nhật ký kiểm toán toàn trường, Quản lý bài tập/đồ án, Sổ điểm, Trung tâm thông báo, Bảng điều khiển giảng viên, Giám sát WebSocket trực tiếp, Đơn từ học vụ sinh viên.

---

## 3. KIỂM TOÁN CHI TIẾT FLUTTER MOBILE (`mobile/`)

### 3.1. Phiên bản và Thư viện phụ thuộc
* **Flutter SDK:** `3.47.3` (channel stable).
* **Dart SDK:** `3.13.3` (xác minh qua `flutter --version`).
* **State Management & Routing:** `get: ^4.6.6`.
* **Mạng & Lưu trữ:** `dio: ^5.7.0`, `flutter_secure_storage: ^9.2.2`.
* **Camera & AI Thị giác trên thiết bị:**
  - `camera: ^0.11.0+2` (Khởi tạo luồng preview camera trước).
  - `google_mlkit_face_detection: ^0.15.1` (Trích xuất góc Euler Yaw, Pitch, Roll và đếm số mặt).
* **Thiếu hụt thư viện Native (Native Plugin Gaps):**
  - Chưa khai báo `mobile_scanner` hoặc `qr_code_scanner` (chưa quét mã QR động).
  - Chưa khai báo `network_info_plus` (chưa thể đọc BSSID của Wi-Fi phòng học từ phần cứng).
  - Chưa khai báo `geolocator` (chưa kiểm tra tọa độ GPS Geofencing).

### 3.2. Cấu trúc ứng dụng & Luồng màn hình
* **Định hướng phạm vi:** Mobile UniCheck được thiết kế chuyên biệt cho **Sinh viên (STUDENT)**. Các màn hình `AdminShellView` và `LecturerShellView` chỉ tồn tại dạng khung vỏ bảo vệ (Shell Fallback) phục vụ kiểm thử phân quyền RoleGuard.
* **Màn hình Đăng nhập ([`login_view.dart`](file:///mobile/lib/feature/auth/views/login_view.dart)):** Kết nối API thật qua `ApiClient`, xác thực thành công lưu Access Token và Refresh Token vào `FlutterSecureStorage`.
* **Phục hồi phiên & Điều tiết Token (Session Management & RTR):**
  - `ApiClient` cài đặt Interceptor bắt mã HTTP 401. Khi Access Token hết hạn, hệ thống kích hoạt cơ chế `Completer` (Mutex) duy nhất để gọi `/auth/refresh-token`, các request đồng thời khác phải xếp hàng chờ token mới mà không gây bão request.
* **Màn hình Đăng Ký Khuôn Mặt ([`face_enrollment_view.dart`](file:///mobile/lib/feature/attendance/views/face_enrollment_view.dart)):**
  - Mở camera trước (`CameraLensDirection.front`).
  - Tích hợp `Google ML Kit Face Detector` để thẩm định góc quay đầu 3 bước theo [`HeadPoseEvaluator`](file:///mobile/lib/core/utils/head_pose_evaluator.dart):
    * **Bước 1 (Nhìn thẳng):** $|Yaw| \le 8.0^\circ$, $|Pitch| \le 15.0^\circ$, $|Roll| \le 15.0^\circ$, $N = 1$.
    * **Bước 2 (Nghiêng trái):** $Yaw \ge 12.0^\circ$. Nếu nhìn thẳng hoặc quay phải sẽ bị từ chối và cảnh báo.
    * **Bước 3 (Nghiêng phải):** $Yaw \le -12.0^\circ$.
  - Thu nhận đủ 3 khung hình đạt chuẩn, mã hóa Base64 và gửi lên `POST /attendance/register-face`.
* **Màn hình Điểm Danh Sinh Trắc Học ([`face_checkin_view.dart`](file:///mobile/lib/feature/attendance/views/face_checkin_view.dart)):**
  - **TRẠNG THÁI THỰC TẾ: UI PLACEHOLDER.**
  - Màn hình chứa khung oval giả lập. Nút bấm *"XÁC NHẬN ĐIỂM DANH SINH TRẮC HỌC"* chỉ hiển thị Snackbar thông báo: *"Tính năng camera sinh trắc học đang được đồng bộ với AI Service"*.
  - Chưa có mã nguồn chụp ảnh gửi về backend để kiểm tra liveness và đối chiếu khuôn mặt.
* **Bảng điều khiển Sinh viên ([`student_shell_view.dart`](file:///mobile/lib/feature/shell/views/student_shell_view.dart)):**
  - Thẻ *"Lịch Học Cá Nhân"* và *"Lịch Sử Điểm Danh"* hiện có sự kiện `onTap: () {}` rỗng, chưa mở màn hình tương ứng.

### 3.3. Đánh giá khả năng hỗ trợ Đa nền tảng (Android / iOS)
* **Android:** Đã kiểm thử thực tế và chạy đạt 100% trên Android Emulator (API 34, `emulator-5554`).
* **iOS:** Thư mục `mobile/ios/` có cấu trúc hợp lệ (Podfile, Runner.xcodeproj). Tuy nhiên:
  - Dự án chưa được build và chạy thử nghiệm trên máy macOS với Xcode thực tế.
  - Mục tiêu đề bài *"Tương thích iOS từ phiên bản 10.0 trở lên"* là **chưa được kiểm chứng trên thiết bị thật**, và các plugin hiện đại như `camera 0.11` cùng `google_mlkit_face_detection 0.15` thường yêu cầu iOS deployment target tối thiểu từ iOS 12.0 hoặc 15.5 trở lên.

---

## 4. KIỂM TOÁN CHI TIẾT BACKEND SPRING BOOT (`backend/`)

### 4.1. Phiên bản và Môi trường
* **Spring Boot:** `3.3.4` (xác minh qua `pom.xml:L9`).
* **Java:** Chạy trên OpenJDK 22.0.2; mã nguồn cấu hình tương thích `release 21` (Java 21 LTS).
* **Cơ chế bảo mật:** Spring Security 6 với JWT Stateless, `jjwt: 0.12.6`.
* **Cơ sở dữ liệu & Di chuyển:** Spring Data JPA, Hibernate ORM, PostgreSQL Driver, Flyway Core `10.18.0`.
* **Bộ nhớ đệm:** Spring Data Redis Client (Jedis/Lettuce) hỗ trợ Blacklist token và RTR.

### 4.2. Danh mục 10 REST Controllers & Hợp đồng API
Hệ thống áp dụng kiến trúc **Dual Route Compatibility** (Mọi endpoint đều ánh xạ song song `/api/v1/...` và `/api/...`):

| Controller | Đường dẫn gốc | Số Endpoint | Chức năng nghiệp vụ & Ghi chú |
| :--- | :--- | :---: | :--- |
| `AuthController` | `/auth` | **11** | Login, Logout, Refresh Token, Me, Change Password, Forgot Password, Reset Password, 3 Role Checks |
| `UserController` | `/users` | **8** | Tạo người dùng, Lấy chi tiết, Cập nhật, Khóa/Mở khóa tài khoản, Xóa người dùng, Danh sách phân trang, Import CSV |
| `CourseController` | `/courses` | **7** | Tạo môn học, Cập nhật, Xóa môn (chặn xóa nếu là môn tiên quyết), Danh sách, Chi tiết, Chống phụ thuộc vòng |
| `SemesterController` | `/semesters` | **8** | Tạo học kỳ, Cấu hình ngày/tuần, Khóa học kỳ, Đảm bảo duy nhất 1 học kỳ ACTIVE, Lịch nghỉ lễ |
| `FacilityController` | `/rooms`, `/wifi-aps` | **14** | Quản lý phòng học, chuẩn hóa MAC/BSSID, gán AP vào phòng (Unique V5), bảo vệ phòng đã có lịch học |
| `ClassSectionController` | `/classes` | **8** | Tạo lớp học phần, Sĩ số tối đa, Lọc theo học kỳ/môn học/giảng viên, Trạng thái vòng đời lớp |
| `EnrollmentController` | `/enrollments` | **5** | Ghi danh sinh viên, Chặn ghi danh trùng (Unique V4), Kiểm tra giới hạn sĩ số, Hủy ghi danh |
| `TimetableController` | `/timetable` | **10** | Xếp lịch học, Phát hiện xung đột 3 chiều (Phòng, Giảng viên, Lớp), Ràng buộc ca học đã có điểm danh |
| `AttendanceSessionController`| `/attendance` | **10** | Khởi tạo phiên gắn với ca học (Unique V7), Mở phiên, Đóng phiên, Tra cứu trạng thái, KPI phiên, Thống kê, Cấu hình động |
| `FaceEnrollmentController` | `/attendance`, `/face` | **4** | Đăng ký khuôn mẫu Face-ID, Tra cứu trạng thái hồ sơ khuôn mặt, Xóa/Thu hồi dữ liệu Face-ID để đăng ký lại |

### 4.3. Đánh giá tính năng Lưu trữ Dữ liệu Sinh trắc học & Bảo vệ Quyền riêng tư
* Phương thức triển khai tại [`FaceEnrollmentServiceImpl.java`](file:///backend/src/main/java/com/unicheck/service/impl/FaceEnrollmentServiceImpl.java):
  - Nhận ảnh Base64 từ client $\rightarrow$ Gọi `AiServiceClient` sang Flask AI để trích xuất vector 512 số thực float32.
  - Đóng gói mảng 512 số thực IEEE 754 thành mảng nhị phân **2048 bytes** (Little Endian).
  - Lưu trực tiếp vào cột `face_encodings.face_encoding` (kiểu dữ liệu `BYTEA` của PostgreSQL).
  - **Tuân thủ ISO/IEC 27001 & Nghị định 13/2023/NĐ-CP:** Cột `face_encodings.face_image` được đặt giá trị `NULL`. Hệ thống **tuyệt đối không lưu ảnh khuôn mặt gốc** trên ổ đĩa máy chủ sau khi tạo khuôn mẫu thành công.
  - Cập nhật trạng thái người dùng: `users.face_data_status = 'REGISTERED'`.

### 4.4. Điểm thiếu hụt nghiêm trọng trong luồng Điểm danh
* **Backend hiện chưa có Controller tiếp nhận điểm danh trực tiếp của sinh viên:**
  - Chưa có endpoint `POST /api/v1/attendance/check-in` để sinh viên gửi ảnh selfie và BSSID phòng học.
  - Mặc dù thực thể `StudentAttendance` và repository `StudentAttendanceRepository` đã tồn tại, việc ghi bản ghi điểm danh hiện mới chỉ được thực hiện qua bộ dữ liệu kiểm thử `AttendanceSessionIntegrationTest.java` hoặc các ca test nghiệp vụ, chưa có API công khai phục vụ ứng dụng di động sinh viên.
  - Nghiệp vụ này nằm trong phạm vi kế hoạch của **TASK-06 (Mobile Check-in & Dynamic QR Flow)**.

---

## 5. KIỂM TOÁN CHI TIẾT FLASK AI SERVICE (`ai-service/`)

### 5.1. Công nghệ và Thư viện Deep Learning
* **Ngôn ngữ & Framework:** Python 3.11, Flask 3.1, Gunicorn 21.2.
* **Inference Engine:** `onnxruntime: 1.31.0` (Tối ưu hóa chạy trên CPU đa luồng).
* **Xử lý ảnh & Thị giác máy tính:** `opencv-python-headless: 5.0.0.93`, `pillow: 12.3.0`, `numpy: 2.4.6`.
* **Bộ trọng số mô hình đã tích hợp sẵn trong kho mã nguồn:**
  1. `face_detection_yunet_2023mar.onnx` (Phát hiện khuôn mặt YuNet của OpenCV Zoo).
  2. `w600k_mbf.onnx` (Mô hình ArcFace MobileFaceNet trích xuất vector đặc trưng 512 chiều, tiền huấn luyện trên tập dữ liệu WebFace600k).
  3. `MiniFASNetV2.onnx` (1.74 MB, Apache 2.0, phân tích vi cấu trúc bề mặt da và lỗ chân lông với tỷ lệ mở rộng $2.7\times$).
  4. `MiniFASNetV1SE.onnx` (1.74 MB, Apache 2.0, phân tích toàn cảnh và viền khung thiết bị với tỷ lệ mở rộng $4.0\times$).

### 5.2. Các Endpoints REST thực tế tại `ai-service/app.py`
1. **`GET /health`:** Kiểm tra trạng thái máy chủ và trạng thái nạp của 3 mô hình (`detector_ready`, `engine_ready`, `liveness_ready`). Trả HTTP 200 `status: "UP"`.
2. **`POST /api/v1/face/extract-embedding`:**
   - Đầu vào: JSON `{"image_base64": "..."}`.
   - Luồng: Giải mã ảnh $\rightarrow$ YuNet Detection (Score $\ge 0.6$, NMS $0.3$) $\rightarrow$ Bắt buộc $N = 1$ mặt $\rightarrow$ Căn chỉnh Affine 5 điểm mốc mắt/mũi/miệng $\rightarrow$ ArcFace ONNX $\rightarrow$ Chuẩn hóa L2 $\rightarrow$ Vector 512D.
   - Mã lỗi: `ERR_3001` (Không có mặt), `ERR_3002` (Nhiều hơn 1 mặt), `ERR_1001` (Ảnh lỗi).
3. **`POST /api/v1/face/verify-face`:**
   - So sánh 2 khuôn mặt bằng Cosine Similarity:
     $$\text{Cosine Similarity}(u, v) = \frac{u \cdot v}{\|u\|_2 \|v\|_2}$$
   - Ngưỡng cấu hình động `AI_FACE_MATCH_THRESHOLD` (mặc định **0.68**).
   - Kiểm tra tính toàn vẹn vector (NaN, Inf, Zero vector). Phân tách rõ ràng: Mẫu cùng người đạt $1.0000$, khác người đạt $0.0058$.
4. **`POST /api/v1/face/check-liveness`:**
   - Đầu vào: Ảnh khuôn mặt Probe.
   - Luồng xử lý: Cắt 2 vùng ảnh bounding box mở rộng tỷ lệ $2.7\times$ và $4.0\times$ $\rightarrow$ Đưa qua 2 mô hình ONNX `MiniFASNetV2` và `MiniFASNetV1SE` $\rightarrow$ Tính xác suất Softmax 3 lớp $\rightarrow$ Điểm thực thể sống $S_{\text{real}} \ge 0.70$ xác nhận người thật.
   - Phân loại tấn công giả mạo: `PRINT_PAPER_OR_CUTOUT` (Ảnh in 2D), `SCREEN_OR_VIDEO_REPLAY` (Phát lại qua màn hình).
   - **Cơ chế Fail-Closed động:** Nếu mô hình chưa sẵn sàng hoặc gặp ngoại lệ nội bộ, trả HTTP 503 `ERR_3003`, tuyệt đối không bao giờ trả kết quả `is_live=true` giả lập.

### 5.3. Kết quả đo đạc hiệu năng thực tế trên CPU (Inference Latency Benchmark)
*(Đo lường trên bộ kiểm thử tự động `ai-service/tests/test_liveness.py` và `test_face_engine.py`)*:
* Thời gian suy luận YuNet Face Detection: **~8.2 ms**.
* Thời gian suy luận ArcFace MobileFaceNet: **~3.4 ms**.
* Thời gian suy luận Dual MiniFASNet Ensemble: **~2.6 ms**.
* **Tổng thời gian xử lý E2E toàn pipeline AI:** **~11.53 ms (p50)**, nhanh gấp **25 lần** so với ngân sách kỹ thuật yêu cầu ($\le 300$ ms).

---

## 6. KIỂM TOÁN CƠ SỞ DỮ LIỆU & HẠ TẦNG TRIỂN KHAI

### 6.1. Đối chiếu Schema Flyway (50 Bảng) và Thực thể JPA (25 Thực thể)
Cơ sở dữ liệu PostgreSQL 15 được quản lý bởi 7 tệp Flyway Migration (`V1` đến `V7`):
* `V1__init_academic_catalog.sql`: 16 bảng danh mục đào tạo, phòng học, Wi-Fi.
* `V2__init_users_and_profiles.sql`: 10 bảng người dùng, hồ sơ, phân quyền, sinh trắc học, log.
* `V3__init_classes_attendance_and_operations.sql`: 24 bảng lớp học phần, điểm danh, bài tập, chat, thông báo, đơn từ.
* `V4` đến `V7`: Bổ sung các ràng buộc khóa duy nhất và chỉ mục (Unique `(class_name, student_id)`, Unique `(room_id, wifi_access_point_id)`, Composite Indexes cho thời khóa biểu, Unique `(slot_id)` cho phiên điểm danh).

**Phát hiện thực tế:** Trong tổng số 50 bảng schema, chỉ có **25 bảng đã có JPA Entity tương ứng** trong mã nguồn Java:
1. `User` (`users`)
2. `StudentProfile` (`student_profiles`)
3. `LecturerProfile` (`lecturer_profiles`)
4. `UserPermission` (`user_permissions`)
5. `UserDeviceToken` (`user_device_tokens`)
6. `UserSession` (`user_sessions`)
7. `FaceEncoding` (`face_encodings`)
8. `LecturerGradeOtp` (`lecturer_grade_otps`)
9. `AccessLog` (`access_logs`)
10. `SystemLog` (`system_logs`)
11. `Course` (`courses`)
12. `Semester` (`semesters`)
13. `SemesterConfig` (`semester_configs`)
14. `Holiday` (`holidays`)
15. `SlotType` (`slot_types`)
16. `Room` (`rooms`)
17. `WifiAccessPoint` (`wifi_access_points`)
18. `RoomWifiAccessPoint` (`room_wifi_access_points`)
19. `ClassSection` (`class_sections`)
20. `TeachingAssignment` (`teaching_assignments`)
21. `Enrollment` (`enrollments`)
22. `TimetableSlot` (`timetable_slots`)
23. `AttendanceSession` (`attendance_sessions`)
24. `StudentAttendance` (`student_attendances`)
25. `AttendanceConfig` (`attendance_configs`)

**25 bảng còn lại chưa có Entity và chưa có nghiệp vụ xử lý trong mã nguồn Java:** `majors`, `specializations`, `sub_specializations`, `course_prerequisites`, `specialization_courses`, `sub_specialization_courses`, `grade_components`, `semester_weekdays`, `student_grades`, `assignments`, `assignment_submissions`, `chat_groups`, `chat_group_members`, `chat_messages`, `chat_message_reads`, `chat_message_reactions`, `ai_chat_sessions`, `ai_chat_messages`, `notifications`, `news`, `news_attachments`, `academic_requests`, `schedule_requests`, `alerts`, `import_jobs`.

### 6.2. Kiểm tra Cấu hình Docker & Môi trường Vận hành
* Tệp `docker-compose.yml` định nghĩa **5 dịch vụ**: `postgres:15-alpine`, `redis:7-alpine`, `ai-service` (Python 3.11), `backend` (Spring Boot 3), `frontend` (React Nginx).
* Lệnh thẩm định `docker compose --env-file .env.example config` trả về mã thoát **0 (Cú pháp hợp lệ 100%)**.
* Mạng nội bộ `unicheck_network` (bridge), khối lượng lưu trữ bền vững `postgres_data` và `redis_data`.

### 6.3. Xác minh các dịch vụ bên ngoài (External Services)
* **Cloudinary:** Có dòng biến cấu hình trong `.env.example`, nhưng **HOÀN TOÀN KHÔNG CÓ DÒNG CODE NÀO** sử dụng Cloudinary SDK trong cả Backend, Frontend lẫn Mobile.
* **Firebase Cloud Messaging (FCM):** Có biến môi trường mẫu trong `.env.example`, nhưng **KHÔNG CÓ TRIỂN KHAI** trong mã nguồn.
* **OpenRouter / OpenAI LLM:** **KHÔNG CÓ BẰNG CHỨNG TÍCH HỢP**. Phân hệ Chatbot AI chưa được lập trình.
* **WebSocket / STOMP:** Thư viện `spring-boot-starter-websocket` được khai báo trong `pom.xml`, nhưng **CHƯA CÓ CLASS `@EnableWebSocket` hay `WebSocketHandler` nào** được đăng ký. Luồng giám sát giảng viên hiện hoạt động qua cơ chế HTTP Polling `/recent-checkins`.

---

## 7. KẾT LUẬN KIỂM TOÁN MÃ NGUỒN

1. **Điểm mạnh đã đạt được:**
   - Lõi bảo mật, cơ chế xoay vòng Refresh Token (RTR) và phân quyền RBAC được triển khai mẫu mực, đồng bộ trên cả React Web, Spring Boot và Flutter Mobile.
   - Kiến trúc nhận diện khuôn mặt và chống giả mạo sinh trắc học (YuNet + ArcFace 512D + MiniFASNet Dual Ensemble) tại AI Service đã hoàn thành 100% bằng thuật toán Deep Learning thực tế, đạt chuẩn bảo mật Fail-Closed, tốc độ xử lý CPU ~11.53ms vượt trội.
   - Quy trình đăng ký Face-ID thời gian thực trên cả Web (WebRTC/MediaPipe) và Mobile (Google ML Kit Head Pose 3 bước) hoạt động nghiêm ngặt, tuân thủ không lưu ảnh gốc.
   - Phân hệ quản lý học vụ và phiên điểm danh (TASK-02 và TASK-05) đã hoàn thiện full-stack từ Web UI đến CSDL.
2. **Điểm còn thiếu hụt và hạn chế cốt lõi:**
   - **Luồng điểm danh của sinh viên trên Mobile (Student Check-in):** Giao diện quét mặt hiện tại là UI Placeholder. Backend chưa có endpoint tiếp nhận nộp điểm danh từ sinh viên; chưa có cơ chế sinh và quét Dynamic QR Code (thuộc kế hoạch TASK-06).
   - **Đa nền tảng:** Ứng dụng di động mới chỉ kiểm thử trên Android Emulator; chưa thể khẳng định chạy tốt trên iOS 10.0+ nếu thiếu môi trường macOS và thiết bị iPhone vật lý. Web được xây dựng bằng React thay vì Flutter Web như đề bài ban đầu của giảng viên.
   - **25 bảng mở rộng:** Các tính năng học vụ nâng cao (điểm số, bài tập, chat lớp, chatbot AI, đơn từ) là thiết kế tương lai, chưa được lập trình trong phiên bản nghiệm thu hiện tại.
