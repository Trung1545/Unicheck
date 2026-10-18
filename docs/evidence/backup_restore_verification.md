# UNICHECK - BACKUP & RESTORE VERIFICATION REPORT (TASK P01)
**Thời điểm thực thi**: 2026-10-13  
**Môi trường**: Windows 11 Enterprise [Version 10.0.26300.9550]  
**PostgreSQL Runtime**: PostgreSQL 18.4 (msvc 64-bit) at `localhost:5432`  
**Công cụ sử dụng**: `pg_dump.exe`, `psql.exe` tại `C:\Program Files\PostgreSQL\18\bin\`

---

## 1. MỤC TIÊU VÀ PHẠM VI KIỂM THỬ

1. Khảo sát dữ liệu thực tế và Flyway history trên database dev `unicheck_clean_test`.
2. Tạo tệp sao lưu (backup) đầy đủ lược đồ và dữ liệu bằng script `backend/scripts/backup_restore.ps1`.
3. Khôi phục thử nghiệm (restore) vào cơ sở dữ liệu `unicheck_db` (trước đó là cơ sở dữ liệu rỗng 0 bảng).
4. Xác minh tính toàn vẹn 100% của 50 bảng nghiệp vụ và bảng lịch sử Flyway sau khi phục hồi.

---

## 2. KẾT QUẢ THỰC THI CHI TIẾT

### 2.1. Bước 1: Trạng thái cơ sở dữ liệu trước kiểm thử
- `unicheck_clean_test`: 51 bảng (50 bảng nghiệp vụ + 1 bảng `flyway_schema_history` với 3 migration V1, V2, V3 đều thành công).
- `unicheck_db`: 0 bảng (`Did not find any tables`).

### 2.2. Bước 2: Thực thi Lệnh Sao Lưu (Backup)
- **Lệnh chạy**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File backend\scripts\backup_restore.ps1 -Action backup -Database unicheck_clean_test
  ```
- **Kết quả thực tế**:
  ```
  [UniCheck Backup] Starting backup for database 'unicheck_clean_test' at localhost:5432...
  [UniCheck Backup] Using pg_dump: C:\Program Files\PostgreSQL\18\bin\pg_dump.exe
  [UniCheck Backup] Output file: C:\Users\Admin\Documents\Antigravity\UniCheck\backend\backups\unicheck_backup_unicheck_clean_test_20261013_162340.sql
  [UniCheck Backup] SUCCESS! Backup saved (138457 bytes).
  ```
- **Exit Code**: `0` (Thành công).
- **Tệp xuất ra**: `backend/backups/unicheck_backup_unicheck_clean_test_20261013_162340.sql` (Kích thước: 138,457 bytes).

### 2.3. Bước 3: Thực thi Lệnh Phục Hồi (Restore vào DB rỗng `unicheck_db`)
- **Lệnh chạy**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File backend\scripts\backup_restore.ps1 -Action restore -Database unicheck_db
  ```
- **Kết quả thực tế**:
  ```
  [UniCheck Restore] Starting restore to database 'unicheck_db' from 'C:\Users\Admin\Documents\Antigravity\UniCheck\backend\backups\unicheck_backup_unicheck_clean_test_20261013_162340.sql'...
  [UniCheck Restore] Using psql: C:\Program Files\PostgreSQL\18\bin\psql.exe
  ...
  [UniCheck Restore] SUCCESS! Database 'unicheck_db' restored successfully.
  ```
- **Exit Code**: `0` (Thành công).

### 2.4. Bước 4: Kiểm tra và đối chiếu sau phục hồi (Post-Restore Verification)
- **Truy vấn số lượng bảng trên `unicheck_db`**:
  ```sql
  SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
  ```
  *Kết quả*: **51 bảng** (Trùng khớp 100% với database nguồn `unicheck_clean_test`).

- **Truy vấn lịch sử Flyway trên `unicheck_db`**:
  ```sql
  SELECT installed_rank, version, description, script, success FROM flyway_schema_history ORDER BY installed_rank;
  ```
  *Kết quả*:
  ```
   installed_rank | version |              description               |                     script                     | success 
  ----------------+---------+----------------------------------------+------------------------------------------------+---------
                1 | 1       | init academic catalog                  | V1__init_academic_catalog.sql                  | t
                2 | 2       | init users and profiles                | V2__init_users_and_profiles.sql                | t
                3 | 3       | init classes attendance and operations | V3__init_classes_attendance_and_operations.sql | t
  (3 rows)
  ```

---

## 3. KIỂM THỬ KHỞI ĐỘNG HỆ THỐNG VÀ BẢO VỆ REGRESSION (MAVEN TEST RUN)

- **Lệnh chạy**:
  ```powershell
  mvn test
  ```
- **Kết quả thực tế**:
  ```
  [INFO] Results:
  [INFO] 
  [INFO] Tests run: 30, Failures: 0, Errors: 0, Skipped: 0
  [INFO] 
  [INFO] ------------------------------------------------------------------------
  [INFO] BUILD SUCCESS
  [INFO] ------------------------------------------------------------------------
  [INFO] Total time:  18.585 s
  ```
- **Đánh giá**: Toàn bộ 30 test suites trong backend (bao gồm startup trên clean database, authentication, user management CRUD, audit logs) đều tiếp tục **PASS 100%**, không có bất kỳ hồi quy nào.
