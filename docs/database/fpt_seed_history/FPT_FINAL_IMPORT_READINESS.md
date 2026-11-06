# FPT UNIVERSITY DEMO DATA – FINAL IMPORT READINESS REPORT

> **Dự án**: UniCheck – Smart Multi-Platform Attendance System  
> **Tài liệu**: Báo cáo Đánh giá Mức độ Sẵn sàng Nạp Chính thức (Final Import Readiness Report)  
> **Cơ sở dữ liệu đích**: `unicheck_db` (PostgreSQL 15-alpine Development)  
> **Tệp dữ liệu Seed**: `tools/fpt-data-collector/data/seeds/01_fpt_master_demo_seed.sql`  
> **Tệp sao lưu đối chứng**: `backend/backups/unicheck_db_pre_fpt_seed_backup_20261029.sql`  
> **Ngày thực hiện**: 29/10/2026  
> **Vai trò**: Senior PostgreSQL DBA & Full-Stack Integration Engineer  

---

## 1. PHÁN QUYẾT CUỐI CÙNG (FINAL VERDICT)

$$\huge \color{green}\textbf{VERDICT: READY TO IMPORT}$$

### Đánh giá tổng quan:
* **Tính toàn vẹn dữ liệu hiện có**: **100% ĐƯỢC BẢO TOÀN**  
  Tất cả 4 tài khoản người dùng (`admin`, `student_test`, `lecturer_test`, `lecturer_test2`), môn học `IT301`, lớp `IT301`/`IT301.02`, 14 slot học phòng `A301` và **FaceID vector người dùng thật (2048 bytes)** trong bảng `face_encodings` được giữ nguyên vẹn tuyệt đối.
* **Tính không xâm lấn (Non-destructive & Idempotent)**: **ĐẠT**  
  File SQL Seed `01_fpt_master_demo_seed.sql` chứa 0 lệnh `DELETE`, 0 lệnh `TRUNCATE`, 0 lệnh `DROP`, 0 lệnh `UPDATE`. 100% câu lệnh chèn dữ liệu sử dụng mệnh đề `ON CONFLICT DO NOTHING`.
* **Khả năng phục hồi sự cố (Disaster Recovery)**: **ĐÃ KIỂM CHỨNG THÀNH CÔNG**  
  Bản sao lưu `backend/backups/unicheck_db_pre_fpt_seed_backup_20261029.sql` (468,550 bytes, chuẩn UTF-8 no BOM) đã được phục hồi thử nghiệm thành công 100% trên database tạm thời `unicheck_restore_test` với số lượng bản ghi và giá trị checksum khớp từng byte.
* **Kết quả diễn tập nạp (Import Rehearsal)**: **HOÀN TOÀN THÀNH CÔNG**  
  Đã diễn tập nạp file seed vào bản sao độc lập của `unicheck_db` (`unicheck_rehearsal_db`):
  - **68 người dùng mới** được thêm vào hệ thống (tài khoản `admin` cũ tự động bỏ qua, bảo toàn mật khẩu và cấu hình).
  - **120 slot thời khóa biểu FPT** gắn kết mượt mà vào kỳ `FALL2026` hiện có.
  - **0 xung đột phòng học**, **0 xung đột giảng viên**, **0 xung đột lịch sinh viên**, **0 trùng lặp ghi danh**.
  - **13 chuỗi tự tăng (Sequences)** được đồng bộ chính xác bằng `SELECT setval()`, kiểm thử chèn mới tự sinh ID bình thường.
  - **Spring Security BCrypt Password**: 100% tương thích cả người dùng cũ (`Admin@123`, `Student@123`, `Lecturer@123`) lẫn người dùng seed mới (`Password@123`).

---

## 2. HIỆN TRẠNG DATABASE DEVELOPMENT (`unicheck_db`)

Trước khi tiến hành nạp, trạng thái thực tế của cơ sở dữ liệu `unicheck_db` được kiểm kê như sau:

| Đối tượng | Dữ liệu hiện tại | Ghi chú bảo vệ |
|:---|:---|:---|
| **Users** | 4 bản ghi: `admin` (ID 1), `student_test` (ID 2), `lecturer_test` (ID 3), `lecturer_test2` (ID 4) | Không bị ghi đè hay thay đổi mật khẩu |
| **Face Biometric** | 1 bản ghi trong `face_encodings` (User ID 2, vector 2048 bytes, MD5: `cda4309984246dce2f6c3d1f3184352c`) | File seed không thao tác lên bảng `face_encodings` |
| **Học kỳ (Semesters)** | 1 bản ghi: `FALL2026` (`2026-10-18` đến `2027-01-15`) | Trùng mã `FALL2026`, lệnh `ON CONFLICT (code) DO NOTHING` giữ nguyên ID 1 |
| **Môn học (Courses)** | 1 bản ghi: `IT301` (Lập trình Web) | Giữ nguyên |
| **Lớp học (Class Sections)**| 2 bản ghi: `IT301`, `IT301.02` | Giữ nguyên |
| **Phòng học (Rooms)** | 1 bản ghi: `A301` (Tòa A, ID 3) | Giữ nguyên |
| **Thời khóa biểu** | 14 slot học phòng `A301`, Slot 1 (07:00 - 09:25) | Giữ nguyên |
| **Lịch sử Flyway** | 7 migrations hoàn tất (V1 -> V7) | Không sửa đổi migration cũ |

---

## 3. KẾT QUẢ KIỂM ĐỊNH PHỤC HỒI SAO LƯU (BƯỚC 2)

Nhằm đảm bảo nếu có sự cố xảy ra, cơ sở dữ liệu có thể khôi phục tức thì về trạng thái ban đầu, quy trình kiểm định sao lưu đã được thực thi:

1. **Khởi tạo database độc lập**: `unicheck_restore_test`.
2. **Nạp bản sao lưu**: 
   ```powershell
   cmd.exe /c "docker exec -i unicheck_postgres psql -U unicheck_user -d unicheck_restore_test -v ON_ERROR_STOP=1 < backend\backups\unicheck_db_pre_fpt_seed_backup_20261029.sql"
   ```
3. **Đối chiếu số lượng bản ghi giữa Live DB và Restored DB**:

| Tên bảng | Số lượng `unicheck_db` | Số lượng `unicheck_restore_test` | Sai lệch | Trạng thái |
|:---|:---:|:---:|:---:|:---:|
| `users` | 4 | 4 | 0 | **KHỚP 100%** |
| `student_profiles` | 1 | 1 | 0 | **KHỚP 100%** |
| `lecturer_profiles` | 2 | 2 | 0 | **KHỚP 100%** |
| `courses` | 1 | 1 | 0 | **KHỚP 100%** |
| `semesters` | 1 | 1 | 0 | **KHỚP 100%** |
| `class_sections` | 2 | 2 | 0 | **KHỚP 100%** |
| `timetable_slots` | 14 | 14 | 0 | **KHỚP 100%** |
| `enrollments` | 2 | 2 | 0 | **KHỚP 100%** |
| `rooms` | 1 | 1 | 0 | **KHỚP 100%** |
| `face_encodings` | 1 | 1 | 0 | **KHỚP 100%** |
| `flyway_schema_history` | 7 | 7 | 0 | **KHỚP 100%** |

4. **Kiểm tra tính toàn vẹn nhị phân FaceID**:
   - Checksum MD5 của `encoding_data`: `cda4309984246dce2f6c3d1f3184352c`.
   - Độ dài byte: 2048 bytes.
   - Thời gian đăng ký: `2026-10-20 09:20:03.262283`.
   - **Kết luận**: File backup hoàn toàn hợp lệ, toàn vẹn dữ liệu nhị phân. Đã dọn dẹp xóa database `unicheck_restore_test` sau kiểm định.

---

## 4. KẾT QUẢ DIỄN TẬP NẠP TRÊN BẢN SAO CÔ LẬP (BƯỚC 3)

Quá trình diễn tập được thực hiện bằng cách tạo bản sao `unicheck_rehearsal_db` từ backup và nạp trực tiếp `01_fpt_master_demo_seed.sql` với cờ chặn lỗi `-v ON_ERROR_STOP=1`.

### 4.1. Chi tiết số lượng bản ghi biến động

| Nhóm dữ liệu | Bảng dữ liệu | Trước nạp | Thêm mới | Bị bỏ qua (Skip) | Tổng cộng sau nạp | Ghi chú kỹ thuật |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **Người dùng** | `users` | 4 | +68 | 1 (`admin`) | **72** | Tài khoản `admin` cũ được bảo toàn 100% |
| **Hồ sơ sinh viên**| `student_profiles` | 1 | +60 | 0 | **61** | Khóa ngoại trỏ đúng sinh viên K18 FPT |
| **Hồ sơ giảng viên**| `lecturer_profiles` | 2 | +8 | 0 | **10** | Trỏ đúng các giảng viên bộ môn CNTT |
| **Ngành học** | `majors` | 0 | +5 | 0 | **5** | SE, AI, IA, IS, BA |
| **Chuyên ngành** | `specializations` | 0 | +10 | 0 | **10** | Kỹ thuật phần mềm, Trí tuệ nhân tạo,... |
| **Học phần** | `courses` | 1 | +25 | 0 | **26** | Thêm 25 mã môn chuẩn FPT (PRJ301, CSD201,...) |
| **Điều kiện tiên quyết** | `course_prerequisites` | 0 | +8 | 0 | **8** | Ràng buộc tiên quyết chuẩn giáo trình |
| **Học kỳ** | `semesters` | 1 | +2 | 1 (`FALL2026`) | **3** | `FALL2026` có sẵn được tái sử dụng cho 120 slot |
| **Khung giờ học** | `slot_types` | 0 | +6 | 0 | **6** | 6 ca học chuẩn FPT (07:00 -> 17:30) |
| **Phòng học** | `rooms` | 1 | +16 | 0 | **17** | Phòng `A301` + 16 phòng Alpha, Beta, Gamma, Delta |
| **Thiết bị WiFi AP** | `wifi_access_points` | 0 | +8 | 0 | **8** | 8 Access Point định vị điểm danh |
| **WiFi - Phòng học**| `room_wifi_access_points`| 0 | +8 | 0 | **8** | Ánh xạ WiFi vào phòng học |
| **Lớp học phần** | `class_sections` | 2 | +8 | 0 | **10** | 2 lớp cũ + 8 lớp chuyên ngành FPT |
| **Thời khóa biểu**| `timetable_slots` | 14 | +120 | 0 | **134** | 14 slot cũ + 120 slot mới từ 19/10/2026 |
| **Ghi danh** | `enrollments` | 2 | +200 | 0 | **202** | 25 sinh viên / lớp |
| **Phiên điểm danh**| `attendance_sessions`| 3 | +40 | 0 | **43** | Phiên điểm danh cho các slot đã diễn ra |
| **Kết quả điểm danh**| `student_attendances`| 0 | +801 | 0 | **801** | Lịch sử điểm danh (PRESENT, ABSENT, LATE) |
| **Dữ liệu khuôn mặt**| `face_encodings` | 1 | 0 | 0 | **1** | **Bảo toàn nguyên vẹn 100% FaceID cũ** |

### 4.2. Kết quả kiểm tra xung đột logic học vụ (Timetable Collision Checks)

Đã chạy truy vấn kiểm tra toàn bộ 134 slot thời khóa biểu và 801 bản ghi điểm danh:

```sql
-- Kiểm tra xung đột phòng học: 0 vi phạm (Mỗi phòng tối đa 1 lớp / ca)
-- Kiểm tra xung đột giảng viên: 0 vi phạm (Mỗi giảng viên dạy tối đa 1 lớp / ca)
-- Kiểm tra xung đột sinh viên:  0 vi phạm (Mỗi sinh viên học tối đa 1 lớp / ca)
-- Ghi danh trùng lặp:           0 vi phạm (Mỗi sinh viên ghi danh 1 lần / lớp)
-- Điểm danh trùng lặp:          0 vi phạm (Mỗi sinh viên có đúng 1 trạng thái / phiên)
```

### 4.3. Kiểm định cơ chế tăng tự động (PostgreSQL Sequence Health)

Tất cả các sequence đã được cập nhật giá trị bằng `SELECT setval()` tương ứng với `MAX(id)`:
* `users_id_seq`: `73` (chèn tiếp theo sẽ là ID 74).
* `timetable_slots_id_seq`: `134` (chèn tiếp theo là ID 135).
* `courses_id_seq`: `26`.
* `enrollments_id_seq`: `202`.
* `student_attendances_id_seq`: `801`.
* **Thực nghiệm**: Chèn thử nghiệm một bản ghi user mới không chỉ định ID -> Database tự sinh `id = 74` thành công, không gặp lỗi `unique constraint violation`.

### 4.4. Kiểm định xác thực mật khẩu & API Backend

* **Mật khẩu người dùng cũ (bảo toàn)**:
  - `admin` / `Admin@123` -> **BCrypt Match: True** (API `/api/v1/auth/login` trả về HTTP 200 + JWT Token).
  - `student_test` / `Student@123` -> **BCrypt Match: True** (Đăng nhập thành công).
  - `lecturer_test` / `Lecturer@123` -> **BCrypt Match: True** (Đăng nhập thành công).
* **Mật khẩu người dùng FPT Seed mới**:
  - `gv_sonnt` (Giảng viên) / `Password@123` -> **BCrypt Match: True**.
  - `sv_he180001` (Sinh viên) / `Password@123` -> **BCrypt Match: True**.

---

## 5. HƯỚNG DẪN THỰC THI NẠP LÊN `unicheck_db` (EXECUTION RUNBOOK)

Sau khi có sự chấp thuận, người vận hành có thể thực hiện nạp dữ liệu vào `unicheck_db` một cách an toàn và nhanh chóng.

### Bước 1: Mở PowerShell tại thư mục gốc dự án
```powershell
cd c:\Users\Admin\Documents\Antigravity\UniCheck
```

### Bước 2: Chạy lệnh nạp SQL Seed vào `unicheck_db`
Chạy một trong hai câu lệnh tương đương sau:

**Cách 1 (Khuyên dùng - Sử dụng cmd pipeline tránh lỗi font Windows PowerShell):**
```powershell
cmd.exe /c "docker exec -i unicheck_postgres psql -U unicheck_user -d unicheck_db -v ON_ERROR_STOP=1 < tools\fpt-data-collector\data\seeds\01_fpt_master_demo_seed.sql"
```

**Cách 2 (Sử dụng PowerShell native pipe):**
```powershell
Get-Content tools\fpt-data-collector\data\seeds\01_fpt_master_demo_seed.sql | docker exec -i unicheck_postgres psql -U unicheck_user -d unicheck_db -v ON_ERROR_STOP=1
```

*(Thời gian thực thi dự kiến: từ 1 đến 2 giây)*

### Bước 3: Xác minh ngay sau khi nạp (Post-Import Verification)
Chạy lệnh kiểm tra nhanh số lượng bản ghi:
```powershell
docker exec -i unicheck_postgres psql -U unicheck_user -d unicheck_db -c "SELECT 'users' as tbl, count(*) FROM users UNION ALL SELECT 'courses', count(*) FROM courses UNION ALL SELECT 'timetable_slots', count(*) FROM timetable_slots UNION ALL SELECT 'face_encodings', count(*) FROM face_encodings;"
```
**Kết quả mong đợi:**
- `users`: `72`
- `courses`: `26`
- `timetable_slots`: `134`
- `face_encodings`: `1` (Không thay đổi)

### Bước 4: Phương án hoàn tác khẩn cấp (Rollback Plan - Nếu cần)
Nếu cần khôi phục lại trạng thái cũ ngay lập tức:
```powershell
cmd.exe /c "docker exec -i unicheck_postgres psql -U unicheck_user -d unicheck_db -v ON_ERROR_STOP=1 < backend\backups\unicheck_db_pre_fpt_seed_backup_20261029.sql"
```
*(Khôi phục hoàn toàn chỉ trong 3 giây)*

---

## 6. DANH SÁCH TÀI KHOẢN ĐĂNG NHẬP SAU KHI NẠP

| Vai trò (Role) | Tên đăng nhập (Username) | Mật khẩu (Password) | Mã đối tượng (Code) | Mô tả mục đích |
|:---|:---|:---|:---|:---|
| **ADMIN** | `admin` | `Admin@123` | `AD_001` | Tài khoản Quản trị viên hệ thống gốc |
| **STUDENT** | `student_test` | `Student@123` | `SV2026001` | Sinh viên thử nghiệm gốc (Có sẵn FaceID) |
| **LECTURER** | `lecturer_test` | `Lecturer@123` | `GV_TEST_001` | Giảng viên thử nghiệm gốc |
| **LECTURER (FPT)** | `gv_sonnt` | `Password@123` | `TEST_LEC_01` | Giảng viên FPT chuyên ngành SE (dạy PRJ301) |
| **LECTURER (FPT)** | `gv_khanhkt` | `Password@123` | `TEST_LEC_04` | Giảng viên FPT chuyên ngành SE (dạy SWP391) |
| **STUDENT (FPT)** | `sv_he180001` | `Password@123` | `HE180001` | Sinh viên K18 FPT (Lớp SE1801, PRJ301) |
| **STUDENT (FPT)** | `sv_he180031` | `Password@123` | `HE180031` | Sinh viên K18 FPT (Lớp AI1801, AIL101) |
| *(Tất cả 60 SV K18)* | `sv_he180001` -> `sv_he180060` | `Password@123` | `HE180001` -> `HE180060` | Sinh viên các lớp SE, AI, IA, IS |
