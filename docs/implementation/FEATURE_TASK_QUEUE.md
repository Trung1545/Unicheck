# UniCheck — Hàng Đợi Công Việc Tính Năng Chi Tiết (Feature Task Queue)

> **Mã tài liệu:** IMPL-TASK-QUEUE-2026  
> **Phiên bản:** 1.0.0  
> **Ngày lập:** 15/10/2026  
> **Quy cách:** Đặc tả chính xác từng công việc kỹ thuật đến cấp độ file mã nguồn, endpoint, bảng cơ sở dữ liệu và tiêu chí nghiệm thu (Acceptance Criteria).

---

## TASK-01: Quản Trị Người Dùng Web (User Management React)

* **Mã Công Việc:** `TASK-01`
* **Mức Ưu Tiên:** **P0** (Khởi chạy ngay lập tức)
* **Thời gian ước tính:** 3 ngày làm việc (16/10 - 18/10/2026)
* **Trạng thái hiện tại:** Backend `DONE` (có 8 endpoints và integration test passed), Frontend `NOT_STARTED`.
* **Phụ thuộc:** Authentication Web (`DONE`), [UserController.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/controller/UserController.java) (`ACTIVE`).
* **Màn hình Stitch:** `21275607791c43e58ee6a5b2db656d20` (UniCheck - Quản lý người dùng), `8e1010eda64348f98bd95f7c01648bef` (Quản lý sinh viên), `3c68af65d6ae4a0f9509aed6e9ea81be` (Quản lý giảng viên).
* **Tuyến đường React (Route):** `/admin/users`, `/admin/students`, `/admin/lecturers`.
* **Tệp mã nguồn hiện có:**
  - Backend: `UserController.java`, `UserService.java`, `UserServiceImpl.java`, `UserRepository.java`, `User.java`.
  - Frontend: `src/common-ui/Table.tsx`, `src/common-ui/Pagination.tsx`, `src/common-ui/Button.tsx`, `src/common-ui/Modal.tsx`.
* **Tệp cần tạo / chỉnh sửa:**
  - `frontend/src/api/users.api.ts`: Khai báo API client cho `GET /users`, `POST /users`, `PUT /users/{id}`, `PATCH /users/{id}/status`, `POST /users/import-csv`.
  - `frontend/src/pages/admin/UserManagementPage.tsx`: Bảng dữ liệu người dùng, phân trang, lọc vai trò/trạng thái.
  - `frontend/src/pages/admin/StudentManagementPage.tsx`: Quản lý danh sách sinh viên.
  - `frontend/src/pages/admin/LecturerManagementPage.tsx`: Quản lý danh sách giảng viên.
  - `frontend/src/features/users/components/UserCreateModal.tsx`: Form tạo tài khoản người dùng đơn lẻ.
  - `frontend/src/features/users/components/UserImportCsvModal.tsx`: Form kéo thả tải lên file CSV/Excel danh sách.
* **Backend Endpoints:**
  - `GET /api/v1/users` (ACTIVE)
  - `GET /api/v1/users/{id}` (ACTIVE)
  - `POST /api/v1/users` (ACTIVE)
  - `PUT /api/v1/users/{id}` (ACTIVE)
  - `PATCH /api/v1/users/{id}/status` (ACTIVE)
  - `POST /api/v1/users/import-csv` (ACTIVE)
* **Bảng Cơ Sở Dữ Liệu:** `users`, `student_profiles`, `lecturer_profiles`.
* **Tích hợp AI / Mobile:** Không.
* **Tiêu chí nghiệm thu (Acceptance Criteria):**
  1. Hiển thị danh sách người dùng với phân trang 10/20/50 bản ghi, có tìm kiếm theo họ tên, email, mã số sinh viên/giảng viên.
  2. Lọc chính xác theo vai trò (`STUDENT`, `LECTURER`, `ADMIN`) và trạng thái (`ACTIVE`, `INACTIVE`, `LOCKED`).
  3. Khóa / Mở khóa tài khoản phản hồi cập nhật tức thì trên giao diện mà không cần reload trang.
  4. Import file CSV hợp lệ: Thêm người dùng vào hệ thống và hiển thị thông báo kết quả (số bản ghi thành công/thất bại).
  5. 100% component tuân thủ chính xác bảng màu Academic Precision và typography từ Stitch Screen `21275607791c43e58ee6a5b2db656d20`.
* **Rủi ro & Điểm nghẽn (Blockers):** Không có blocker. Docker daemon cần được bật để test với PostgreSQL thật.

---

## TASK-02: Lõi Học Thuật & Cơ Sở Vật Chất (Academic Core & Facilities)

* **Mã Công Việc:** `TASK-02`
* **Mức Ưu Tiên:** **P0**
* **Thời gian ước tính:** 3 ngày làm việc (19/10 - 21/10/2026)
* **Trạng thái hiện tại:**
  - **TASK-02A (F-11 Courses & F-12 Semesters):** `COMPLETED` (100% Full-Stack: Spring Boot Entities, 15 REST Endpoints, React 18 UI, 54/54 BE tests passed, 24/24 FE tests passed, Vite build OK).
  - **TASK-02B (F-14 Class Sections & F-15 Enrollments):** `COMPLETED` (100% Full-Stack Vertical Slice: Spring Boot Entities, Migration V4, 13 REST Endpoints, React 18 UI matching Stitch Screens 1 & 2, 72/72 BE tests passed, 32/32 FE tests passed, Vite build OK).
  - **TASK-02C (F-13 Rooms & Wi-Fi Access Points):** `COMPLETED` (100% Full-Stack Vertical Slice: Spring Boot Entities, Migration V5, 14 REST Endpoints, React 18 UI matching Stitch Screen `e796d9e992364bfcbf8a32a6330927ce`, 15/15 BE tests passed, 40/40 FE tests passed, Vite build OK, Docker & PostgreSQL E2E passed 100%).
  - **TASK-02D (F-16 Timetable & Slot Scheduling):** `COMPLETED` (100% Full-Stack Vertical Slice: Spring Boot Entities, Migration V6, 10 REST Endpoints, React 18 UI matching Stitch Screen `ac1b85bea7f6478e9c77fd6a4e9594f9`, 13/13 BE tests passed, 8/8 FE tests passed, Vite build OK).
* **Phụ thuộc:** `TASK-01`.
* **Màn hình Stitch:**
  - `a9f520acd00440c8a26633aec9a8799c` (UniCheck - Danh mục học phần) -> **DONE** (`/admin/courses`).
  - `4f0245590b1b4c6ab231b412b5ba845d` (UniCheck - Học kỳ & Niên khóa) -> **DONE** (`/admin/semesters`).
  - `495a21f075ca479698f5f5075cee8a41` (UniCheck - Quản lý lớp học phần) -> **DONE** (`/admin/classes`).
  - `1a99da032e154d86b432c579ec4e4bf1` (UniCheck - Ghi danh & Đăng ký) -> **DONE** (`/admin/enrollments`).
  - `e796d9e992364bfcbf8a32a6330927ce` (UniCheck - Phòng học & Wi-Fi AP) -> **DONE** (`/admin/facilities`).
  - `ac1b85bea7f6478e9c77fd6a4e9594f9` (UniCheck - Thời khóa biểu) -> **DONE** (`/admin/timetable`).
* **Tuyến đường React (Route):** `/admin/courses` (DONE), `/admin/semesters` (DONE), `/admin/classes` (DONE), `/admin/enrollments` (DONE), `/admin/facilities` (DONE), `/admin/timetable` (DONE).
* **Tệp đã tạo / chỉnh sửa:**
  - Backend Entities & Repositories: `Course.java`, `Semester.java`, `SemesterConfig.java`, `ClassSection.java`, `Enrollment.java`, `TeachingAssignment.java`, `Room.java`, `WifiAccessPoint.java`, `RoomWifiAccessPoint.java`, `TimetableSlot.java`, `SlotType.java`, `Holiday.java`, `CourseRepository.java`, `SemesterRepository.java`, `ClassSectionRepository.java`, `EnrollmentRepository.java`, `TeachingAssignmentRepository.java`, `RoomRepository.java`, `WifiAccessPointRepository.java`, `RoomWifiAccessPointRepository.java`, `TimetableSlotRepository.java`, `SlotTypeRepository.java`, `HolidayRepository.java`.
  - Backend DTOs & Services: `ClassSectionService`, `ClassSectionServiceImpl`, `EnrollmentService`, `EnrollmentServiceImpl`, `FacilityService`, `FacilityServiceImpl`, `TimetableService`, `TimetableServiceImpl`, DTOs cho Course, Semester, ClassSection, Enrollment, Room, Wi-Fi AP, TimetableSlot.
  - Backend Controllers & Tests: `CourseController.java` (7 endpoints), `SemesterController.java` (8 endpoints), `ClassSectionController.java` (8 endpoints), `EnrollmentController.java` (5 endpoints), `FacilityController.java` (14 endpoints), `TimetableController.java` (10 endpoints), `TimetableIntegrationTest.java` (13 tests passed).
  - Database Migration: `V4__add_enrollment_unique_and_indexes.sql`, `V5__add_room_wifi_indexes_and_unique.sql`, `V6__add_timetable_slots_indexes.sql`.
  - Frontend Pages & Clients: `CourseCatalogPage.tsx`, `SemesterManagementPage.tsx`, `ClassSectionPage.tsx`, `EnrollmentManagementPage.tsx`, `FacilitiesWifiPage.tsx`, `MasterTimetablePage.tsx`, `courses.api.ts`, `semesters.api.ts`, `classes.api.ts`, `enrollments.api.ts`, `facilities.api.ts`, `timetable.api.ts`, `academic-catalog.test.ts`, `class-section-enrollment.test.ts`, `facilities-wifi.test.ts`, `timetable.test.ts`.
* **Bảng Cơ Sở Dữ Liệu:** `courses`, `course_prerequisites`, `semesters`, `semester_configs`, `class_sections`, `enrollments`, `teaching_assignments`, `rooms`, `wifi_access_points`, `room_wifi_access_points`, `timetable_slots`, `slot_types`, `holidays`.
* **Tiêu chí nghiệm thu:**
  1. CRUD môn học (mã môn, tên môn, số tín chỉ, số tiết học, môn tiên quyết, chống vòng, chống xóa khi đang được tham chiếu) -> **DONE**.
  2. CRUD học kỳ (mã, tên, ngày bắt đầu/kết thúc, cấu hình ca học, tự động đóng học kỳ cũ khi kích hoạt học kỳ mới, khóa học kỳ) -> **DONE**.
  3. Tạo lớp học phần gắn với giảng viên, học kỳ và môn học (bảng `class_sections`, PK `class_name VARCHAR(50)`, kiểm soát sĩ số, chống xóa khi có sinh viên) -> **DONE**.
  4. Ghi danh sinh viên vào lớp học phần (bảng `enrollments`, ràng buộc vai trò STUDENT, chặn ghi danh kép, kiểm tra giới hạn sĩ số phòng học, hủy ghi danh an toàn) -> **DONE**.
  5. Khai báo danh sách Wi-Fi AP gắn với phòng học (`room_wifi_access_points`), chuẩn hóa BSSID, chặn trùng lặp, bảo vệ ràng buộc toàn vẹn khi xóa -> **DONE** (TASK-02C).
  6. Lập lịch học (`timetable_slots`) theo phòng, ca học, thứ trong tuần, phát hiện trùng lặp 3 chiều (phòng, giảng viên, lớp), kiểm tra ngày lễ và học kỳ, chống sửa/xóa ca học có điểm danh -> **DONE** (TASK-02D).

---

## TASK-03: Động Cơ AI Trích Xuất & So Khớp Khuôn Mặt Thực (Real AI Face Engine)

* **Mã Công Việc:** `TASK-03`
* **Mức Ưu Tiên:** **P0**
* **Thời gian ước tính:** 2 ngày làm việc (22/10 - 23/10/2026)
* **Trạng thái hiện tại:** `COMPLETED` (100% Hoàn thành — Thay thế hoàn toàn mock bằng ArcFace MobileFaceNet ONNX 512-dim thực tế, 18/18 tests passed).
* **Phụ thuộc:** `TASK-01`.
* **Tệp đã tạo / chỉnh sửa:**
  - `ai-service/models/`: `face_detection_yunet_2023mar.onnx` (227 KB, Apache 2.0), `w600k_mbf.onnx` (12.98 MB, MIT/Apache 2.0).
  - `ai-service/config.py`: Module cấu hình tập trung đường dẫn model, ngưỡng `AI_FACE_MATCH_THRESHOLD` (0.68), kích thước ảnh tối đa, siêu tham số detection.
  - `ai-service/face_detector.py`: Giải mã Base64 an toàn, kiểm tra kích thước, phát hiện khuôn mặt bằng YuNet ONNX kèm fallback Haar Cascade, trích xuất 5 facial landmarks.
  - `ai-service/face_engine.py`: Căn chỉnh khuôn mặt Affine 5 mốc về chuẩn 112x112, chuẩn hóa `[-1.0, 1.0]`, chạy mô hình ArcFace MobileFaceNet qua ONNX Runtime CPU, chuẩn hóa L2 vector 512 chiều.
  - `ai-service/face_matcher.py`: Tính toán Cosine Similarity và Euclidean Distance, kiểm tra tính toàn vẹn vector (NaN/Inf/Zero), kiểm tra ngưỡng so khớp.
  - `ai-service/app.py`: Cập nhật endpoint `/health` (kiểm tra readiness), `/api/v1/face/extract-embedding` (vector 512-dim), `/api/v1/face/verify-face` (so khớp danh tính), `/api/v1/face/check-liveness` (fail-closed HTTP 501 UNAVAILABLE).
  - `ai-service/requirements.txt`: Pin `onnxruntime>=1.19.0`, `opencv-python-headless>=4.9.0.80`, `numpy>=1.26.0`.
  - `ai-service/Dockerfile` & `docker-compose.yml`: Bổ sung healthcheck model readiness và biến môi trường `AI_MODEL_DIR`, `AI_FACE_MATCH_THRESHOLD`.
  - `ai-service/tests/test_face_engine.py`: Bộ kiểm thử 15 ca unit & integration tests toàn diện (100% passed).
* **Tiêu chí nghiệm thu:**
  1. Gửi ảnh khuôn mặt hợp lệ: Trả về vector 512 phần tử float chuẩn hóa L2, `face_detected: true`, `confidence > 0.9` -> **DONE**.
  2. Gửi ảnh không có mặt hoặc bị che khuất: Trả về `face_detected: false`, mã lỗi `ERR_3001` -> **DONE**.
  3. Gửi ảnh có nhiều hơn một khuôn mặt: Trả về `face_detected: false`, mã lỗi `ERR_3002`, `face_count >= 2` -> **DONE**.
  4. Thời gian xử lý trích xuất vector E2E đo được trên CPU: Trung bình **14.59ms** (p50: 14.59ms, p95: 16.10ms), nhanh hơn 20 lần so với ngân sách quy định $\le 300ms$ -> **DONE**.
  5. Ngưỡng Cosine Similarity cấu hình động qua biến môi trường `AI_FACE_MATCH_THRESHOLD` (mặc định 0.68) -> **DONE**.
  6. Endpoint Liveness Anti-Spoofing thực thi Fail-Closed (HTTP 501 UNAVAILABLE, `ERR_3003`), ngăn chặn bypass điểm danh giả mạo -> **DONE**.

---

## TASK-04: Luồng Đăng Ký Khuôn Mặt Sinh Viên (Face Enrollment Pipeline)

* **Mã Công Việc:** `TASK-04`
* **Mức Ưu Tiên:** **P0**
* **Thời gian ước tính:** 2 ngày làm việc (24/10 - 25/10/2026)
* **Trạng thái hiện tại:** `COMPLETED` (100% Full-Stack Vertical Slice: Realtime Face Scanning, WebRTC frame throttling ~120ms, Oval Guideline Stitch Screen `a17db05b39144990b49bee366c1e3b43`, 4 Realtime Metrics, Auto-capture, Spring Boot `FaceEnrollmentController` + `AiServiceClient` lưu BYTEA vector 512D vào `face_encodings`, 8/8 tests BE passed, 8/8 tests FE passed, Flutter Mobile `FaceEnrollmentView` tích hợp).
* **Phụ thuộc:** `TASK-01`, `TASK-03`.
* **Màn hình Stitch:** `a17db05b39144990b49bee366c1e3b43` (UniCheck Sinh viên - Đăng ký & Cập nhật Face-ID) -> **DONE** (`/student/face-enrollment`, `/student/face-id`, `/profile/face-id`).
* **Tuyến đường React:** `/student/face-enrollment` (DONE), `/student/face-id` (DONE), `/profile/face-id` (DONE).
* **Tệp đã tạo / chỉnh sửa:**
  - Backend: `FaceEnrollmentController.java` (4 REST endpoints), `FaceEnrollmentService.java`, `FaceEnrollmentServiceImpl.java`, `AiServiceClient.java`, DTOs (`FaceRegistrationRequest`, `FaceSampleDto`, `FaceEnrollmentResponse`, `FaceStatusResponse`), `FaceEnrollmentIntegrationTest.java` (8/8 tests passed).
  - Database: Bảng `face_encodings` (lưu vector 512-dim 2048 bytes BYTEA), cập nhật `users.face_data_status = 'REGISTERED'`.
  - Frontend: `FaceRegistrationPage.tsx`, `face.api.ts`, `face-enrollment.test.ts` (8/8 tests passed), tích hợp `ProfilePage.tsx` và `navigation.config.ts`.
  - Mobile: `face_enrollment_view.dart`, `app_routes.dart`, `main.dart`, `student_shell_view.dart`.
* **Tiêu chí nghiệm thu:**
  1. Quét khuôn mặt thời gian thực (Realtime Face Scanning): Camera preview liên tục, vẽ khung Oval hướng dẫn Stitch `a17db05b39144990b49bee366c1e3b43` -> **DONE**.
  2. Điều tiết tần suất xử lý frame (Throttling ~120ms) tránh lag UI -> **DONE**.
  3. Hiển thị 4 metrics đo lường trực tiếp: Ánh sáng (>=40), Độ nét (>=70), Số khuôn mặt (đơn nhất == 1), Khoảng cách (tối ưu ~55cm) -> **DONE**.
  4. Hướng dẫn trực tiếp chuyển động: Khớp khung oval, di chuyển lại gần/xa, nhìn thẳng camera, giữ ổn định -> **DONE**.
  5. Tự động thu nhận frame hợp lệ khi ổn định mà không cần nhấn nút chụp ảnh -> **DONE**.
  6. Backend gọi Flask AI Service trích xuất vector 512 chiều ArcFace MobileFaceNet và lưu BYTEA vào `face_encodings` -> **DONE**.
  7. Cam kết bảo vệ dữ liệu sinh trắc học: KHÔNG lưu ảnh thô trên server, KHÔNG lưu ảnh/vector vào `localStorage` -> **DONE**.
  8. Cập nhật `users.face_data_status` thành `REGISTERED` và hiển thị Modal chứng nhận sinh trắc học -> **DONE**.
  9. Giải phóng stream camera khi rời màn hình hoặc kết thúc quét -> **DONE**.
  10. Tuyên bố rõ ràng: Chưa tuyên bố chống giả mạo cho tới khi có anti-spoofing thật (MiniFASNet TASK-07) -> **DONE**.

---

## TASK-05: Quản Lý Phiên Điểm Danh (Attendance Session Management & Config)

* **Mã Công Việc:** `TASK-05`
* **Mức Ưu Tiên:** **P0**
* **Trạng thái:** **`COMPLETED` (100% Full-Stack Vertical Slice)**
* **Báo cáo nghiệm thu:** [`docs/testing/TASK_05_ATTENDANCE_SESSION_ACCEPTANCE_REPORT.md`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/docs/testing/TASK_05_ATTENDANCE_SESSION_ACCEPTANCE_REPORT.md)
* **Màn hình Stitch:** 
  - `4f83098c7b904d4389563c28f54e1c48` (UniCheck - Quản lý phiên điểm danh giảng đường) -> **DONE**.
  - `300c3071598340e5981a9a5f5097f909` (UniCheck - Thiết lập & Cấu hình Cơ chế Điểm danh Động) -> **DONE**.
* **Tuyến đường React:** `/admin/attendance/sessions`, `/dashboard/attendance-sessions`, `/lecturer/attendance/sessions`, `/lecturer/attendance-session`, `/admin/attendance/configs`, `/dashboard/attendance-configs`.
* **Backend:**
  - `GET /api/v1/attendance/sessions`: Danh sách phân trang, tìm kiếm, lọc (học kỳ, lớp, giảng viên, ngày, trạng thái).
  - `GET /api/v1/attendance/sessions/{id}`: Chi tiết phiên điểm danh.
  - `POST /api/v1/attendance/sessions`: Khởi tạo phiên từ `timetable_slot_id` (chặn trùng, kiểm tra quyền giảng viên).
  - `POST /api/v1/attendance/sessions/{id}/open`: Mở phiên điểm danh nguyên tử (`CREATED -> OPEN`).
  - `POST /api/v1/attendance/sessions/{id}/close`: Đóng phiên điểm danh nguyên tử (`OPEN -> CLOSED`), bảo lưu toàn bộ lịch sử điểm danh.
  - `GET /api/v1/attendance/sessions/{id}/status`: Hợp đồng trạng thái phiên phục vụ TASK-06 (`canGenerateQr`).
  - `GET /api/v1/attendance/sessions/stats`: 4 chỉ số KPI thời gian thực.
  - `GET /api/v1/attendance/configs`: Tra cứu cấu hình cơ chế điểm danh.
  - `PUT /api/v1/attendance/configs`: Cập nhật cấu hình cơ chế (ADMIN only, audit logged).
  - `GET /api/v1/attendance/sessions/{id}/attendances`: Danh sách check-in sinh viên trong ca học.
* **Cơ sở dữ liệu:** PostgreSQL 18 migration `V7__add_attendance_sessions_constraints_and_indexes.sql` áp dụng thành công.
* **Kiểm thử:**
  - Backend: 19/19 Integration Tests passed (`AttendanceSessionIntegrationTest.java`), 132/132 Regression Tests passed.
  - Frontend: 78/78 Tests passed (`attendance-session.test.ts`), Production Build `tsc -b && vite build` OK.

---

## TASK-06: Sinh Mã QR Động & Xoay Vòng Bảo Mật (Dynamic QR Code Engine)

* **Mã Công Việc:** `TASK-06`
* **Mức Ưu Tiên:** **P0**
* **Trạng thái hiện tại:** **`READY_TO_START`** (Phụ thuộc nền tảng từ TASK-05 đã hoàn thành 100%).
* **Phụ thuộc:** `TASK-05` (Hợp đồng Session ID và `AttendanceSessionStatusResponse`).
* **Màn hình Stitch:** `5c0df9af4d2545919e8f774c1159e7da` (Giảng viên - Khởi tạo phiên & QR động).
* **Tuyến đường React:** `/lecturer/session/qr`.
* **Nghiệp vụ cốt lõi:**
  - Sinh mã QR động HMAC-SHA256 xoay vòng mỗi 5-10 giây (theo cấu hình từ `attendance_configs`).
  - Hiển thị đồng hồ đếm ngược trực quan (Visual Countdown Radar / Circle).
  - Ngăn chặn chụp màn hình gửi bên ngoài; mã QR quá hạn bị từ chối khi check-in.

---

## TASK-07 & TASK-08: Check-in Điểm Danh Trên Mobile & Chống Gian Lận Liveness

* **Mã Công Việc:** `TASK-07-08`
* **Mức Ưu Tiên:** **P0**
* **Thời gian ước tính:** 5 ngày làm việc (29/10 - 02/11/2026)
* **Trạng thái hiện tại:** `BLOCKED` do `mobile/pubspec.yaml` thiếu các native plugins phần cứng.
* **Phụ thuộc:** `TASK-03`, `TASK-04`, `TASK-06`.
* **Tệp cần tạo / chỉnh sửa:**
  - `mobile/pubspec.yaml`: Thêm `camera: ^0.11.0`, `google_mlkit_face_detection: ^0.12.0`, `mobile_scanner: ^5.2.0`, `network_info_plus: ^5.0.1`, `geolocator: ^12.0.0`.
  - `mobile/lib/feature/attendance/`: Hiện thực hóa `FaceCheckinView` với khung Oval hướng dẫn định vị khuôn mặt.
  - `ai-service/app.py`: Tích hợp model `MiniFASNet` kiểm tra liveness chống ảnh in/màn hình.
* **Tiêu chí nghiệm thu:**
  1. Sinh viên quét mã QR từ máy chiếu -> Ứng dụng tự động bật camera trước.
  2. Hướng dẫn sinh viên chớp mắt / giữ thẳng mặt trong khung Oval.
  3. Ứng dụng đọc BSSID của Wi-Fi đang kết nối gửi kèm ảnh selfie và QR token lên API `POST /api/v1/attendance/check-in`.
  4. Server xác thực 4 lớp: Khớp BSSID phòng học + QR token hợp lệ + Liveness $\ge$ ngưỡng + Khuôn mặt khớp hồ sơ.

---

## TASK-09 & TASK-10: Giám Sát Realtime & Lịch Sử Điểm Danh (Live Monitor & Logs)

* **Mã Công Việc:** `TASK-09-10`
* **Mức Ưu Tiên:** **P1**
* **Thời gian ước tính:** 3 ngày làm việc (03/11 - 04/11/2026)
* **Màn hình Stitch:**
  - `c20e515d6d0940379d90ea268522b07e` (Giảng viên - Giám sát điểm danh trực tiếp).
  - `dd2b950932464528a607e4ebd490f5e1` (Cảnh báo an ninh & Bất thường).
  - `9ba51f6ecd70421582816363439f4530` (Sinh viên - Lịch sử điểm danh).
  - `769ce5a775bd429cb46ee5e447868e98` (Lịch sử điểm danh toàn trường).
* **Công nghệ:** Spring Boot WebSocket STOMP (`/topic/session.{id}`).
* **Tiêu chí nghiệm thu:** Sinh viên check-in thành công trên Mobile, thẻ đại diện của sinh viên trên Web máy chiếu chuyển sang màu xanh (Có mặt) trong vòng $\le 500ms$.

---

## TASK-11 & TASK-12: Báo Cáo Chuyên Cần & Các Module Còn Lại (Reports, Requests, Grades)

* **Mã Công Việc:** `TASK-11-12`
* **Mức Ưu Tiên:** **P1 / P2**
* **Thời gian ước tính:** 3 ngày làm việc (05/11 - 06/11/2026)
* **Màn hình Stitch:** `c9523d6727af4088a7135067d379c570` (Thống kê chuyên cần), `f3fad431243448f4a7758c9ced16b695` (Duyệt đơn), `c7ac82956cfe41b3b762e7aaabc2bcfa` (Gửi đơn), `ef5d3e2ef1f14d349f4f732efcee4e55` (Sổ điểm), `0d390145e7e14c498c170acf8ed21778` (Bài tập), `300c3071598340e5981a9a5f5097f909` (Cấu hình).
* **Tiêu chí nghiệm thu:** Xuất file Excel báo cáo chuyên cần lớp học chuẩn mẫu, sinh viên nộp đơn nghỉ học kèm minh chứng, giảng viên phê duyệt đơn.

---

## TASK-13: Tổng Kiểm Thử QA, Tải Trọng & Đóng Gói Nghiệm Thu

* **Mã Công Việc:** `TASK-13`
* **Mức Ưu Tiên:** **P0**
* **Thời gian:** Ngày 07/11/2026
* **Tiêu chí nghiệm thu:** 100% test suites passed, Docker Compose khởi động an toàn mọi dịch vụ với biến môi trường hợp lệ, bàn giao toàn bộ tài liệu nghiệm thu.
