# FPT SEED DATA EXECUTION & TESTING GUIDE

> **Dự án**: UniCheck – Smart Multi-Platform Attendance System  
> **Tài liệu**: Hướng dẫn Thực thi Seed Dữ liệu & Đăng nhập Kiểm thử  
> **Phiên bản**: 1.0.0  
> **Ngày hoàn thành**: 29/10/2026  

---

## 1. VỊ TRÍ CÁC ARTIFACTS DỮ LIỆU

1. **File Script SQL Seed (PostgreSQL)**:
   [`tools/fpt-data-collector/data/seeds/01_fpt_master_demo_seed.sql`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/tools/fpt-data-collector/data/seeds/01_fpt_master_demo_seed.sql)
2. **File Dữ liệu Chuẩn hóa (JSON)**:
   [`tools/fpt-data-collector/data/normalized/fpt_master_demo_dataset.json`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/tools/fpt-data-collector/data/normalized/fpt_master_demo_dataset.json)

---

## 2. HƯỚNG DẪN THỰC THI NẠP DỮ LIỆU VÀO POSTGRESQL

### Cách 1: Nạp qua Docker Desktop (Môi trường chuẩn của dự án)
Khi các container Docker đang chạy (`docker compose up -d`), mở PowerShell tại thư mục gốc của dự án và chạy:

```powershell
docker compose exec -T postgres psql -U unicheck_user -d unicheck_db < tools/fpt-data-collector/data/seeds/01_fpt_master_demo_seed.sql
```

### Cách 2: Nạp qua PostgreSQL Local trên máy (nếu chạy không qua Docker)
```powershell
psql -h localhost -p 5432 -U unicheck_user -d unicheck_db -f tools/fpt-data-collector/data/seeds/01_fpt_master_demo_seed.sql
```

> [!NOTE]
> File SQL được thiết kế với tính chất **Idempotent** (`ON CONFLICT DO NOTHING`) và bọc trong giao dịch `BEGIN; ... COMMIT;`. Nếu bạn chạy lệnh này nhiều lần, hệ thống sẽ tự động bỏ qua các bản ghi đã tồn tại mà không gây lỗi hoặc trùng lặp.

---

## 3. CÁC CÂU LỆNH SQL KIỂM TRA SAU KHI NẠP DỮ LIỆU (POST-SEED AUDIT)

Sau khi nạp xong, bạn có thể chạy các câu truy vấn sau trong PostgreSQL để xác minh kết quả:

```sql
-- 1. Thống kê tổng số lượng bản ghi của từng bảng
SELECT 'majors' AS table_name, count(*) FROM majors
UNION ALL SELECT 'specializations', count(*) FROM specializations
UNION ALL SELECT 'courses', count(*) FROM courses
UNION ALL SELECT 'semesters', count(*) FROM semesters
UNION ALL SELECT 'rooms', count(*) FROM rooms
UNION ALL SELECT 'users', count(*) FROM users
UNION ALL SELECT 'class_sections', count(*) FROM class_sections
UNION ALL SELECT 'enrollments', count(*) FROM enrollments
UNION ALL SELECT 'timetable_slots', count(*) FROM timetable_slots
UNION ALL SELECT 'attendance_sessions', count(*) FROM attendance_sessions
UNION ALL SELECT 'student_attendances', count(*) FROM student_attendances;

-- 2. Xem danh sách các lớp học phần kỳ Fall 2026 kèm giảng viên
SELECT c.class_name, co.name AS course_name, u.full_name AS lecturer, c.current_enrollment, c.status
FROM class_sections c
JOIN courses co ON c.course_id = co.id
JOIN users u ON c.lecturer_id = u.id
ORDER BY c.class_name;

-- 3. Xem các phiên điểm danh đang MỞ (OPEN) sẵn sàng cho test quét QR hoặc FaceID
SELECT s.id AS session_id, t.class_name, t.date, t.slot_number, u.full_name AS lecturer, s.status
FROM attendance_sessions s
JOIN timetable_slots t ON s.timetable_slot_id = t.id
JOIN users u ON s.lecturer_id = u.id
WHERE s.status = 'OPEN';
```

---

## 4. MA TRẬN TÀI KHOẢN ĐĂNG NHẬP THỬ NGHIỆM (TEST CREDENTIALS MATRIX)

Tất cả các tài khoản thử nghiệm đều sử dụng chung một mật khẩu chuẩn:
👉 **Mật khẩu**: `Password@123`

### 4.1. Tài khoản Quản trị viên (Admin)
| Username | Email | Vai trò (Role) | Chức năng kiểm thử |
|:---|:---|:---:|:---|
| `admin` | `admin@test.unicheck.edu.vn` | `ADMIN` | Quản lý danh mục ngành, môn học, lớp học phần, phòng học, phân công giảng viên |

### 4.2. Danh sách 8 Giảng viên thử nghiệm (Lecturers)
| Username | Email | Họ và tên | Môn học phụ trách | Lớp giảng dạy |
|:---|:---|:---|:---|:---|
| `gv_sonnt` | `sonnt@test.unicheck.edu.vn` | Nguyễn Tấn Sơn | `PRJ301` (Java Web Application) | `SE1801-PRJ301` |
| `gv_dunglnt` | `dunglnt@test.unicheck.edu.vn` | Lê Ngọc Tuấn Dũng | `CSD201` (Data Structures) | `SE1802-CSD201` |
| `gv_khanhkt` | `khanhkt@test.unicheck.edu.vn` | Kiều Trọng Khánh | `SWP391` (Software Project) | `SE1803-SWP391` |
| `gv_chunglq` | `chunglq@test.unicheck.edu.vn` | Lê Quang Chung | `PRN211` (.NET Core) | `SE1804-PRN211` |
| `gv_tuanvm` | `tuanvm@test.unicheck.edu.vn` | Vũ Minh Tuấn | `AIL101` & `AIP391` (AI) | `AI1801-AIL101`, `AI1802-AIP391` |
| `gv_trangvtt` | `trangvtt@test.unicheck.edu.vn` | Võ Thị Thu Trang | `IAE101` (Information Assurance) | `IA1801-IAE101` |
| `gv_haont` | `haont@test.unicheck.edu.vn` | Nguyễn Thành Hảo | `DBI202` (Databases) | `IS1801-DBI202` |
| `gv_namph` | `namph@test.unicheck.edu.vn` | Phạm Hữu Nam | `MKT101` / `OBM101` (Kinh tế) | Giảng viên dự phòng |

### 4.3. Danh sách Sinh viên mẫu tiêu biểu (Students)
| Username | Mã sinh viên (RollNo) | Email | Khóa / Chuyên ngành | Ghi chú |
|:---|:---:|:---|:---:|:---|
| `sv_he180001` | `HE180001` | `he180001@test.unicheck.edu.vn` | K18 - Kỹ thuật phần mềm | Ghi danh `SE1801-PRJ301` |
| `sv_he180002` | `HE180002` | `he180002@test.unicheck.edu.vn` | K18 - Kỹ thuật phần mềm | Ghi danh `SE1801-PRJ301` |
| `sv_he180003` | `HE180003` | `he180003@test.unicheck.edu.vn` | K18 - Kỹ thuật phần mềm | Ghi danh `SE1801-PRJ301` |
| `sv_he180041` | `HE180041` | `he180041@test.unicheck.edu.vn` | K19 - Trí tuệ nhân tạo | Ghi danh `AI1801-AIL101` |
| `sv_he180042` | `HE180042` | `he180042@test.unicheck.edu.vn` | K19 - Trí tuệ nhân tạo | Ghi danh `AI1801-AIL101` |

*(Toàn bộ 60 sinh viên từ `sv_he180001` đến `sv_he180060` đều sẵn sàng đăng nhập trên Web và Flutter Mobile App)*.
