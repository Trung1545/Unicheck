# FPT DATA COLLECTION & PIPELINE ARCHITECTURE PLAN

> **Dự án**: UniCheck – Smart Multi-Platform Attendance System  
> **Tài liệu**: Kế hoạch Thu thập & Kiến trúc Pipeline Dữ liệu FPT  
> **Thư mục công cụ**: `tools/fpt-data-collector/`  
> **Phiên bản**: 1.0.0  
> **Ngày lập**: 29/10/2026  

---

## 1. MỤC TIÊU & NGUYÊN TẮC THIẾT KẾ

Module `tools/fpt-data-collector` được thiết kế như một **Data Engineering Tool** chuyên biệt bằng Python 3, phục vụ mục đích:
1. Thu thập dữ liệu chương trình đào tạo, ngành, chuyên ngành, môn học từ các nguồn web công khai hợp lệ của Đại học FPT.
2. Xử lý và đọc các file xuất học vụ (Excel/CSV) chuẩn FAP do giảng viên hoặc phòng đào tạo cung cấp hợp pháp.
3. Sinh dữ liệu giả lập (Synthetic Data) với định dạng chuẩn 100% của FPT University đối với các thông tin nhạy cảm (sinh viên, giảng viên, phiên điểm danh).
4. Chuẩn hóa (Transform), xác thực toàn vẹn (Validate) và xuất ra file nạp dữ liệu (JSON / SQL Seed) tương thích tuyệt đối với schema PostgreSQL của UniCheck.

### Các nguyên tắc bắt buộc:
- **Zero-Invasive Scraping**: Luôn có rate limiting (nghỉ ngẫu nhiên 2 - 4 giây giữa các request), xoay vòng User-Agent chuẩn trình duyệt, hỗ trợ cache dữ liệu để không gọi trùng URL.
- **Fail-Safe & Dry-Run First**: Mọi lệnh đều hỗ trợ cờ `--dry-run` để kiểm tra số lượng bản ghi, lỗi xung đột hoặc thiếu trường trước khi tạo file thực tế.
- **Idempotency**: Dữ liệu xuất ra luôn có khả năng chạy lại nhiều lần mà không tạo bản ghi trùng lặp (`ON CONFLICT DO NOTHING` hoặc `ON CONFLICT (code) DO UPDATE`).
- **Privacy Compliance**: Không thu thập dữ liệu cá nhân thật từ FAP; thay vào đó sử dụng generator sinh tên tiếng Việt chuẩn hóa, mã sinh viên theo format `HE18xxxx`, `SE18xxxx` và mã giảng viên `DungLNT`, `SonNT`.

---

## 2. KIẾN TRÚC THƯ MỤC CÔNG CỤ (`tools/fpt-data-collector/`)

```text
tools/fpt-data-collector/
├── pyproject.toml / requirements.txt   # Dependencies: requests, beautifulsoup4, pandas, openpyxl, pydantic
├── README.md                           # Hướng dẫn cài đặt và sử dụng CLI
├── main.py                             # Điểm khởi chạy CLI (Command Line Interface)
├── config.py                           # Cấu hình URLs, headers, rate-limits, output paths
├── scrapers/
│   ├── __init__.py
│   ├── base_scraper.py                 # Lớp cơ sở: session, retries, rate limiting, logging
│   └── fptu_curriculum_scraper.py      # Bóc tách ngành, chuyên ngành, môn học từ daihoc.fpt.edu.vn
├── parsers/
│   ├── __init__.py
│   ├── fap_schedule_parser.py          # Bóc tách file Excel xuất từ FAP (Thời khóa biểu tuần)
│   └── fap_student_list_parser.py      # Đọc danh sách sinh viên lớp từ file CSV/Excel hợp lệ
├── generators/
│   ├── __init__.py
│   ├── fpt_synthetic_generator.py      # Sinh dữ liệu giả lập: Giảng viên, Sinh viên, Điểm danh mẫu
│   └── timetable_generator.py          # Sinh thời khóa biểu đầy đủ 10-15 tuần theo khung slot FPT
├── transformers/
│   ├── __init__.py
│   ├── schema_mapper.py                # Ánh xạ dữ liệu FPT -> Entities UniCheck
│   └── data_validator.py               # Kiểm tra ràng buộc FK, định dạng mã, regex email, slot hợp lệ
├── exporters/
│   ├── __init__.py
│   ├── json_exporter.py                # Xuất ra file JSON lưu trữ trung gian
│   └── sql_seed_exporter.py            # Xuất script SQL PostgreSQL an toàn, idempotent
└── data/
    ├── raw/                            # Chứa dữ liệu cào thô và file excel đầu vào
    ├── normalized/                     # Dữ liệu JSON sau khi chuẩn hóa
    └── seeds/                          # File SQL hoàn chỉnh sẵn sàng nạp vào PostgreSQL
```

---

## 3. THIẾT KẾ CÁC MODULE CHI TIẾT

### 3.1. Module Scraper (`scrapers/fptu_curriculum_scraper.py`)
- **Nguồn thu thập**:
  - `https://daihoc.fpt.edu.vn/chuong-trinh-dao-tao/`
  - Các trang con chuyên ngành: `/chuyen-nganh/ky-thuat-phan-mem/`, `/chuyen-nganh/tri-tue-nhan-tao/`, v.v.
- **Dữ liệu thu được**:
  - Tên ngành: Công nghệ thông tin, Quản trị kinh doanh, Công nghệ truyền thông, Ngôn ngữ, Luật.
  - Tên chuyên ngành: Kỹ thuật phần mềm (SE), Trí tuệ nhân tạo (AI), An toàn thông tin (IA), Hệ thống thông tin (IS), Thiết kế mỹ thuật số (GD).
  - Khung thời gian: 4 năm (9 học kỳ chính khóa + giai đoạn chuẩn bị tiếng Anh).
  - Các khối môn học và định hướng công nghệ.
- **Kỹ thuật chống chặn & tải trọng**:
  - Sử dụng thư viện `requests` kèm `urllib3.util.retry.Retry` (tối đa 3 lần thử lại khi gặp 429 hoặc 5xx).
  - Header: `User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36`.
  - Rate limiting: `time.sleep(random.uniform(1.5, 3.0))` giữa mỗi URL.
  - Tự động lưu cache file HTML tại `data/raw/html_cache/` để tránh gọi lại nhiều lần.

### 3.2. Module Parser (`parsers/fap_schedule_parser.py`)
- **Đầu vào**: File Excel `.xlsx` hoặc `.csv` xuất từ FAP màn hình *Weekly Timetable* hoặc *Class Information*.
- **Định dạng bảng FAP thông thường**:
  - Cột: `Date`, `Slot`, `Class`, `Subject Code`, `Room`, `Lecturer`, `Attendance Status`.
- **Cơ chế bóc tách**:
  - Sử dụng `pandas` và `openpyxl`.
  - Chuẩn hóa ngày: `dd/MM/yyyy` -> `YYYY-MM-DD`.
  - Chuẩn hóa Slot: Map các khung giờ slot 1..6 tương ứng với bảng `slot_types` của UniCheck.
  - Chuẩn hóa Room: Tách `Building` và `Room Code` (ví dụ `AL-L201` -> Tòa `Alpha`, Tầng 2).

### 3.3. Module Synthetic Generator (`generators/fpt_synthetic_generator.py`)
- Nhằm mục đích phục vụ kiểm thử và demo đầy đủ mà không lộ thông tin cá nhân của người thật:
  - **Giảng viên**: Tạo 10-15 tài khoản giảng viên theo đúng định danh viết tắt của FPT (ví dụ: `SonNT`, `DungLNT`, `TuanVM`, `KhanhKT`, `ChungLQ`, `TrangVTT`), email `@fpt.edu.vn`, mật khẩu mặc định băm bằng BCrypt tương thích với Spring Security của UniCheck.
  - **Sinh viên**: Tạo 100-200 tài khoản sinh viên theo các khóa K18, K19 (mã `HE180001` đến `HE180100`, email `@fpt.edu.vn`, ảnh đại diện mẫu, trạng thái đăng ký khuôn mặt `REGISTERED` hoặc `NOT_REGISTERED`).
  - **Lớp học phần (ClassSection)**: Tạo các lớp theo chuẩn FPT: `SE1801-PRJ301`, `SE1802-CSD201`, `AI1801-AIL101`, `IA1801-IAE101`.
  - **Thời khóa biểu (TimetableSlots)**: Tạo lịch học phân bổ đều các ngày trong tuần (Thứ Hai đến Thứ Bảy), gắn đúng Slot 1-6 và phòng học tại Campus Hòa Lạc.
  - **Điểm danh mẫu (AttendanceSessions & StudentAttendance)**: Tạo các phiên điểm danh đã đóng (CLOSED) với tỷ lệ tham dự thực tế (85% PRESENT, 10% ABSENT, 5% LATE) kèm các phương thức nhận diện (FACE_RECOGNITION, DYNAMIC_QR, MANUAL) để hiển thị biểu đồ thống kê chuyên nghiệp trên Dashboard.

### 3.4. Module Transformer & Validator (`transformers/`)
- Kiểm tra toàn vẹn dữ liệu trước khi xuất:
  - Khóa chính không được rỗng (`null`).
  - Foreign key phải tồn tại trong danh mục (ví dụ `course_id`, `semester_id`, `lecturer_id`).
  - Trạng thái phải khớp với enum Java của UniCheck: `ClassSectionStatus`, `TimetableSlotStatus`, `AttendanceSessionStatus`, `Role`, `UserStatus`.
  - Kiểm tra xung đột phòng học: 1 phòng không thể có 2 lớp học cùng slot trong cùng 1 ngày.

### 3.5. Module Exporter (`exporters/sql_seed_exporter.py`)
- Xuất file SQL hoàn chỉnh: `tools/fpt-data-collector/data/seeds/fpt_unicheck_seed_data.sql`.
- Đảm bảo an toàn:
  - Đóng gói toàn bộ trong `BEGIN;` ... `COMMIT;`.
  - Sử dụng cú pháp `INSERT INTO ... ON CONFLICT DO NOTHING`.
  - Thiết lập lại chuỗi `SELECT setval('table_name_id_seq', (SELECT MAX(id) FROM table_name));` sau khi chèn để không làm hỏng tính năng tự động tăng ID trong tương lai.

---

## 4. THIẾT KẾ GIAO DIỆN DÒNG LỆNH (CLI SPECIFICATION)

```powershell
# 1. Cài đặt môi trường
pip install -r requirements.txt

# 2. Cào dữ liệu công khai từ website FPTU (Dry-run xem trước)
python main.py scrape --dry-run

# 3. Thực hiện cào dữ liệu công khai và lưu JSON
python main.py scrape --output data/normalized/fptu_catalog.json

# 4. Sinh bộ dữ liệu giả lập hoàn chỉnh (Synthetic Demo Dataset)
python main.py generate-demo --semester FALL2026 --students 150 --classes 12 --output data/normalized/demo_dataset.json

# 5. Phân tích file Excel lịch học FAP (nếu có file xuất hợp lệ)
python main.py parse-fap --file data/raw/fap_schedule_sample.xlsx --output data/normalized/fap_parsed.json

# 6. Xuất ra file SQL Seed hoàn chỉnh cho PostgreSQL
python main.py export-sql --input data/normalized/demo_dataset.json --output data/seeds/01_fpt_master_demo_seed.sql
```

---

## 5. KẾ HOẠCH BẢO ĐẢM AN TOÀN VÀ TIÊU CHUẨN KỸ THUẬT

1. **Không can thiệp cấu trúc bảng**: Giữ nguyên 100% Flyway migrations V1 đến V7 hiện có của UniCheck.
2. **Không tác động hệ thống thật của FPT**: Mọi thao tác thu thập chỉ đọc các trang tĩnh công khai hoặc file do người dùng tự cung cấp.
3. **Môi trường nạp dữ liệu**: Chỉ áp dụng cho database phát triển cục bộ (`unicheck_db` trong Docker Desktop hoặc PostgreSQL local).
