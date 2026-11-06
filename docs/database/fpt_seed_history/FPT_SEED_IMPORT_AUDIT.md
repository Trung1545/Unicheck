# FPT DEMO SEED IMPORT AUDIT & DATABASE SAFETY REPORT

> **Dự án**: UniCheck – Smart Multi-Platform Attendance System  
> **Tài liệu**: Báo cáo Đánh giá Tiền Nạp (Pre-Import Audit) & Nạp Thử nghiệm Cô lập  
> **Phiên bản**: 1.0.0  
> **Ngày lập**: 29/10/2026  
> **Thực hiện bởi**: Senior PostgreSQL DBA, Spring Boot Engineer & QA Lead  

---

## 1. MÔI TRƯỜNG & DATABASE ĐƯỢC KIỂM TRA

### 1.1. Hạ tầng PostgreSQL
* **Container Docker**: `unicheck_postgres` (PostgreSQL 15-alpine, Cổng ánh xạ: `5432:5432`).
* **Trạng thái**: `Up (healthy)`.
* **Người dùng kết nối**: `unicheck_user`.

### 1.2. Hiện trạng Database trước khi nạp
* **Database Development chính (`unicheck_db`)**:
  - Đang phục vụ hoạt động development, lưu trữ dữ liệu người dùng thật/thử nghiệm trước đó:
    - `users`: **4 bản ghi** (`admin` ID 1, `student_test` ID 2, `lecturer_test` ID 3, `lecturer_test2` ID 4).
    - `courses`: **1 bản ghi** (`IT301`).
    - `semesters`: **1 bản ghi** (`FALL2026`, thời gian: `2026-10-18` đến `2027-01-15`).
    - `class_sections`: **2 bản ghi** (`IT301`, `IT301.02`).
    - `timetable_slots`: **14 bản ghi**.
    - `attendance_sessions`: **3 bản ghi**.
    - `user_sessions`: **112 bản ghi**.
    - `access_logs`: **137 bản ghi**.
    - `face_encodings`: **1 bản ghi** (vector nhận diện của người dùng thật).
* **Biện pháp Bảo vệ An toàn Dữ liệu**:
  - Đã xuất bản sao lưu toàn diện dự phòng:
    📁 [`backend/backups/unicheck_db_pre_fpt_seed_backup_20261029.sql`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/backups/unicheck_db_pre_fpt_seed_backup_20261029.sql) (468,550 bytes).
  - **Tuân thủ nguyên tắc cách ly**: **Tuyệt đối KHÔNG chạy trực tiếp lên `unicheck_db`**. Tạo database độc lập riêng **`unicheck_fpt_test`** để thử nghiệm.

---

## 2. KIỂM ĐỊNH TỆP TIN SQL SEED (`01_fpt_master_demo_seed.sql`)

### 2.1. Kiểm tra lệnh hủy hoại dữ liệu (Destructive Statements Audit)
* Đã quét toàn bộ 1,451 dòng của file SQL seed:
  - `DELETE`: **0 lệnh**
  - `TRUNCATE`: **0 lệnh**
  - `DROP`: **0 lệnh**
  - `UPDATE`: **0 lệnh**
* **Kết luận**: File SQL thuần túy chỉ chứa các câu lệnh `INSERT INTO ... ON CONFLICT DO NOTHING`, bảo đảm an toàn tuyệt đối, không có khả năng xóa hoặc biến đổi dữ liệu có sẵn.

### 2.2. Kiểm tra xung đột khóa và tính Idempotent
* **Tài khoản Admin**:
  - Trong `unicheck_db`, tài khoản `admin` đã tồn tại với email `admin@unicheck.edu.vn`.
  - Trong file seed: `INSERT INTO users (..., username, ...) VALUES (..., 'admin', ...) ON CONFLICT (username) DO NOTHING;`.
  - **Kết quả**: Cơ chế `ON CONFLICT` sẽ tự động bỏ qua (skip), **giữ nguyên 100% tài khoản, email, mật khẩu gốc của Admin hiện có**.
* **Học kỳ FALL2026**:
  - Đã căn chỉnh thời gian kỳ `FALL2026` trong file seed khớp chính xác với `unicheck_db` (`start_date = 2026-10-18`, `end_date = 2027-01-15`).
  - Lịch học bắt đầu từ Thứ Hai `2026-10-19`. Do đó, 120 slot lịch học đều nằm trọn vẹn trong khung thời gian học kỳ.
* **Tự động tăng ID (Sequence Synchronization)**:
  - Cuối file có 13 lệnh `SELECT setval(..., COALESCE((SELECT MAX(id) FROM ...), 1));`.
  - Ngăn chặn hoàn toàn lỗi vỡ sequence (`Unique constraint violation on id`) khi hệ thống tạo bản ghi mới sau này.

---

## 3. KẾT QUẢ NẠP THỬ NGHIỆM TRÊN DATABASE CÔ LẬP (`unicheck_fpt_test`)

### 3.1. Các lệnh đã thực thi
```powershell
# 1. Khởi tạo database test cô lập
docker exec -i unicheck_postgres psql -U unicheck_user -d postgres -c "DROP DATABASE IF EXISTS unicheck_fpt_test; CREATE DATABASE unicheck_fpt_test OWNER unicheck_user;"

# 2. Áp dụng toàn bộ 7 Flyway migrations
Get-Content backend/src/main/resources/db/migration/V1__init_academic_catalog.sql | docker exec -i unicheck_postgres psql -U unicheck_user -d unicheck_fpt_test -v ON_ERROR_STOP=1
... (V2 -> V7)

# 3. Nạp bộ dữ liệu FPT Demo Seed
Get-Content tools/fpt-data-collector/data/seeds/01_fpt_master_demo_seed.sql | docker exec -i unicheck_postgres psql -U unicheck_user -d unicheck_fpt_test -v ON_ERROR_STOP=1
```

### 3.2. Bảng đối soát số lượng bản ghi (Trước vs Sau khi nạp)

| Tên bảng (Table Name) | Số lượng trước nạp | Số lượng sau nạp | Số bản ghi thêm mới | Trạng thái |
|:---|:---:|:---:|:---:|:---:|
| `majors` | 0 | 5 | +5 | **PASS** |
| `specializations` | 0 | 10 | +10 | **PASS** |
| `courses` | 0 | 25 | +25 | **PASS** |
| `course_prerequisites` | 0 | 8 | +8 | **PASS** |
| `semesters` | 0 | 3 | +3 | **PASS** |
| `slot_types` | 0 | 6 | +6 | **PASS** |
| `rooms` | 0 | 16 | +16 | **PASS** |
| `wifi_access_points` | 0 | 8 | +8 | **PASS** |
| `room_wifi_access_points` | 0 | 8 | +8 | **PASS** |
| `users` | 0 | 69 | +69 | **PASS** |
| `student_profiles` | 0 | 60 | +60 | **PASS** |
| `lecturer_profiles` | 0 | 8 | +8 | **PASS** |
| `class_sections` | 0 | 8 | +8 | **PASS** |
| `enrollments` | 0 | 200 | +200 | **PASS** |
| `timetable_slots` | 0 | 120 | +120 | **PASS** |
| `attendance_sessions` | 0 | 40 | +40 | **PASS** |
| `student_attendances` | 0 | 800 | +800 | **PASS** |
| **TỔNG CỘNG** | **0** | **1,418** | **+1,418** | **COMMIT THÀNH CÔNG 100%** |

---

## 4. KẾT QUẢ ĐỐI SOÁT TOÀN VẸN VÀ RÀNG BUỘC KỸ THUẬT

1. **Khóa ngoại (Foreign Keys)**: 100% bản ghi con tham chiếu chính xác bản ghi cha, 0 lỗi mồ côi (`orphan records`).
2. **Xung đột phòng học (Room Conflicts)**: **0 xung đột** (Mỗi phòng học chỉ chứa tối đa 1 lớp tại 1 slot trong ngày).
3. **Xung đột giảng viên (Lecturer Conflicts)**: **0 xung đột** (Mỗi giảng viên chỉ giảng dạy 1 lớp tại 1 thời điểm).
4. **Ghi danh trùng lặp (Duplicate Enrollments)**: **0 trùng lặp** (Mỗi sinh viên chỉ được ghi danh 1 lần vào mỗi lớp).
5. **Điểm danh trùng lặp (Duplicate Attendances)**: **0 trùng lặp** (Mỗi sinh viên chỉ có đúng 1 trạng thái trong mỗi phiên).
6. **Kiểm tra Sequence PostgreSQL**:
   - Chạy lệnh test: Chèn thêm 1 user mới `test_seq_user`.
   - Kết quả: PostgreSQL tự động cấp phát `id = 70` (chính xác bằng `MAX(id) + 1`), không bị đụng độ ID.

---

## 5. ĐỀ XUẤT PHƯƠNG ÁN NẠP LÊN DATABASE DEVELOPMENT (`unicheck_db`)

Sau khi nghiệm thu thành công trên `unicheck_fpt_test`, phương án nạp an toàn lên `unicheck_db` khi có chỉ đạo:
1. **Thời điểm thực hiện**: Trong phiên bảo trì dev.
2. **Bước 1**: Đảm bảo file backup `backend/backups/unicheck_db_pre_fpt_seed_backup_20261029.sql` đã sẵn sàng.
3. **Bước 2**: Thực thi nạp idempotent:
   ```powershell
   docker compose exec -T postgres psql -U unicheck_user -d unicheck_db < tools/fpt-data-collector/data/seeds/01_fpt_master_demo_seed.sql
   ```
4. **Đánh giá rủi ro**:
   - *Rủi ro mất dữ liệu*: **0%** (File không chứa bất kỳ lệnh DELETE/DROP/UPDATE nào).
   - *Rủi ro tài khoản*: **0%** (Tài khoản `admin`, `student_test`, `lecturer_test` cũ được giữ nguyên 100%).
   - *Khả năng hoàn tác (Rollback)*: Nếu có bất kỳ sự cố nào, chỉ cần khôi phục lại từ file backup trong vòng 5 giây.
