# UniCheck — Lộ Trình Triển Khai Thực Tế Đến 07/11/2026 (Execution Roadmap)

> **Mã tài liệu:** IMPL-EXECUTION-ROADMAP-2026  
> **Thời hạn nghiệm thu (Deadline):** **07/11/2026** (23 ngày làm việc)  
> **Nguyên tắc phân bổ:** Chia thành các lát cắt dọc khép kín (Vertical Slices), ưu tiên mở khóa các tính năng cốt lõi trước, kế thừa 100% mã nguồn đã `DONE`, không code lại các phần đã hoạt động.

---

## 1. Biểu Đồ Gantt Tổng Quan Lộ Trình (13 Vertical Slices)

```mermaid
gantt
    title UniCheck Execution Roadmap (15/10/2026 - 07/11/2026)
    dateFormat  YYYY-MM-DD
    section Phase 1: Nền Tảng Quản Trị & Học Vụ
    Slice 1: User Management React             :done, s1, 2026-10-16, 3d
    Slice 2: Academic Core Tối Thiểu            :s2, after s1, 3d
    section Phase 2: Lõi AI & Sinh Trắc Học
    Slice 3: Real AI Face Recognition Engine    :s3, after s2, 2d
    Slice 4: Face Enrollment Pipeline           :s4, after s3, 2d
    Slice 8: Liveness Detection (MiniFASNet)    :s8, after s4, 2d
    section Phase 3: Điểm Danh Đa Yếu Tố & Realtime
    Slice 5: Attendance Session Core            :s5, after s4, 2d
    Slice 6: Dynamic QR Token Engine            :s6, after s5, 1d
    Slice 7: Mobile Native Check-in (Flutter)   :s7, after s6, 3d
    Slice 10: Live Monitoring & WebSocket       :s10, after s7, 2d
    section Phase 4: Báo Cáo & Vận Hành Hoàn Thiện
    Slice 9: Attendance History & Audit Logs    :s9, after s10, 2d
    Slice 11: Statistics & Excel Export         :s11, after s9, 2d
    Slice 12: Remaining Stitch Screens (Requests/Grades):s12, after s11, 2d
    Slice 13: End-to-End QA, Load Test & Demo   :s13, after s12, 2d
```

---

## 2. Chi Tiết Lộ Trình Theo Từng Lát Cắt Dọc (Vertical Slice Breakdown)

---

### Vertical Slice 1: User Management React (16/10 - 18/10) — Ưu Tiên P0
* **Mục tiêu:** Kết nối hoàn chỉnh giao diện Web React vào [UserController.java](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/controller/UserController.java) (đã có 8 endpoints `ACTIVE`).
* **Màn hình Stitch:**
  - `21275607791c43e58ee6a5b2db656d20` (UniCheck - Quản lý người dùng).
  - `8e1010eda64348f98bd95f7c01648bef` (UniCheck - Quản lý sinh viên).
  - `3c68af65d6ae4a0f9509aed6e9ea81be` (UniCheck - Quản lý giảng viên).
* **Kết quả bàn giao:** Bảng danh sách phân trang, tìm kiếm, lọc theo vai trò/khoa/trạng thái, khóa tài khoản, form thêm mới người dùng và import CSV/Excel danh sách sinh viên.

---

### Vertical Slice 2: Academic Core Tối Thiểu (19/10 - 21/10) — Ưu Tiên P0
* **Mục tiêu:** Khai báo JPA Entities và REST APIs tương ứng với các bảng Flyway V1 & V3 đã có: `semesters`, `courses`, `rooms`, `wifi_access_points`, `room_wifi_access_points`, `class_sections`, `timetable_slots`, `enrollments`.
* **Màn hình Stitch:**
  - `a9f520acd00440c8a26633aec9a8799c` (Danh mục học phần).
  - `495a21f075ca479698f5f5075cee8a41` (Quản lý lớp học phần).
  - `4f0245590b1b4c6ab231b412b5ba845d` (Học kỳ & Niên khóa).
  - `e796d9e992364bfcbf8a32a6330927ce` (Phòng học & Wi-Fi AP).
* **Kết quả bàn giao:** Quản lý dữ liệu nền tảng phục vụ xếp lịch và tạo phiên điểm danh.

---

### Vertical Slice 3: Real AI Face Recognition Engine (22/10 - 23/10) — Ưu Tiên P0
* **Mục tiêu:** Thay thế stub mock `[0.0] * 128` trong `ai-service/app.py` bằng mô hình ONNX Runtime nhẹ (ArcFace / MobileFaceNet 512-dim).
* **Nhiệm vụ:**
  - Tải pre-trained weights ONNX cho Face Detection (SCRFD) và Feature Extraction (ArcFace).
  - Xử lý pipeline: Phát hiện mặt -> Căn chỉnh (Alignment) -> Chuẩn hóa L2 -> Trích xuất vector 512-dim.
  - Cấu hình động ngưỡng Cosine Similarity (`AI_FACE_MATCH_THRESHOLD`) trong `application.yml` và bảng `attendance_configs`, tránh hardcode cố định.

---

### Vertical Slice 4: Face Enrollment Pipeline (24/10 - 25/10) — Ưu Tiên P0
* **Mục tiêu:** Hoàn thiện luồng đăng ký khuôn mặt ban đầu cho sinh viên.
* **Màn hình Stitch:** `a17db05b39144990b49bee366c1e3b43` (UniCheck Sinh viên - Đăng ký & Cập nhật Face-ID).
* **Nhiệm vụ Backend:** Tạo `FaceRecognitionService.java`, endpoint `POST /api/v1/attendance/register-face` lưu vector vào bảng `face_encodings` và cập nhật `users.face_data_status = 'REGISTERED'`.

---

### Vertical Slice 5: Attendance Session Core (26/10 - 27/10) — Ưu Tiên P0
* **Mục tiêu:** Logic quản lý phiên điểm danh của Giảng viên.
* **Màn hình Stitch:** `4f83098c7b904d4389563c28f54e1c48` (Quản lý phiên điểm danh) & `bd31d3594ab14b2b87223f9134cf0982` (Lớp học phần phụ trách).
* **Backend:** `AttendanceSessionService.java` xử lý mở phiên (dựa trên ca học `timetable_slots`), thiết lập thời gian cho phép check-in trễ, đóng phiên.

---

### Vertical Slice 6: Dynamic QR Code Token Engine (28/10) — Ưu Tiên P0
* **Mục tiêu:** Chống gian lận chụp ảnh QR gửi ra bên ngoài bằng mã động xoay vòng mỗi 5-10 giây.
* **Màn hình Stitch:** `5c0df9af4d2545919e8f774c1159e7da` (UniCheck Giảng viên - Khởi tạo phiên & QR động).
* **Backend:** Thuật toán TOTP HMAC-SHA256 có thời hạn (TTL 10s) kết hợp Redis/In-memory Cache.

---

### Vertical Slice 7: Mobile Native Check-in Flow (29/10 - 31/10) — Ưu Tiên P0
* **Mục tiêu:** Hiện thực hóa camera native, quét QR và xác thực vị trí trên Flutter App.
* **Nhiệm vụ:**
  - Thêm plugins: `camera`, `google_mlkit_face_detection`, `mobile_scanner`, `network_info_plus`, `geolocator`.
  - Xây dựng camera preview với khung Oval viền xanh hướng dẫn căn chỉnh khuôn mặt.
  - Quét QR động -> Lấy BSSID Wi-Fi hiện tại -> Chụp ảnh selfie -> Gửi payload `POST /api/v1/attendance/check-in`.

---

### Vertical Slice 8: Liveness Detection Anti-Spoofing (01/11 - 02/11) — Ưu Tiên P1
* **Mục tiêu:** Chống giả mạo bằng ảnh chụp màn hình điện thoại hoặc ảnh in giấy.
* **Nhiệm vụ:** Tích hợp mô hình `MiniFASNet` tại `ai-service/app.py`, phân tích texture và moiré patterns, kết hợp challenge chớp mắt (Blink Detection) on-device trên Flutter qua Google ML Kit.

---

### Vertical Slice 9: Attendance History & Audit Trail (03/11) — Ưu Tiên P1
* **Màn hình Stitch:**
  - `9ba51f6ecd70421582816363439f4530` (Sinh viên - Lịch sử điểm danh).
  - `dbeb7a8d359c4fbaa1363673ceac548e` (Giảng viên - Báo cáo & Lịch sử điểm danh).
  - `769ce5a775bd429cb46ee5e447868e98` (Lịch sử điểm danh toàn trường).
  - `6dd3388036ab44f5bf221a5f6e7f24e0` (Nhật ký kiểm toán).

---

### Vertical Slice 10: Live Monitoring & WebSocket Console (04/11) — Ưu Tiên P1
* **Mục tiêu:** Cập nhật tức thì danh sách sinh viên check-in lên máy chiếu giảng đường.
* **Màn hình Stitch:** `c20e515d6d0940379d90ea268522b07e` (Giảng viên - Giám sát điểm danh trực tiếp) & `dd2b950932464528a607e4ebd490f5e1` (Cảnh báo an ninh).
* **Công nghệ:** Spring Boot WebSocket STOMP (`/topic/session.{id}`).

---

### Vertical Slice 11: Statistics & Excel Export (05/11) — Ưu Tiên P1
* **Mục tiêu:** Thống kê chuyên cần và xuất biên bản điểm danh.
* **Màn hình Stitch:** `c9523d6727af4088a7135067d379c570` (Báo cáo & Thống kê chuyên cần).
* **Backend:** Apache POI xuất báo cáo dạng file `.xlsx` theo chuẩn mẫu Bộ Giáo dục và Đào tạo.

---

### Vertical Slice 12: Remaining Stitch Screens (06/11) — Ưu Tiên P2
* **Màn hình Stitch:**
  - Đơn từ học vụ: `f3fad431243448f4a7758c9ced16b695` (Duyệt đơn) & `c7ac82956cfe41b3b762e7aaabc2bcfa` (Gửi đơn).
  - Sổ điểm: `ef5d3e2ef1f14d349f4f732efcee4e55`.
  - Bài tập: `0d390145e7e14c498c170acf8ed21778`.
  - Thông báo: `ef7e12816fa44ec387f5b605b9df08ff`.
  - Cấu hình hệ thống: `300c3071598340e5981a9a5f5097f909`.

---

### Vertical Slice 13: End-to-End QA, Load Test & Demo (07/11) — Nghiệm Thu
* **Nhiệm vụ:**
  - Chạy toàn bộ test suites (Backend JUnit, Frontend Vitest, Mobile Flutter test).
  - Kiểm thử tải (Load test) mô phỏng 500 sinh viên check-in đồng thời bằng Locust.
  - Đóng gói Docker Compose hoàn chỉnh và bàn giao hệ thống.
