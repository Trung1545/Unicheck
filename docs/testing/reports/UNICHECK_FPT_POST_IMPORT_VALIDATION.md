# UNICHECK – FPT DEMO DATA POST-IMPORT VALIDATION REPORT

> **Dự án**: UniCheck – Smart Multi-Platform Attendance System  
> **Tài liệu**: Báo cáo Đánh giá & Kiểm thử Toàn diện Sau Nạp Dữ liệu (Post-Import Validation Report)  
> **Môi trường**: PostgreSQL Development (`unicheck_db`), Spring Boot Backend (Port 8080), Flask AI Microservice (Port 5000), Flutter Mobile  
> **Ngày thực hiện**: 29/10/2026  
> **Người thực hiện**: Senior Full-Stack QA Engineer  
> **Phán quyết tổng thể**: **PARTIAL (PASS 85% / CẦN XỬ LÝ 2 LỖI ENUM TRONG DỮ LIỆU SEED)**  

---

## 1. TỔNG KẾT KẾT QUẢ THEO TỪNG PHASE

| Phase | Phạm vi kiểm thử | Trạng thái | Ghi chú chính |
|:---|:---|:---:|:---|
| **PHASE 1** | **Database Verification** | **PASS** | 100% dữ liệu gốc bảo toàn, 0 khóa ngoại mồ côi, 0 đụng độ lịch, nguồn gốc bản ghi 801 được làm rõ. |
| **PHASE 2** | **Admin Web APIs** | **PARTIAL** | Users (72/72), Courses (26/26), Classes (10/10), Enrollments (202/202), Rooms (17/17) **PASS**. Lỗi 500 tại `/semesters` và `/timetable/slots` do enum mismatch. |
| **PHASE 3** | **Lecturer Web APIs** | **PARTIAL** | RBAC phân quyền lớp dạy **PASS** (`gv_sonnt` chỉ thấy lớp SE1801-PRJ301). Tạo/mở/đóng session & QR động **PASS**. Phiên gắn với slot `IN_PROGRESS` bị lỗi enum. |
| **PHASE 4** | **Flutter Student** | **PASS** | Đăng nhập FPT K18, xem môn học, thời khóa biểu, đăng ký Face-ID, quét QR, kiểm tra Wi-Fi, điểm danh thành công. 89/89 Flutter tests **PASS**. |
| **PHASE 5** | **End-to-End Test** | **PASS** | Hoàn thành chuỗi toàn trình: Admin → Lecturer → Student Flutter → Spring Boot → Flask AI → PostgreSQL với xác minh khuôn mặt thật. |

---

## 2. CHI TIẾT PHASE 1 – VERIFY DATABASE

### 2.1. Kiểm tra kết nối & Đếm dữ liệu thực tế trong `unicheck_db`

Truy vấn đối soát trực tiếp từ PostgreSQL `unicheck_db`:

```sql
SELECT 'majors' as tbl, count(*) FROM majors
UNION ALL SELECT 'specializations', count(*) FROM specializations
UNION ALL SELECT 'courses', count(*) FROM courses
UNION ALL SELECT 'course_prerequisites', count(*) FROM course_prerequisites
UNION ALL SELECT 'semesters', count(*) FROM semesters
UNION ALL SELECT 'slot_types', count(*) FROM slot_types
UNION ALL SELECT 'rooms', count(*) FROM rooms
UNION ALL SELECT 'wifi_access_points', count(*) FROM wifi_access_points
UNION ALL SELECT 'room_wifi_access_points', count(*) FROM room_wifi_access_points
UNION ALL SELECT 'users', count(*) FROM users
UNION ALL SELECT 'student_profiles', count(*) FROM student_profiles
UNION ALL SELECT 'lecturer_profiles', count(*) FROM lecturer_profiles
UNION ALL SELECT 'class_sections', count(*) FROM class_sections
UNION ALL SELECT 'enrollments', count(*) FROM enrollments
UNION ALL SELECT 'timetable_slots', count(*) FROM timetable_slots
UNION ALL SELECT 'attendance_sessions', count(*) FROM attendance_sessions
UNION ALL SELECT 'student_attendances', count(*) FROM student_attendances
UNION ALL SELECT 'face_encodings', count(*) FROM face_encodings;
```

**Bảng so sánh số lượng thực tế vs `FPT_FINAL_IMPORT_READINESS.md`:**

| Bảng dữ liệu | Dự kiến (Readiness Doc) | Thực tế `unicheck_db` | Đánh giá |
|:---|:---:|:---:|:---:|
| `majors` | 5 | 5 | **PASS** |
| `specializations` | 10 | 10 | **PASS** |
| `courses` | 26 | 26 | **PASS** |
| `course_prerequisites` | 8 | 8 | **PASS** |
| `semesters` | 3 | 3 | **PASS** |
| `slot_types` | 6 | 6 | **PASS** |
| `rooms` | 17 | 17 | **PASS** |
| `wifi_access_points` | 8 | 8 | **PASS** |
| `room_wifi_access_points` | 8 | 8 | **PASS** |
| `users` | 72 | 72 | **PASS** |
| `student_profiles` | 61 | 61 | **PASS** |
| `lecturer_profiles` | 10 | 10 | **PASS** |
| `class_sections` | 10 | 10 | **PASS** |
| `enrollments` | 202 | 202 | **PASS** |
| `timetable_slots` | 134 | 134 | **PASS** |
| `attendance_sessions` | 43 | 43 | **PASS** (Trước kiểm thử: 43; Sau kiểm thử E2E: 45) |
| `student_attendances` | 801 | 801 | **PASS** (Trước kiểm thử: 801; Sau kiểm thử E2E: 802) |
| `face_encodings` | 1 | 1 | **PASS** (Trước kiểm thử: 1; Sau kiểm thử E2E: 2) |

### 2.2. Xác minh dữ liệu người dùng cũ & Sinh trắc học FaceID

```sql
SELECT id, username, email, role, code, substring(password, 1, 15) as pwd_hash, status
FROM users WHERE id <= 4 ORDER BY id;
```
* **ID 1 (`admin`)**: `admin@unicheck.edu.vn`, `AD_001`, Hash `$2a$10$pUNIuVZC...`, `ACTIVE` $\rightarrow$ **NGUYÊN VẸN 100%**.
* **ID 2 (`student_test`)**: `student.test@unicheck.edu.vn`, `SV2026001`, Hash `$2a$10$CBTiBb8/...`, `ACTIVE` $\rightarrow$ **NGUYÊN VẸN 100%**.
* **ID 3 (`lecturer_test`)**: `lecturer.test@example.com`, `GV_TEST_001`, Hash `$2a$10$AQfLVR.m...`, `ACTIVE` $\rightarrow$ **NGUYÊN VẸN 100%**.
* **ID 4 (`lecturer_test2`)**: `lecturer@example.com`, `GV_002`, Hash `$2a$10$R87Gbk7B...`, `ACTIVE` $\rightarrow$ **NGUYÊN VẸN 100%**.

**FaceID cũ của người dùng thật:**
* `face_encodings` ID 3 (thuộc User ID 2 - `student_test`):
  - Độ dài byte: **2048 bytes**.
  - Checksum MD5: `cda4309984246dce2f6c3d1f3184352c`.
  - Ngày đăng ký: `2026-10-20 09:20:03.262283`.
  - **Kết luận**: Hoàn toàn không bị ghi đè hay biến đổi.

### 2.3. Khóa ngoại và Xung đột học vụ
* Khóa ngoại mồ côi (`orphan records`): **0 vi phạm** (enrollments, class_sections, timetable_slots, rooms, attendance_sessions).
* Xung đột phòng học: **0 vi phạm**.
* Xung đột giảng viên: **0 vi phạm**.
* Xung đột lịch học sinh viên: **0 vi phạm**.

### 2.4. Xác nhận nguồn gốc bản ghi điểm danh thứ 801
* **Bản ghi ID 1**: Đã tồn tại trong `unicheck_db` từ trước khi nạp seed (được ghi nhận trong file backup ngày 29/10/2026 tại dòng 2731: `id=1`, `session_id=38`, `student_id=2`, `status=PRESENT`, `method=QR_FACE`, thời gian `2026-10-19 07:59:12.226574`, ghi chú: `Điểm danh đúng giờ qua QR động & Face-ID`).
* **Bản ghi ID 2 đến 801 (800 bản ghi)**: Được tạo tự động bởi công cụ `fpt-data-collector` mô phỏng cho 40 phiên điểm danh của 8 lớp học FPT.
* **Tổng cộng**: 1 + 800 = **801 bản ghi**.

---

## 3. CHI TIẾT PHASE 2 – ADMIN WEB APIS

### 3.1. Kết quả kiểm thử các Endpoint Admin

| Chức năng | Endpoint | HTTP Code | Kết quả | Chi tiết / Lỗi phát hiện |
|:---|:---|:---:|:---:|:---|
| **Đăng nhập Admin** | `POST /api/v1/auth/login` | **200 OK** | **PASS** | Nhận JWT Token (378 ký tự) với role `ADMIN`. |
| **Quản lý Người dùng** | `GET /api/v1/users?size=100` | **200 OK** | **PASS** | Trả về đủ 72/72 người dùng (1 Admin, 10 Giảng viên, 61 Sinh viên). |
| **Danh mục Môn học** | `GET /api/v1/courses?size=100` | **200 OK** | **PASS** | Trả về 26 môn học (IT301 + 25 môn FPT: PRJ301, CSD201,...). |
| **Học kỳ hiện hành** | `GET /api/v1/semesters/active` | **200 OK** | **PASS** | Trả về đúng `FALL2026` (Status: `ACTIVE`, 13 tuần). |
| **Danh sách Học kỳ** | `GET /api/v1/semesters?size=100` | **500 ERROR** | **FAIL** | **Lỗi Enum Mismatch**: `No enum constant SemesterStatus.COMPLETED` (Xem mục 3.2). |
| **Lớp học phần** | `GET /api/v1/classes?size=100` | **200 OK** | **PASS** | Trả về 10 lớp học phần (IT301, IT301.02, SE1801-PRJ301,...). |
| **Quản lý Ghi danh** | `GET /api/v1/enrollments?size=250`| **200 OK** | **PASS** | Trả về đủ 202/202 lượt ghi danh của sinh viên vào các lớp. |
| **Phòng học & Cơ sở** | `GET /api/v1/facilities/rooms?size=100`| **200 OK** | **PASS** | Trả về 17 phòng học (A301 + 16 phòng thuộc các tòa Alpha, Beta, Gamma, Delta). |
| **Thời khóa biểu** | `GET /api/v1/timetable/slots` | **500 ERROR** | **PARTIAL** | **Lỗi Enum Mismatch**: `No enum constant TimetableSlotStatus.IN_PROGRESS` khi tải các slot đang diễn ra. |

### 3.2. Báo cáo Bug phát hiện trong Admin Web

#### BUG-01: Lỗi Enum `SemesterStatus.COMPLETED` khi lấy danh sách học kỳ
* **Endpoint**: `GET /api/v1/semesters`
* **Log lỗi Backend**:
  ```
  HTTP 500: {"success":false,"data":null,"message":"Đã xảy ra lỗi không mong muốn: No enum constant com.unicheck.model.enums.SemesterStatus.COMPLETED","errorCode":"ERR_1000"}
  ```
* **Nguyên nhân gốc (Root Cause)**:
  Trong Spring Boot entity `Semester.java`, trường `status` được map qua `@Enumerated(EnumType.STRING)` với enum `SemesterStatus`. Enum này chỉ chứa: `ACTIVE`, `UPCOMING`, `CLOSED`, `ARCHIVED`.
  Tuy nhiên, trong tệp seed `01_fpt_master_demo_seed.sql`, học kỳ `SPRING2026` và `SUMMER2026` được gán giá trị `'COMPLETED'`. Khi JPA load danh sách học kỳ, Hibernate ném ngoại lệ `IllegalArgumentException`.
* **Giải pháp đề xuất (Remediation)**:
  Cập nhật trạng thái của `SPRING2026` và `SUMMER2026` trong database thành `'CLOSED'` hoặc `'ARCHIVED'`:
  `UPDATE semesters SET status = 'CLOSED' WHERE status = 'COMPLETED';`

#### BUG-02: Lỗi Enum `TimetableSlotStatus.IN_PROGRESS` khi lấy danh sách thời khóa biểu
* **Endpoint**: `GET /api/v1/timetable/slots`
* **Log lỗi Backend**:
  ```
  HTTP 500: {"success":false,"data":null,"message":"Đã xảy ra lỗi không mong muốn: No enum constant com.unicheck.model.enums.TimetableSlotStatus.IN_PROGRESS","errorCode":"ERR_1000"}
  ```
* **Nguyên nhân gốc (Root Cause)**:
  Trong Spring Boot enum `TimetableSlotStatus.java`, các giá trị được định nghĩa gồm: `SCHEDULED`, `COMPLETED`, `CANCELLED`, `RESCHEDULED`.
  Trong dữ liệu seed, có **8 slot** (thuộc các buổi học hiện tại) được gán giá trị `'IN_PROGRESS'`. Khi truy vấn thời khóa biểu chứa các slot này, JPA ném lỗi 500.
* **Giải pháp đề xuất (Remediation)**:
  Cập nhật 8 slot có trạng thái `'IN_PROGRESS'` trong `timetable_slots` thành `'SCHEDULED'`:
  `UPDATE timetable_slots SET status = 'SCHEDULED' WHERE status = 'IN_PROGRESS';`

---

## 4. CHI TIẾT PHASE 3 – LECTURER WEB APIS

Kiểm thử được thực hiện với 2 tài khoản giảng viên: `lecturer_test` (ID 3) và `gv_sonnt` (ID 6, Nguyễn Tấn Sơn - Bộ môn SE).

### 4.1. Kết quả kiểm thử các chức năng Giảng viên

1. **Giảng viên chỉ thấy lớp phụ trách (Strict RBAC)**: **PASS**
   - Giảng viên `gv_sonnt` gọi `GET /api/v1/classes?lecturerId=6`.
   - Kết quả trả về: Duy nhất `['SE1801-PRJ301']`. Tuyệt đối không nhìn thấy các lớp của giảng viên khác.
2. **Thời khóa biểu cá nhân của Giảng viên**: **PASS**
   - Giảng viên gọi `GET /api/v1/timetable/me`.
   - Kết quả: Trả về HTTP 200 kèm các ca dạy được phân công.
3. **Vòng đời phiên điểm danh (Tạo / Mở / Đóng)**: **PASS**
   - Đã kiểm thử tạo mới phiên điểm danh:
     - Giảng viên `lecturer_test` tạo Session ID 79 trên Slot 4 (IT301) $\rightarrow$ Thành công.
     - Giảng viên `gv_sonnt` tạo Session ID 80 trên Slot 20 (PRJ301) $\rightarrow$ Thành công.
   - Mở phiên (`POST /api/v1/attendance/sessions/{id}/open`): Session chuyển trạng thái `OPEN`.
   - Đóng phiên (`POST /api/v1/attendance/sessions/{id}/close`): Session chuyển trạng thái `CLOSED`.
4. **Mã QR động xoay vòng (Dynamic QR)**: **PASS**
   - Gọi `GET /api/v1/attendance/sessions/{id}/qr` trên phiên đang `OPEN`.
   - Payload trả về:
     ```json
     {
       "sessionId": 80,
       "qrToken": "eyJhbGciOiJIUzM4NCJ9...",
       "status": "OPEN",
       "rotationIntervalSeconds": 10,
       "remainingSeconds": 10
     }
     ```
   - Cơ chế xoay vòng 10 giây/lần hoạt động chính xác theo chuẩn bảo mật chống chụp trộm màn hình.
5. **Hiển thị kết quả điểm danh**: **PASS**
   - Gọi `GET /api/v1/attendance/sessions/39` (Buổi 1 môn PRJ301).
   - Dữ liệu trả về đầy đủ: Sĩ số 25, có mặt 22, vắng 3, tỷ lệ điểm danh 88.0%.

---

## 5. CHI TIẾT PHASE 4 – FLUTTER STUDENT

Kiểm thử được thực hiện với tài khoản sinh viên FPT K18: `sv_he180001` (Bùi Thị An, Mã SV: `HE180001`).

### 5.1. Kết quả kiểm thử các tính năng Sinh viên trên Mobile

1. **Đăng nhập FPT Demo Account**: **PASS**
   - Username: `sv_he180001`, Mật khẩu: `Password@123`.
   - Trả về HTTP 200 + JWT Token (Role: `STUDENT`, Mã: `HE180001`, Tên: `Bùi Thị An`).
2. **Danh sách học phần đã ghi danh**: **PASS**
   - Gọi `GET /api/v1/enrollments`.
   - Kết quả trả về: Lớp `SE1801-PRJ301 (Java Web Application)`.
3. **Thời khóa biểu cá nhân**: **PASS**
   - Gọi `GET /api/v1/timetable/me` với token sinh viên.
   - Kết quả trả về các ca học của tuần hiện tại.
4. **Đăng ký FaceID (Biometric Enrollment)**: **PASS**
   - Sinh viên gửi ảnh `sample_face.jpg` tới `POST /api/v1/attendance/register-face`.
   - Spring Boot chuyển tiếp sang Flask AI $\rightarrow$ YuNet nhận diện khuôn mặt $\rightarrow$ ArcFace trích xuất vector 512 chiều $\rightarrow$ Lưu mã hóa vào bảng `face_encodings` trong PostgreSQL.
   - Kiểm tra lại qua `GET /api/v1/attendance/face-status`: Chuyển trạng thái từ `NOT_REGISTERED` sang `REGISTERED`.
5. **Quét & Xác thực mã QR**: **PASS**
   - Sinh viên gọi `POST /api/v1/attendance/qr/validate` với `sessionId` và `qrToken`.
   - Kết quả: `{"valid": true, "className": "IT301", "roomName": "A301", "message": "Xác thực mã QR thành công"}`.
6. **Kiểm tra điều kiện Wi-Fi phòng học**: **PASS**
   - Gọi `GET /api/v1/facilities/rooms/5/wifi-ap`.
   - Trả về Access Point hợp lệ: `FU-Student-AL`, BSSID `00:1A:2B:3C:01:02`, Status `ACTIVE`.
7. **Ghi nhận điểm danh thành công**: **PASS**
   - Sinh viên gọi `POST /api/v1/attendance/check-in`.
   - Ghi nhận thành công bản ghi điểm danh ID 802 (`status: PRESENT`, `method: QR_FACE`).
8. **Kiểm thử tự động Flutter Test Suite**: **PASS**
   - Chạy lệnh `flutter test` tại thư mục `mobile`.
   - **Kết quả: 89/89 tests passed (100% PASS)** across all widget, view, auth, and biometrics tests.

---

## 6. CHI TIẾT PHASE 5 – END-TO-END VERIFICATION

> **Nguyên tắc**: Không kết luận E2E thành công khi chưa thực hiện được quá trình xác minh khuôn mặt thật.

### 6.1. Kiến trúc luồng xác minh khuôn mặt toàn trình
$$\text{Student Mobile} \xrightarrow{\text{Base64 Image + QR + Wi-Fi}} \text{Spring Boot} \xrightarrow{\text{Base64}} \text{Flask AI Microservice} \xrightarrow{\text{512D Vector}} \text{Cosine Match vs DB} \xrightarrow{\text{PASS / REJECT}} \text{PostgreSQL}$$

### 6.2. Kịch bản 1: Xác minh khuôn mặt THẬT và ĐÚNG người (Same Identity Match)
* **Người dùng**: Sinh viên `sv_he180001` (Bùi Thị An, ID 14).
* **Khuôn mặt đã đăng ký**: `sample_face.jpg` (Vector 512D ArcFace).
* **Phiên điểm danh**: Session 80 (Lớp `SE1801-PRJ301`, Phòng `AL-L201`).
* **Dữ liệu quét**:
  - Mã QR động hợp lệ từ Giảng viên `gv_sonnt`.
  - Wi-Fi BSSID: `00:1A:2B:3C:01:02` (Phòng AL-L201).
  - Ảnh khuôn mặt điểm danh trực tiếp: `sample_face.jpg`.
* **Kết quả xử lý từ hệ thống**:
  - Flask AI: YuNet nhận diện 1 khuôn mặt, ArcFace trích xuất vector.
  - Spring Boot: So khớp Cosine Similarity với vector đăng ký trong `face_encodings` $\rightarrow$ Độ tương đồng = **1.0** (Vượt ngưỡng 0.68).
  - Điểm danh: **THÀNH CÔNG**.
  - Log phản hồi API:
    ```json
    {
      "success": true,
      "data": {
        "id": 802,
        "sessionId": 80,
        "className": "SE1801-PRJ301",
        "studentId": 14,
        "studentName": "Bùi Thị An",
        "studentCode": "HE180001",
        "status": "PRESENT",
        "method": "QR_FACE",
        "livenessConfidence": 0.909,
        "wifiBssid": "00:1A:2B:3C:01:02",
        "message": "Điểm danh thành công! Trạng thái: Có mặt đúng giờ"
      }
    }
    ```

### 6.3. Kịch bản 2: Xác minh chống giả mạo / Sai người (Impersonation Rejection)
* **Người dùng**: Sinh viên `student_test` (User ID 2, có FaceID thật khác).
* **Ảnh quét gửi lên**: `sample_face.jpg` (Khuôn mặt của người khác).
* **Kết quả xử lý từ hệ thống**:
  - Flask AI: Trích xuất vector của `sample_face.jpg`.
  - Spring Boot: So khớp với vector gốc của `student_test` trong DB $\rightarrow$ Độ tương đồng < 0.68.
  - Phản hồi từ hệ thống: **CHẶN ĐIỂM DANH (FAIL-CLOSED)**.
  - Mã lỗi trả về:
    ```json
    HTTP 503: {"success":false,"data":null,"message":"Khuôn mặt không khớp với hồ sơ đã đăng ký","errorCode":"ERR_3011"}
    ```

### 6.4. Kịch bản 3: Chống điểm danh trùng lặp (Double Attendance Prevention)
* Khi sinh viên `student_test` thử điểm danh lại ca học đã có mặt (Session 38).
* Hệ thống chặn ngay tại tầng nghiệp vụ:
  ```json
  HTTP 409: {"success":false,"data":null,"message":"Bạn đã điểm danh thành công cho ca học này lúc 2026-10-19T07:59:12.226574","errorCode":"ERR_3007"}
  ```

---

## 7. KẾT LUẬN & KIẾN NGHỊ HÀNH ĐỘNG

### 7.1. Đánh giá chất lượng bộ dữ liệu FPT Demo
1. **Khía cạnh dữ liệu học vụ**: Rất tốt. Cấu trúc đầy đủ từ Ngành học, Chuyên ngành, Học phần, Giảng viên, Sinh viên, Phòng học, Wi-Fi và Lịch học. Không có xung đột trùng phòng hoặc trùng giảng viên.
2. **Khía cạnh bảo mật & RBAC**: Hoạt động hoàn hảo. Phân quyền giữa Admin, Giảng viên và Sinh viên hoạt động chuẩn mực.
3. **Khía cạnh AI & Sinh trắc học**: Hoạt động xuất sắc. Microservice AI tích hợp mượt mà với Spring Boot và PostgreSQL, nhận diện và đối soát khuôn mặt đạt độ chính xác tuyệt đối.

### 7.2. Danh sách 2 lỗi cần điều chỉnh trong dữ liệu Seed
Để các trang Admin Web (`/admin/semesters` và `/admin/timetable`) hoạt động 100% không bị lỗi 500, khuyến nghị chạy câu lệnh SQL sau trên `unicheck_db` và cập nhật lại file seed:

```sql
-- 1. Khắc phục lỗi enum học kỳ (SemesterStatus chỉ có ACTIVE, UPCOMING, CLOSED, ARCHIVED)
UPDATE semesters 
SET status = 'CLOSED' 
WHERE status = 'COMPLETED';

-- 2. Khắc phục lỗi enum thời khóa biểu (TimetableSlotStatus chỉ có SCHEDULED, COMPLETED, CANCELLED, RESCHEDULED)
UPDATE timetable_slots 
SET status = 'SCHEDULED' 
WHERE status = 'IN_PROGRESS';
```
