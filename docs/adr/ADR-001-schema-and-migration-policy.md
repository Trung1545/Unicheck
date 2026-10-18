# ADR-001: Chính Sách Quản Lý Lược Đồ CSDL Và Quyết Định Migration V4+

- **Trạng thái**: Accepted (Đã phê duyệt)
- **Ngày quyết định**: 2026-10-13
- **Tác giả**: Lead Engineer (UniCheck Core Team)
- **Phạm vi**: Backend PostgreSQL 15/18, Flyway Migrations, JPA Entities

---

## 1. Bối cảnh kỹ thuật (Context)

Hệ thống UniCheck hiện sở hữu 50 bảng cơ sở dữ liệu đã được khai báo qua 3 tệp migration gốc:
1. `V1__init_academic_catalog.sql` (16 bảng danh mục đào tạo, phòng học, học phần, kỳ học).
2. `V2__init_users_and_profiles.sql` (9 bảng người dùng, hồ sơ, phân quyền, token, face encodings).
3. `V3__init_classes_attendance_and_operations.sql` (25 bảng lớp học phần, lịch học, điểm danh, bài tập, chat, thông báo).

Các migration V1–V3 đã chạy thành công trên cả cơ sở dữ liệu PostgreSQL dev và H2 in-memory test suite (`mvn test` 30/30 pass). Hệ thống chạy cấu hình JPA Hibernate `ddl-auto: validate`.

Khi tiến hành kiểm kê chi tiết:
- Đã có 10 JPA Entities được ánh xạ (toàn bộ miền User, Profile, Security, FaceEncoding, SystemLog).
- 40 bảng còn lại (thuộc miền Đào tạo, Lịch học, Điểm danh, Trao đổi) đã có cấu trúc bảng chuẩn trong Flyway nhưng chưa khai báo JPA Entity trong Java.
- Ở bảng `student_attendances` (nhật ký điểm danh), schema hiện tại có index riêng lẻ trên `session_id` và `student_id` nhưng **chưa có ràng buộc UNIQUE** trên cặp `(session_id, student_id)`.

---

## 2. Quyết định kiến trúc (Decision)

### 2.1. Khóa bất biến đối với Flyway V1, V2, V3
- **Tuyệt đối không sửa đổi** nội dung của các tệp migration `V1__init_academic_catalog.sql`, `V2__init_users_and_profiles.sql`, `V3__init_classes_attendance_and_operations.sql`.
- Lý do: Bất kỳ sửa đổi nào vào tệp migration đã chạy sẽ làm sai lệch checksum trong bảng `flyway_schema_history`, gây lỗi khởi động nghiêm trọng (`Migration checksum mismatch`) trên tất cả môi trường đã triển khai.

### 2.2. Không tạo Migration V4 vật lý trong Task P01
- **Không vội vàng áp dụng migration V4** khi chưa bắt đầu triển khai business logic của Module 3.16 (Điểm danh).
- Lý do: Giữ môi trường ổn định, tránh phát sinh lỗi schema mismatch hoặc phá vỡ các luồng test đang chạy `ddl-auto: validate`.

### 2.3. Quy chuẩn cho Migration V4+ trong tương lai (Additive Migration Protocol)
Mọi migration từ V4 trở đi phải tuân thủ nghiêm ngặt các nguyên tắc sau:
1. **Tính chất Additive (Chỉ bổ sung, không phá vỡ)**: Chỉ thêm bảng mới, thêm cột có giá trị `DEFAULT` hoặc cho phép `NULL`, thêm index, thêm ràng buộc toàn vẹn. Tuyệt đối không xóa cột (`DROP COLUMN`) hay đổi tên cột (`RENAME COLUMN`) trên bảng đang chạy dữ liệu thực.
2. **Kiểm tra dữ liệu trước khi thêm Constraint**: Trước khi áp dụng `UNIQUE` constraint, phải có câu lệnh kiểm tra/dọn dẹp các bản ghi trùng lặp (nếu có).
3. **Luôn đi kèm kịch bản Rollback (Undo Script)**: Mỗi migration `V{x}__*.sql` phải có kịch bản hoàn nguyên `U{x}__*.sql` được lưu trữ sẵn sàng.

---

## 3. Dự thảo Kịch bản Migration V4+ (Sẽ kích hoạt tại Module Điểm danh 3.16)

### 3.1. Kịch bản UP (`V4__add_attendance_anti_duplication_constraint.sql`)
```sql
-- ==============================================================================
-- UniCheck - Flyway Migration V4: Attendance Anti-Duplication Constraint
-- ==============================================================================

-- 1. Bổ sung ràng buộc UNIQUE chống trùng điểm danh một sinh viên trong một buổi học
ALTER TABLE student_attendances 
ADD CONSTRAINT uq_student_attendances_session_student UNIQUE (session_id, student_id);

-- 2. Tối ưu hóa truy vấn tìm kiếm buổi điểm danh đang hoạt động của lịch học
CREATE INDEX IF NOT EXISTS idx_attendance_sessions_slot_status 
ON attendance_sessions (timetable_slot_id, status);

-- 3. Tối ưu hóa truy vấn tìm lịch học theo ngày và phòng học
CREATE INDEX IF NOT EXISTS idx_timetable_slots_room_date 
ON timetable_slots (room_id, date);
```

### 3.2. Kịch bản DOWN / Rollback (`U4__undo_attendance_anti_duplication_constraint.sql`)
```sql
-- ==============================================================================
-- UniCheck - Rollback Script for Migration V4
-- ==============================================================================

ALTER TABLE student_attendances 
DROP CONSTRAINT IF EXISTS uq_student_attendances_session_student;

DROP INDEX IF EXISTS idx_attendance_sessions_slot_status;
DROP INDEX IF EXISTS idx_timetable_slots_room_date;
```

---

## 4. Hệ quả & Đánh giá rủi ro (Consequences)

- **Tích cực**:
  - Bảo vệ 100% tính toàn vẹn của database hiện hữu và lịch sử Flyway.
  - Kiểm thử `mvn test` và khởi động Spring Boot luôn đạt kết quả PASS mà không lo xung đột schema.
  - Sẵn sàng kịch bản chống trùng điểm danh ở cấp độ cơ sở dữ liệu khi bắt đầu lập trình tính năng check-in.
- **Tiêu cực / Rủi ro**:
  - Trong giai đoạn hiện tại (trước khi chạy V4), việc chống trùng điểm danh phải dựa hoàn toàn vào kiểm tra tầng ứng dụng (application-level synchronization / query check).
