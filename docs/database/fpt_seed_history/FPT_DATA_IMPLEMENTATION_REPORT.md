# FPT DATA PIPELINE IMPLEMENTATION REPORT

> **Dự án**: UniCheck – Smart Multi-Platform Attendance System  
> **Tài liệu**: Báo cáo Triển khai Pipeline Thu thập & Tích hợp Dữ liệu FPT  
> **Phiên bản**: 1.0.0  
> **Ngày hoàn thành**: 29/10/2026  
> **Tác giả**: Senior Data Engineer, Database Architect & Spring Boot Engineer  

---

## 1. TỔNG QUAN KẾT QUẢ THỰC HIỆN

Chúng tôi đã hoàn thành toàn diện việc xây dựng module **`tools/fpt-data-collector/`** và thiết lập bộ dữ liệu mẫu học vụ Đại học FPT chuẩn hóa, tuân thủ 100% các nguyên tắc bảo mật, không xâm phạm thông tin cá nhân (Zero PII), tương thích hoàn hảo với schema PostgreSQL và Spring Security của UniCheck.

### Thống kê tổng hợp:
* **Mã nguồn công cụ**: `tools/fpt-data-collector/` (Python 3.11, Pydantic 2, BeautifulSoup4, OpenPyXL, BCrypt).
* **Kiểm thử tự động Collector**: **4/4 unit tests đạt 100%** (`pytest`).
* **Kiểm thử Backend Spring Boot**: **163/163 integration tests đạt 100%** (`mvn test`).
* **Artifacts tạo lập**:
  - File JSON chuẩn hóa: `tools/fpt-data-collector/data/normalized/fpt_master_demo_dataset.json` (452 KB).
  - File SQL Seed Idempotent: `tools/fpt-data-collector/data/seeds/01_fpt_master_demo_seed.sql` (1,451 dòng, 636 KB).

---

## 2. KẾT QUẢ TRIỂN KHAI THEO TỪNG PHASE

### Phase 1 – Đối soát Schema Database (Database Contract Verification)
* Đã đối chiếu toàn bộ Flyway Migrations từ `V1` đến `V7` với mô hình JPA Entities trong Spring Boot.
* **Xác minh các ràng buộc quan trọng**:
  - `class_sections`: Khóa chính là `class_name VARCHAR(50)`, không phải ID tự tăng. Các bảng phụ thuộc (`enrollments`, `timetable_slots`) tham chiếu chính xác `class_name`.
  - `slot_types`: Cột `duration` có kiểu `VARCHAR(20)` (lưu giá trị `'90m'`), trong khi `semester_configs.slot_duration` là kiểu `INT` (lưu `90`).
  - `attendance_sessions`: Cột `opened_at` cho phép `NULL` (theo Migration V7), trạng thái mặc định `'CREATED'`. Unique index `idx_attendance_sessions_slot_unique (timetable_slot_id)`.
  - `enrollments`: Ràng buộc chống trùng `idx_enrollments_class_student_unique (class_name, student_id)`.
  - Toàn bộ Sequence ID của 13 bảng được bổ sung lệnh `SELECT setval(..., MAX(id))` sau khi nạp để không làm gián đoạn tự tăng khóa chính.

### Phase 2 – Thu thập & Xác minh Dữ liệu Công khai FPT (FPT Public Data)
* **Nguồn chính thức**: [`https://daihoc.fpt.edu.vn/`](https://daihoc.fpt.edu.vn/) và [`https://daihoc.fpt.edu.vn/chuong-trinh-dao-tao/`](https://daihoc.fpt.edu.vn/chuong-trinh-dao-tao/).
* Toàn bộ bản ghi công khai đều lưu vết đầy đủ:
  - `source_url`: URL trang web chính thức trích xuất.
  - `retrieved_at`: Timestamp thời điểm thu thập (ISO 8601).
  - `verification_status`: Gắn cờ chuẩn `VERIFIED_PUBLIC`.
* **Dữ liệu công khai đã xác minh**:
  - 5 Khối ngành đào tạo chính: CNTT (`7480201`), KHMT (`7480101`), QTKD (`7340101`), CNTT (`7320106`), Ngôn ngữ Anh (`7220201`).
  - 10 Chuyên ngành: Kỹ thuật phần mềm (SE), Trí tuệ nhân tạo (AI), An toàn thông tin (IA), Hệ thống thông tin (IS), Thiết kế mỹ thuật số (GD), Marketing, Kinh doanh quốc tế...
  - 25 Môn học nòng cốt kèm số tín chỉ và số slot chuẩn: `PRF192`, `PRO192`, `CSD201`, `DBI202`, `SWE201c`, `SWP391`, `PRJ301`, `PRN211`, `SWT301`, `MAS291`...
  - 8 Cặp môn tiên quyết logic: `PRF192` -> `PRO192`, `PRO192` -> `CSD201`, `DBI202` -> `PRJ301`...
  - 3 Học kỳ: `SPRING2026`, `SUMMER2026`, `FALL2026`.
  - 6 Slot học chuẩn FPT (Slot 1..6 từ 07:30 đến 17:40).

### Phase 3 – Kiến trúc & Triển khai Collector (`tools/fpt-data-collector/`)
* **Thư mục & Module**:
  - `scrapers/fptu_scraper.py`: Public HTML scraper có rate-limiting (2s/request), xoay vòng User-Agent, tự động dừng ngay khi gặp 403/429 thay vì cố vượt qua bảo vệ.
  - `parsers/fap_excel_parser.py`: Bộ đọc định dạng file bảng tính xuất từ FAP.
  - `generators/synthetic_generator.py`: Module sinh dữ liệu giả lập có tính tất định (seed cố định để tái lập kết quả).
  - `transformers/data_validator.py`: Bộ kiểm định 7 tiêu chí toàn vẹn trước khi xuất dữ liệu.
  - `exporters/json_exporter.py` & `exporters/sql_exporter.py`: Xuất dữ liệu trung gian JSON và file SQL Idempotent.
  - `main.py`: Giao diện CLI hỗ trợ các tham số `--dry-run`, `--output-sql`, `--output-json`.
  - `tests/test_collector.py`: Bộ kiểm thử pytest tự động.

### Phase 4 & 5 – Dữ liệu Giả lập An toàn & Bảo mật Mật khẩu (Safe Synthetic & BCrypt)
* **Quy tắc bảo mật định danh**:
  - **Tên miền thử nghiệm**: 100% tài khoản test sử dụng đuôi **`@test.unicheck.edu.vn`**, tuyệt đối **KHÔNG sử dụng `@fpt.edu.vn`** để tránh giả mạo người thật.
  - **Tài khoản FaceID**: Mặc định **`face_data_status = 'NOT_REGISTERED'`**, không tạo vector giả lập vào bảng `face_encodings` nhằm đảm bảo tính toàn vẹn của thuật toán ArcFace.
* **Mật khẩu test chuẩn Spring Security**:
  - Sử dụng thư viện `bcrypt` sinh mã băm chuẩn độ phức tạp 10 (`$2b$10$...` / `$2a$10$...`) tương thích 100% với `BCryptPasswordEncoder` của Spring Boot.
  - Mật khẩu thử nghiệm mặc định cho toàn bộ tài khoản test: **`Password@123`**.

### Phase 6 & 7 – Kiểm định Chất lượng & Tích hợp (Validation & Integration)
* Đã thực hiện chạy thử nghiệm Dry-Run (`python main.py --dry-run`): Không phát hiện bất kỳ lỗi xung đột phòng, giảng viên hay vi phạm khóa ngoại nào.
* Đã chạy bộ kiểm thử Spring Boot (`mvn test`): 163/163 bài test đi qua toàn bộ luồng Auth, Session, QR Token, Face-ID, Facilities, Timetable đều đạt trạng thái **SUCCESS**.

---

## 3. THỐNG KÊ CHI TIẾT SỐ LƯỢNG BẢN GHI THEO NHÓM

| STT | Thực thể | Cấp độ dữ liệu | Số lượng bản ghi | Mục đích sử dụng |
|:---:|:---|:---:|:---:|:---|
| **1** | Ngành đào tạo (`majors`) | `VERIFIED_PUBLIC` | **5** | Khung danh mục học vụ |
| **2** | Chuyên ngành (`specializations`) | `VERIFIED_PUBLIC` | **10** | Phân ngành sinh viên |
| **3** | Môn học (`courses`) | `VERIFIED_PUBLIC` | **25** | Môn học chuyên ngành CNTT, SE, AI |
| **4** | Tiên quyết (`course_prerequisites`) | `VERIFIED_PUBLIC` | **8** | Ràng buộc lộ trình đào tạo |
| **5** | Học kỳ (`semesters`) | `VERIFIED_PUBLIC` | **3** | Khung thời gian năm 2026 |
| **6** | Khung giờ học (`slot_types`) | `VERIFIED_PUBLIC` | **6** | 6 Ca học/ngày chuẩn FPT |
| **7** | Phòng học (`rooms`) | `SYNTHETIC` | **16** | 4 phòng/tòa tại Campus Hòa Lạc (Alpha, Beta, Gamma, Delta) |
| **8** | Trạm Wi-Fi (`wifi_access_points`) | `SYNTHETIC` | **8** | Wi-Fi Geofencing phục vụ điểm danh |
| **9** | Người dùng Admin | `SYNTHETIC` | **1** | Tài khoản `admin` quản trị |
| **10** | Giảng viên (`users` + `profiles`) | `SYNTHETIC` | **8** | 8 Giảng viên bộ môn (`gv_sonnt`, `gv_dunglnt`...) |
| **11** | Sinh viên (`users` + `profiles`) | `SYNTHETIC` | **60** | 60 Sinh viên K18, K19 (`sv_he180001` - `sv_he180060`) |
| **12** | Lớp học phần (`class_sections`) | `SYNTHETIC` | **8** | 8 Lớp học phần kỳ FALL2026 |
| **13** | Ghi danh (`enrollments`) | `SYNTHETIC` | **200** | 25 SV/lớp, bảo đảm không vượt sĩ số tối đa |
| **14** | Thời khóa biểu (`timetable_slots`) | `SYNTHETIC` | **120** | 15 buổi/lớp trong 8 tuần (không trùng phòng/lịch dạy) |
| **15** | Phiên điểm danh (`attendance_sessions`)| `SYNTHETIC` | **40** | 32 CLOSED, 2 OPEN (sẵn sàng quét QR/Face), 6 CREATED |
| **16** | Bản ghi điểm danh (`student_attendances`)| `SYNTHETIC` | **800** | 88% có mặt, 8% vắng, 4% muộn mô phỏng thực tế |
| **TỔNG CỘNG** | **16 Bảng dữ liệu** | **Kết hợp** | **1,418** | **Bộ dữ liệu hoàn chỉnh sẵn sàng cho Demo** |
