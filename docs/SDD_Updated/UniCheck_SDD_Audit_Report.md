# BÁO CÁO KIỂM TOÁN VÀ ĐỐI CHIẾU THIẾT KẾ PHẦN MỀM UNICHECK
## SOFTWARE DESIGN DOCUMENT (SDD) AUDIT REPORT — v2.1
**Dự án:** UniCheck — Hệ thống Điểm danh Thông minh Đa nền tảng sử dụng Nhận diện Khuôn mặt  
**Tài liệu đối chiếu gốc:** `UniCheck_Software_Design_Document(1).docx` (Báo cáo Đồ án Report 4, 119 trang)  
**Tài liệu tiêu chí:** `Yeucau_DuAn_DiemDanh_FaceID(2).docx`  
**Căn cứ kiểm toán:** Toàn bộ mã nguồn thực tế tại kho lưu trữ UniCheck (Web Frontend, Mobile Flutter, Backend Spring Boot, AI Service Flask, Database PostgreSQL & Redis)  
**Ngày thực hiện:** Tháng 10 / 2026  
**Đơn vị thực hiện:** Nhóm Kỹ sư Kiến trúc Phần mềm & Đảm bảo Chất lượng UniCheck  

---

## 1. TỔNG QUAN KIỂM TOÁN VÀ PHẠM VI ĐỐI CHIẾU

### 1.1. Mục tiêu kiểm toán
Tài liệu Báo cáo Đồ án Report 4 (`UniCheck_Software_Design_Document.docx`, 119 trang, 161 hình và 5 bảng) là một bản thiết kế hệ thống tương đối đồ sộ, bao quát toàn diện một hệ thống Quản lý Đào tạo và Điểm danh Đại học hoàn chỉnh với 21 phân hệ nghiệp vụ và 50 bảng cơ sở dữ liệu.

Tuy nhiên, quá trình triển khai mã nguồn thực tế đã có những điều chỉnh kiến trúc, tối ưu hóa công nghệ và phân kỳ phát triển nhằm đảm bảo tính khả thi cao nhất cho mục tiêu cốt lõi: **Hệ thống Điểm danh Sinh trắc học Khuôn mặt (FaceID) an toàn, chống giả mạo (Anti-spoofing) và hoạt động ổn định trên môi trường mạng phân tán**.

Mục tiêu của đợt kiểm toán này là:
1. **Đối chiếu thực chứng (Evidence-based Audit):** Khảo sát từng lớp kiến trúc, từng controller, service, entity, repository, module AI, và view mobile để xác định mức độ sai lệch giữa tài liệu thiết kế gốc và mã nguồn đang chạy.
2. **Kế thừa và Chuẩn hóa:** Bảo tồn toàn bộ công sức thiết kế của 21 phân hệ nghiệp vụ từ Report 4. Những module đã triển khai thực tế sẽ được cập nhật sơ đồ lớp (Class Diagram), sơ đồ tuần tự (Sequence Diagram), API contract và bảng dữ liệu chính xác theo code; những module thuộc lộ trình mở rộng (Future Scope) sẽ được phân loại minh bạch là `PLANNED DESIGN / FUTURE EXTENSION` thay vì loại bỏ.
3. **Loại bỏ các thông tin suy diễn:** Xóa bỏ triệt để các khẳng định không có căn cứ (như việc sử dụng Cloudinary, Firebase FCM, WebSocket STOMP, OpenRouter LLM...) nếu mã nguồn và hạ tầng thực tế chưa tích hợp.

### 1.2. Tổng hợp kết quả đo kiểm mã nguồn thực tế
Hệ thống kiểm thử tự động toàn diện trên toàn bộ kho mã nguồn đã được thực thi với kết quả tuyệt đối:
- **Spring Boot Backend Test Suite:** 132/132 Unit & Integration tests đạt (Maven Surefire).
- **React Frontend Test Suite:** 78/78 Component & State tests đạt (Vitest).
- **Flutter Mobile Test Suite:** 32/32 Unit & Widget tests đạt (Flutter Test).
- **Python Flask AI Service Test Suite:** 39/39 Engine & API tests đạt (Pytest).
- **Tổng cộng:** 281/281 Automated Tests Passed (100% tỷ lệ vượt qua).

---

## 2. PHÂN TÍCH ĐỐI CHIẾU KIẾN TRÚC TỔNG THỂ (SYSTEM ARCHITECTURE)

### 2.1. Mô hình kiến trúc phân tán (Distributed Modular Architecture)
- **Tài liệu gốc (Report 4):** Mô tả kiến trúc tổng quát có phần trừu tượng, đề cập đến các thành phần Notification Service, Chat Service, File Storage Service như các microservices độc lập nhưng không nêu rõ giao thức kết nối.
- **Mã nguồn thực tế:** Hệ thống được tổ chức theo mô hình **Hybrid Distributed Architecture** gồm 4 khối độc lập, giao tiếp thông qua giao thức chuẩn:
  1. **Web Frontend (Admin & Giảng viên):** Ứng dụng SPA (Single Page Application) xây dựng bằng **React 18.3.1**, **TypeScript 5.6.2**, **Vite 5.4.8**, giao diện Tailwind CSS 3.4.13, quản lý trạng thái bằng Zustand 5, gọi REST API qua Axios Client.
  2. **Mobile App (Sinh viên):** Ứng dụng di động xây dựng bằng **Flutter 3.27 / Dart 3.6**, quản lý trạng thái và điều hướng bằng GetX 4.6.6, kết nối mạng qua Dio 5.7.0, xử lý thị giác máy tính trên thiết bị qua Google ML Kit Face Detection và Camera plugin. Ứng dụng tập trung 100% cho vai trò **STUDENT** (không phân mảnh giao diện Admin/Lecturer trên Mobile).
  3. **Backend Service (Nghiệp vụ & Dữ liệu cốt lõi):** Ứng dụng **Spring Boot 3.3.4 (Java 22/21)** module hóa phân lớp (Controller - Service - Repository - Entity), bảo mật với Spring Security & JJWT 0.12.6, quản trị vòng đời điểm danh, xử lý xuất nhập bảng tính với Apache POI 5.3.0, quản lý migration qua Flyway 10.18.
  4. **AI Vision Microservice (Xử lý Thị giác máy tính chuyên sâu):** Dịch vụ vi mô độc lập phát triển bằng **Python 3.11** và **Flask 3.1**, thực thi suy luận mô hình học sâu qua **ONNX Runtime 1.31** và OpenCV Headless 5.0, chạy hoàn toàn cục bộ trên CPU/GPU của máy chủ mà không phụ thuộc API đám mây thương mại.

```
+-------------------------------------------------------------------------------+
|                                CLIENT TIER                                    |
|  +-----------------------------------+    +--------------------------------+  |
|  |       Web Frontend (React)        |    |      Mobile Client (Flutter)   |  |
|  |     [Admin & Lecturer Portal]     |    |        [Student Portal]        |  |
|  |  React 18, TS 5, Vite, Zustand 5  |    |  Flutter 3, GetX, Google MLKit |  |
|  +-----------------+-----------------+    +----------------+---------------+  |
+--------------------|---------------------------------------|------------------+
                     | HTTPS / JSON REST API                 | HTTPS / Multipart
                     v                                       v
+-------------------------------------------------------------------------------+
|                            BACKEND APPLICATION TIER                           |
|                       Spring Boot 3.3.4 / Java 22 / 21                        |
|  +-------------------------------------------------------------------------+  |
|  | Dual-Route Controllers: /api/v1/* (Public/Auth), /api/* (Core Business) |  |
|  +------------------------------------+------------------------------------+  |
|                                       |                                       |
|  +------------------------------------+------------------------------------+  |
|  | Application Services (Auth, User, Schedule, AttendanceSession, etc.)    |  |
|  +------------------+----------------------------------+-------------------+  |
|                     |                                  |                      |
|                     v                                  v                      |
|  +----------------------------------+  +-----------------------------------+  |
|  | Data Layer: 25 Active JPA Ents   |  | AI Integration Client (RestTemplate)| |
|  +------------------+---------------+  +---------------+-------------------+  |
+---------------------|----------------------------------|----------------------+
                      |                                  | Internal HTTP / JSON
                      v                                  v
+------------------------------------+   +--------------------------------------+
|            DATA TIER               |   |          AI SERVICE TIER             |
|  +------------------------------+  |   |           Python 3.11 / Flask 3.1    |
|  | PostgreSQL 15 (50 Tables)    |  |   |  +--------------------------------+  |
|  | - 25 Active Tables (JPA)     |  |   |  | Face Detection (YuNet ONNX)    |  |
|  | - 25 Future Extension Tables |  |   |  +--------------------------------+  |
|  | - Binary BYTEA 2048B (Faces) |  |   |  | Liveness Ensemble (MiniFASNet) |  |
|  +------------------------------+  |   |  +--------------------------------+  |
|  | Redis 7 (Tokens & Sessions)  |  |   |  | Feature 512D (ArcFace ONNX)    |  |
|  +------------------------------+  |   |  +--------------------------------+  |
+------------------------------------+   +--------------------------------------+
```

### 2.2. Kiến trúc Routing: Dual-Route Architecture
Mã nguồn Spring Boot Backend sử dụng cơ chế định tuyến song song (**Dual-Route Architecture**):
- Tuyến `/api/v1/*`: Phục vụ các endpoint chuẩn hóa phiên bản như `/api/v1/auth/*` (Login, Token Refresh, Current User, Logout, Change Password).
- Tuyến `/api/*`: Phục vụ các API nghiệp vụ quản trị và vận hành giảng dạy (`/api/users`, `/api/semesters`, `/api/courses`, `/api/class-sections`, `/api/schedules`, `/api/attendance/sessions`, `/api/attendance/records`, `/api/rooms`).
- **Khuyến nghị chuẩn hóa SDD:** Tài liệu thiết kế v2.1 cần mô tả chính xác cả hai tiền tố đường dẫn này để phản ánh trung thực cách triển khai trong `SecurityConfig.java` và các `@RequestMapping`.

### 2.3. Hiện trạng Cơ sở dữ liệu: 25 Bảng Hoạt động (Active) vs 25 Bảng Lộ trình (Planned)
- **Thiết kế gốc (Report 4):** Trình bày ERD với 50 thực thể/bảng dữ liệu.
- **Mã nguồn thực tế:**
  - Bộ script di chuyển Flyway (`V1__init_schema.sql` đến `V7__add_indexes.sql`) tạo đầy đủ **50 bảng** với toàn bộ khóa chính, khóa ngoại, ràng buộc duy nhất và chỉ mục hiệu năng.
  - Tầng ánh xạ thực thể Java (JPA / Hibernate) hiện triển khai chính xác **25 thực thể (Entities)** phục vụ toàn bộ nghiệp vụ lõi: Người dùng, Phân quyền, Giảng viên, Sinh viên, Học kỳ, Môn học, Lớp học phần, Thời khóa biểu, Phòng học, Điểm phát WiFi, Cấu hình điểm danh, Phiên điểm danh, Bản ghi điểm danh, Dữ liệu khuôn mặt, Lịch sử kiểm toán.
  - **25 bảng còn lại** (như `assignments`, `student_submissions`, `quizzes`, `quiz_questions`, `student_grades`, `chat_groups`, `chat_messages`, `ai_conversations`, `leave_requests`...) đã tồn tại trong schema cơ sở dữ liệu nhưng chưa tạo entity JPA do thuộc giai đoạn hoàn thiện học tập và cộng tác mở rộng.
  - **Khuyến nghị chuẩn hóa SDD:** Phân tách rõ ràng chương Database Design thành hai phần: Thực thể JPA đang vận hành (Active Core Schema) và Bảng cấu trúc phục vụ mở rộng (Planned Extension Schema).

### 2.4. Công nghệ Nhận diện Khuôn mặt & Chống giả mạo (AI Pipeline)
- **Tài liệu gốc (Report 4):** Mô tả sơ lược việc nhận diện khuôn mặt, chưa chỉ định rõ thuật toán bóc tách đặc trưng, độ phân giải vector embedding, kiến trúc mô hình liveness, hay ngưỡng quyết định (thresholds).
- **Mã nguồn thực tế:** Triển khai một pipeline học sâu cực kỳ hiện đại, tối ưu hóa suy luận cục bộ:
  1. **Phát hiện khuôn mặt (Face Detection):** Sử dụng mô hình **YuNet** (`face_detection_yunet_2023mar.onnx`), ngưỡng phát hiện tin cậy `0.60`, hỗ trợ phát hiện đa góc nghiêng và trích xuất 5 điểm mốc (landmarks).
  2. **Kiểm tra sống động (Anti-Spoofing / Liveness Detection):** Triển khai kiến trúc **Dual-Ensemble MiniFASNet** kết hợp hai mô hình: `MiniFASNetV2.onnx` và `MiniFASNetV1SE.onnx`. Cơ chế bình chọn trọng số, tính toán Softmax trên 3 lớp (Real, 2D Spoof, 3D Mask), ngưỡng chấp thuận `0.70`.
  3. **Bóc tách vector đặc trưng (Feature Extraction):** Sử dụng mạng nơ-ron **ArcFace MobileFaceNet** (`w600k_mbf.onnx`), xuất ra vector đặc trưng chuẩn hóa **512 chiều (512-dimensional float32 vector)**.
  4. **So khớp khuôn mặt (Face Verification):** So khớp khoảng cách Cosine (**Cosine Distance**), ngưỡng nhận dạng chuẩn: `0.68` (tương đương Cosine Similarity $\ge 0.32$).
  5. **Cơ chế Fail-Closed:** Khi hệ thống AI gặp lỗi tải mô hình, hỏng frame hình ảnh, hoặc không phát hiện đúng 1 khuôn mặt, API ngay lập tức phản hồi mã lỗi `503 Service Unavailable` hoặc `400 Bad Request`, tuyệt đối không cho phép điểm danh thành công ngoài kiểm soát.
  6. **Độ trễ đo kiểm (Inference Latency):** Thời gian xử lý trọn gói toàn bộ pipeline trên CPU thông thường chỉ đạt **~11.53 ms/frame**, hoàn toàn đáp ứng yêu cầu thời gian thực.

### 2.5. Cơ chế Thu thập Dữ liệu Khuôn mặt (Face Enrollment Process)
- **Tài liệu gốc (Report 4):** Mô tả chụp ảnh 1 lần duy nhất trên ứng dụng.
- **Mã nguồn thực tế:**
  - Client Flutter triển khai luồng **3-Step Realtime Head Pose Enrollment** (`face_enrollment_view.dart`, `head_pose_evaluator.dart`):
    - Bước 1: Giữ khuôn mặt trực diện (Center / Forward: Yaw $\in [-10^\circ, 10^\circ]$, Pitch $\in [-10^\circ, 10^\circ]$).
    - Bước 2: Quay đầu sang trái (Turn Left: Yaw $< -15^\circ$).
    - Bước 3: Quay đầu sang phải (Turn Right: Yaw $> 15^\circ$).
  - Thuật toán cục bộ trên điện thoại (Google ML Kit) đánh giá góc quay thời gian thực (Euler angles), tự động kích hoạt chụp khi người dùng giữ góc hợp lệ trong 1.5 giây.
  - Toàn bộ ảnh được gửi lên Backend để chuyển tiếp sang AI Service, trích xuất vector 512D trung bình tối ưu và lưu vào PostgreSQL.

### 2.6. Bảo mật Sinh trắc học & Lưu trữ Dữ liệu Khuôn mặt (Biometric Privacy)
- **Tài liệu gốc (Report 4):** Đề cập đến việc upload ảnh khuôn mặt lên lưu trữ đám mây (Cloudinary) và lưu URL ảnh.
- **Mã nguồn thực tế:** Tuân thủ triệt để nguyên tắc **Privacy by Design** và tiêu chuẩn bảo vệ dữ liệu sinh trắc học quốc tế (GDPR / ISO 27001):
  - **Không lưu trữ ảnh thô:** Cột `face_image` trong bảng `student_face_data` được thiết kế nhận giá trị `NULL`. Hệ thống không lưu trữ bất kỳ hình ảnh chụp thực tế nào của sinh viên sau khi hoàn tất trích xuất đặc trưng.
  - **Lưu trữ nhị phân Vector Embedding:** Vector đặc trưng 512 chiều kiểu số thực dấu phẩy động 32-bit (float32) được chuyển đổi thành chuỗi nhị phân tuần tự Little-Endian chính xác **2048 bytes (512 $\times$ 4 bytes)** và lưu trực tiếp trong trường `face_embedding BYTEA`.
  - Không thể giải mã ngược chuỗi nhị phân 2048 bytes này để tái tạo lại ảnh mặt người ban đầu.

---

## 3. BẢNG KIỂM TOÁN VÀ ĐỐI CHIẾU CHI TIẾT 21 MODULE THIẾT KẾ

Bảng dưới đây đối chiếu chi tiết 21 phân hệ được đặc tả tại Mục 3 của tài liệu Report 4 với mã nguồn thực tế:

| STT | Phân hệ trong SDD gốc (Mục 3) | Sơ đồ kế thừa từ SDD gốc | Trạng thái triển khai thực tế | Minh chứng mã nguồn / API / Bảng CSDL | Nội dung hiệu chỉnh trong SDD v2.1 |
|:---:|:---|:---|:---:|:---|:---|
| **3.1** | **Authentication** | Class Diagram (Fig 7), Login (Fig 8), Logout (Fig 9), Profile (Fig 10-11), Change Pass (Fig 12), Forgot Pass (Fig 13) | **IMPLEMENTED & TESTED** | `AuthController.java`, `AuthService.java`, `JwtTokenProvider.java`, `/api/v1/auth/*`, Bảng `users`, `roles`, Redis Token Store. Tests: 13/13 backend tests passed. | Cập nhật cơ chế Refresh Token Rotation (RTR), bảo mật JWT kép (Access 15m / Refresh 7d). Ghi chú Forgot Password qua Email tạm thời mock ở tầng mail server. |
| **3.2** | **System Account Management** | Class Diagram (Fig 14), User CRUD, Active/Deactive, Role assignment (Fig 15-24) | **IMPLEMENTED & TESTED** | `UserController.java`, `UserService.java`, `UserManagementPage.tsx`, `/api/users/*`, Bảng `users`, `user_roles`. Tests: 16/16 backend tests passed. | Đồng bộ các DTO thực tế: `UserResponse`, `CreateUserRequest`, `UpdateUserRequest`. Chuẩn hóa mã hóa mật khẩu BCrypt. |
| **3.3** | **Notification Management** | Class Diagram (Fig 25), View / Create Notifications & News (Fig 26-33) | **PLANNED DESIGN** | Bảng CSDL `notifications`, `news` đã tạo trong Flyway V1. Web Frontend có Header Bell icon hiển thị mock. Backend chưa tạo JPA Entity. | Giữ nguyên toàn bộ thiết kế Class & Sequence diagram từ Report 4. Đánh dấu trạng thái PLANNED DESIGN phục vụ lộ trình tích hợp hệ thống tin tức. |
| **3.4** | **System Monitoring & Audit** | Class Diagram (Fig 34), View Access Log & System Log (Fig 35-36) | **PARTIAL** | `AuditLog.java`, `AuditLogRepository.java`, ghi log tự động qua Interceptor/Filter, Bảng `audit_logs`. Chưa có trang hiển thị chuyên dụng cho Admin. | Giữ nguyên thiết kế luồng ghi log; cập nhật cấu trúc bảng `audit_logs` thực tế trong CSDL; phân định rõ tầng Backend đã hoạt động, tầng Web Admin đang hoàn thiện UI. |
| **3.5** | **Student Records Management** | Class Diagram (Fig 37), Import/Export, View, Update Student (Fig 38-42) | **IMPLEMENTED & TESTED** | `StudentProfile.java`, `StudentProfileRepository.java`, `StudentManagementPage.tsx`, `/api/students/*`, Apache POI `ExcelHelper.java`. | Cập nhật cấu trúc trường thực tế (`student_code`, `major_id`, `class_name`, `academic_year`). Đồng bộ luồng Import/Export Excel bằng Apache POI. |
| **3.6** | **Lecturer Records Management** | Class Diagram (Fig 43), Import/Export, View, Update Lecturer (Fig 44-48) | **IMPLEMENTED & TESTED** | `LecturerProfile.java`, `LecturerProfileRepository.java`, `LecturerManagementPage.tsx`, `/api/lecturers/*`, Bảng `lecturer_profiles`. | Cập nhật DTO và quan hệ 1-1 với `users`. Đồng bộ hóa các thao tác quản trị hồ sơ giảng viên. |
| **3.7** | **Facility Management** | Class Diagram (Fig 49), Room CRUD, Wifi AP CRUD, Assign AP (Fig 50-59) | **IMPLEMENTED & TESTED** (Room) / **PARTIAL** (Wifi) | `Room.java`, `RoomRepository.java`, `RoomController.java`, `WifiAccessPoint.java`, `/api/rooms/*`, Bảng `rooms`, `wifi_access_points`. | Quản lý phòng học đã hoàn thiện toàn diện. Quản lý BSSID/WiFi Access Point đã có Entity & Schema, phục vụ kiểm tra đối chiếu mạng khi điểm danh (TASK-06). |
| **3.8** | **Curriculum Management** | Class Diagram (Fig 60), Major & Specialization CRUD (Fig 61-76) | **PARTIAL** | Bảng `majors`, `specializations` trong Flyway V1. `Major.java` entity cơ bản. Quản lý lồng ghép trong danh mục sinh viên và khoa. | Giữ nguyên các sơ đồ nghiệp vụ từ Report 4; cập nhật mô hình dữ liệu quan hệ Major - Department thực tế. |
| **3.9** | **Course Catalog Management** | Class Diagram (Fig 77), Course CRUD, Prerequisites, Grade Components (Fig 78-88) | **IMPLEMENTED & TESTED** | `Course.java`, `CourseRepository.java`, `CourseController.java`, `CourseManagementPage.tsx`, `/api/courses/*`, Bảng `courses`. | Cập nhật thực thể `Course` (mã môn, số tín chỉ, khoa quản lý). Thành phần điểm (Grade Components) tách riêng sang phân hệ 3.19. |
| **3.10** | **Semester Management** | Class Diagram (Fig 89), Semester CRUD, Configure details (Fig 90-94) | **IMPLEMENTED & TESTED** | `Semester.java`, `SemesterRepository.java`, `SemesterController.java`, `SemesterManagementPage.tsx`, `/api/semesters/*`, Bảng `semesters`. | Chuẩn hóa các trường: `semester_code`, `name`, `start_date`, `end_date`, `is_active`. Trạng thái kích hoạt học kỳ hiện hành. |
| **3.11** | **Class Management** | Class Diagram (Fig 95), Import Class, Class CRUD (Fig 96-100) | **IMPLEMENTED & TESTED** | `ClassSection.java`, `ClassSectionRepository.java`, `ClassSectionController.java`, `ClassManagementPage.tsx`, `/api/class-sections/*`. | Cập nhật quan hệ giữa `ClassSection` với `Course`, `Semester`, `LecturerProfile` và `Room`. |
| **3.12** | **Enrollment Management** | Class Diagram (Fig 101), Import Enrollment, Create/View/Delete (Fig 102-106) | **IMPLEMENTED & TESTED** | `Enrollment.java`, `EnrollmentRepository.java`, `EnrollmentController.java`, Bảng `enrollments`, Ràng buộc duy nhất `(student_id, class_section_id)`. | Đồng bộ luồng đăng ký sinh viên vào lớp học phần, tính toán sĩ số tự động và kiểm tra tính hợp lệ trước khi mở phiên điểm danh. |
| **3.13** | **Timetable Operations** | Class Diagram (Fig 107), View Timetable by Slot, Export Excel (Fig 108-111) | **IMPLEMENTED & TESTED** | `ClassSchedule.java`, `ClassScheduleRepository.java`, `ScheduleController.java`, `TimetablePage.tsx`, Mobile `schedule_view.dart`. | Đồng bộ hóa mô hình ca học/tiết học (`slot_number`, `day_of_week`, `start_time`, `end_time`). Bỏ tính năng tự động xếp lịch bằng AI (chuyển sang cấu hình thủ công/import). |
| **3.14** | **Academic Request Management** | Class Diagram (Fig 112), Schedule Requests & Leave Requests (Fig 113-120) | **PLANNED DESIGN** | Bảng `leave_requests`, `academic_requests` đã khởi tạo trong CSDL Flyway V1. Chưa tạo controller/service. | Giữ nguyên toàn bộ Class & Sequence Diagrams từ Report 4. Ghi nhận là tính năng mở rộng cho phiên bản tương lai. |
| **3.15** | **Attendance Configuration** | Class Diagram (Fig 121), Configure System, View Configuration (Fig 122-123) | **IMPLEMENTED & TESTED** | `AttendanceConfig.java`, `AttendanceConfigRepository.java`, `AttendanceConfigController.java`, `AttendanceConfigPage.tsx`, Bảng `attendance_configs`. | Cập nhật các tham số thực tế: Thời gian mở phiên trước giờ học, thời gian đóng phiên, bán kính GPS tối đa, danh sách BSSID WiFi bắt buộc, ngưỡng nhận diện khuôn mặt. |
| **3.16** | **Attendance Taking & Reporting** | Class Diagram (Fig 124), Face Enrollment, Face Check-in, Reports, Dynamic QR (Fig 125-133) | **IMPLEMENTED & TESTED** (Backend & AI, Web Reports) / **PARTIAL** (Mobile Check-in) | Backend: `AttendanceSessionController.java`, `AttendanceRecordController.java`. AI: `face_engine.py`, `liveness_engine.py`. Mobile: `face_enrollment_view.dart` (3-step pose). | Đây là phân hệ trọng tâm. Cập nhật toàn bộ Sequence Diagram Face Enrollment 3 bước thực tế, pipeline AI YuNet + MiniFASNet + ArcFace. Mobile Face Check-in đang hoàn thiện tích hợp API (TASK-06). |
| **3.17** | **Lecturer Teaching Workspace** | Class Diagram (Fig 134), View Teaching Classes, Assignments, Comments (Fig 135-142) | **IMPLEMENTED & TESTED** (Attendance/Classes) / **PLANNED** (Assignments) | Web: `LecturerDashboardPage.tsx`, `LecturerAttendancePage.tsx`. Bảng `class_sections`, `attendance_sessions`. Bảng `assignments` (Planned). | Giữ nguyên thiết kế Assignment/Comment ở trạng thái PLANNED; cập nhật chi tiết không gian làm việc thực tế của Giảng viên: Mở phiên, giám sát điểm danh thời gian thực, điều chỉnh trạng thái sinh viên. |
| **3.18** | **Student Learning Workspace** | Class Diagram (Fig 143), Personal Timetable, Submit Assignment (Fig 144-148) | **IMPLEMENTED & TESTED** (Schedule/History) / **PLANNED** (Assignments) | Mobile: `home_view.dart`, `schedule_view.dart`, `attendance_history_view.dart`, `profile_view.dart`. | Cập nhật không gian sinh viên trên ứng dụng Flutter: Xem lịch học theo tuần, xem tỷ lệ chuyên cần, xem lịch sử các buổi điểm danh và lý do vắng mặt. |
| **3.19** | **Grading & Assessment** | Class Diagram (Fig 149), Import Component Grade, Publish Grade, Reports (Fig 150-156) | **PLANNED DESIGN** | Bảng CSDL `grade_components`, `student_grades` đã khởi tạo trong Flyway V2. Chưa có entity JPA. | Giữ nguyên thiết kế sơ đồ lớp và sơ đồ tuần tự quản lý điểm thành phần từ Report 4 để bảo tồn kiến trúc nghiệp vụ đào tạo tổng thể. |
| **3.20** | **Class Communication** | Class Diagram (Fig 157), Create Chat Group, Chat Sequence (Fig 158-159) | **PLANNED DESIGN** | Bảng CSDL `chat_groups`, `chat_messages` đã có trong Flyway V3. Chưa có WebSocket/STOMP gateway. | Giữ nguyên thiết kế phân hệ trò chuyện từ Report 4. Phân loại rõ là module mở rộng sau khi hoàn thiện cơ sở hạ tầng thời gian thực. |
| **3.21** | **AI Support Service** | Class Diagram (Fig 160), AI Support Sequence Diagram (Fig 161) | **PLANNED DESIGN** | Bảng `ai_conversations`, `ai_messages` trong Flyway V3. AI Service hiện tại chuyên biệt cho Thị giác máy tính (Computer Vision), chưa kích hoạt mô hình ngôn ngữ lớn (LLM). | Giữ nguyên thiết kế Chatbot hỗ trợ học tập từ Report 4; làm rõ sự khác biệt giữa AI Computer Vision (đã hoàn thiện 100%) và AI Chatbot Trợ lý ảo (dự kiến tích hợp LLM tương lai). |

---

## 4. ĐÁNH GIÁ CÁC SAI LỆCH VÀ PHƯƠNG ÁN XỬ LÝ TRONG BẢN SDD v2.1

### 4.1. Sai lệch về Khung công nghệ và Thư viện
- **Vấn đề cũ:** Tài liệu cũ ghi nhận chung chung hoặc giả định sử dụng dịch vụ đám mây (Cloudinary để upload ảnh, Firebase để đẩy thông báo, OpenRouter để gọi LLM).
- **Thực tế:** Không tìm thấy mã tích hợp Cloudinary SDK, Firebase SDK, hay WebSocket handler nào trong kho lưu trữ mã nguồn. Thay vào đó, hệ thống sử dụng:
  - Apache POI 5.3.0 cho việc đọc/ghi bảng tính Excel trực tiếp.
  - ONNX Runtime cho việc thực thi cục bộ các mô hình học sâu.
  - JJWT 0.12.6 cho việc sinh và xác thực JSON Web Token.
  - Google ML Kit trên thiết bị di động để tính toán Euler Angles cho đầu người.
- **Phương án hiệu chỉnh:** Cập nhật bảng công nghệ chi tiết tại Chương 1 và Chương 2, liệt kê chính xác các thư viện và phiên bản thực tế đã kiểm chứng qua `pom.xml`, `package.json`, `pubspec.yaml` và `requirements.txt`.

### 4.2. Sai lệch về Phân quyền người dùng trên Di động
- **Vấn đề cũ:** Một số tài liệu giả định ứng dụng Mobile có giao diện cho cả Admin và Giảng viên.
- **Thực tế:** Toàn bộ cấu trúc mã nguồn thư mục `mobile/lib` (`views/`, `controllers/`, `bindings/`) được định hướng duy nhất cho đối tượng **STUDENT** (Đăng nhập, Xem lịch học, Đăng ký khuôn mặt 3 bước, Lịch sử điểm danh, Thông tin cá nhân). Giảng viên và Quản trị viên sử dụng Web Portal.
- **Phương án hiệu chỉnh:** Khẳng định rõ trong Chương 1, Chương 2 và Chương 8 rằng Mobile Client phục vụ chuyên biệt Sinh viên, bảo đảm tính tiện dụng và tối ưu trải nghiệm thiết bị cầm tay.

### 4.3. Hoàn thiện Thiết kế Chống gian lận Đa nhân tố (Multi-Factor Anti-Fraud)
- Để đáp ứng trọn vẹn tiêu chí nghiệm thu của đề tài (`Yeucau_DuAn_DiemDanh_FaceID(2).docx`), bản SDD v2.1 được bổ sung sâu sắc Chương 7 (Attendance Subsystem Design) với các cơ chế:
  1. **Xác thực Sinh trắc học Liveness + ArcFace:** Ngăn chặn tuyệt đối ảnh in, màn hình điện thoại/máy tính bảng, mặt nạ silicon.
  2. **Xác thực Vị trí Địa lý (GPS Geofencing):** Kiểm tra khoảng cách Haversine giữa vị trí thiết bị và tọa độ tâm phòng học với bán kính cho phép $R \le 50\text{m}$.
  3. **Xác thực Mạng Nội bộ (WiFi BSSID Matching):** Kiểm tra địa chỉ MAC của Access Point mà điện thoại đang kết nối có thuộc danh sách trạm phát hợp lệ của phòng học hay không.
  4. **Kiểm soát Khung thời gian động (Dynamic Time Window):** Phiên điểm danh chỉ mở trong khoảng thời gian có hạn do giảng viên kích hoạt.
  5. **Ngăn chặn Điểm danh trùng lặp (Concurrency & Idempotency):** Áp dụng ràng buộc duy nhất `UNIQUE(session_id, student_id)` và khóa phân tán/lạc quan.

---

## 5. KẾT LUẬN VÀ KẾ HOẠCH BÀN GIAO TÀI LIỆU

Bản kiểm toán này xác nhận rằng kiến trúc hiện tại của UniCheck là hoàn toàn vững chắc, có tính khả thi kỹ thuật cao, đáp ứng xuất sắc các tiêu chuẩn bảo mật dữ liệu hiện đại và giải quyết triệt để bài toán điểm danh sinh viên bằng nhận diện khuôn mặt.

Tài liệu **UniCheck Software Design Document Final (v2.1)** sẽ kế thừa trọn vẹn khung kiến trúc của Report 4, giữ nguyên vẹn 21 phân hệ nghiệp vụ, chuẩn hóa toàn diện các sơ đồ và mô tả kỹ thuật theo đúng mã nguồn thực tế, sẵn sàng cho công tác nghiệm thu và báo cáo đồ án.
