# UNICHECK – FPT DEMO DATA ENUM MISMATCH FIX & REGRESSION TEST REPORT

**Dự án:** UniCheck – Smart Multi-Platform Attendance System  
**Ngày thực hiện:** 29/10/2026  
**Chuyên gia thực hiện:** Senior Spring Boot Engineer, PostgreSQL DBA & QA Lead  
**Trạng thái hệ thống:** ĐÃ KHẮC PHỤC HOÀN TOÀN – HỆ THỐNG HOẠT ĐỘNG ỔN ĐỊNH 100%

---

## 1. TỔNG QUAN VẤN ĐỀ & NGUYÊN NHÂN GỐC RỄ (ROOT CAUSE)

Sau khi nhập bộ dữ liệu FPT University Demo vào cơ sở dữ liệu `unicheck_db`, phát hiện 2 API backend trả về mã lỗi **HTTP 500** do sự bất tương thích giữa chuỗi dữ liệu trong cơ sở dữ liệu và enum Java (JPA Hibernate ánh xạ qua `@Enumerated(EnumType.STRING)`):

### 1.1. BUG-01: `SemesterStatus.COMPLETED` Không Hợp Lệ
* **Triệu chứng:** Khi người dùng truy vấn danh sách học kỳ `GET /api/v1/semesters?size=10`, hệ thống ném ra ngoại lệ:
  ```
  java.lang.IllegalArgumentException: No enum constant com.unicheck.model.enums.SemesterStatus.COMPLETED
  ```
* **Nguyên nhân gốc rễ:** 
  - Trong Java, enum `com.unicheck.model.enums.SemesterStatus` chỉ hỗ trợ 4 giá trị: `ACTIVE`, `UPCOMING`, `CLOSED`, `ARCHIVED`.
  - Bộ sinh dữ liệu FPT (`scrapers/fptu_scraper.py`) đã tự gán cho 2 học kỳ cũ `SPRING2026` và `SUMMER2026` trạng thái `COMPLETED` (vốn là logic ngoài đặc tả hệ thống UniCheck).
  - Khi Spring Data JPA đọc bản ghi từ PostgreSQL và ép kiểu sang enum Java, Hibernate gặp chuỗi không khớp và throw ngoại lệ runtime.

### 1.2. BUG-02: `TimetableSlotStatus.IN_PROGRESS` Không Hợp Lệ
* **Triệu chứng:** Khi truy vấn danh sách tiết học `GET /api/v1/timetable/slots` hoặc tải trang chi tiết ca học, hệ thống ném ra ngoại lệ:
  ```
  java.lang.IllegalArgumentException: No enum constant com.unicheck.model.enums.TimetableSlotStatus.IN_PROGRESS
  ```
* **Nguyên nhân gốc rễ:**
  - Trong Java, enum `com.unicheck.model.enums.TimetableSlotStatus` chỉ hỗ trợ 4 giá trị: `SCHEDULED`, `COMPLETED`, `CANCELLED`, `RESCHEDULED`.
  - Bộ sinh dữ liệu tổng hợp (`generators/synthetic_generator.py`) đã gán trạng thái `IN_PROGRESS` cho 8 tiết học (Slot 4..14 thuộc ngày 02/11/2026 đến 04/11/2026).
  - Về mặt kiến trúc UniCheck: Trạng thái đang diễn ra (`OPEN`) được quản lý trên thực thể phiên điểm danh `attendance_sessions` (`CREATED`, `OPEN`, `CLOSED`, `CANCELLED`), trong khi tiết học trong thời khóa biểu (`timetable_slots`) phải giữ trạng thái `SCHEDULED` để hiển thị trên lịch tuần và phục vụ sinh viên/giảng viên trước khi kết thúc học phần.

---

## 2. KIỂM TOÁN TOÀN DIỆN ENUM TRÊN DATABASE (PHASE 1 AUDIT)

Đã đối soát toàn bộ 12 Enums Java của UniCheck với tất cả các bảng dữ liệu trong `unicheck_db`:
1. `Role` (`ADMIN`, `LECTURER`, `STUDENT`) -> 100% Khớp.
2. `UserStatus` (`ACTIVE`, `INACTIVE`, `SUSPENDED`) -> 100% Khớp.
3. `FaceDataStatus` (`NOT_REGISTERED`, `PENDING_APPROVAL`, `REGISTERED`, `REJECTED`) -> 100% Khớp.
4. `CourseStatus` (`ACTIVE`, `INACTIVE`, `ARCHIVED`) -> 100% Khớp.
5. `ClassSectionStatus` (`OPEN`, `ACTIVE`, `CLOSED`, `CANCELLED`) -> 100% Khớp.
6. `EnrollmentStatus` (`ENROLLED`, `DROPPED`, `CANCELLED`) -> 100% Khớp.
7. `RoomType` (`LECTURE_HALL`, `CLASSROOM`, `LAB`, `MEETING_ROOM`) -> 100% Khớp.
8. `RoomStatus` (`AVAILABLE`, `MAINTENANCE`, `OCCUPIED`, `DISABLED`) -> 100% Khớp.
9. `WifiApStatus` (`ACTIVE`, `INACTIVE`, `MAINTENANCE`) -> 100% Khớp.
10. `AttendanceSessionStatus` (`CREATED`, `OPEN`, `CLOSED`, `CANCELLED`) -> 100% Khớp.
11. **`SemesterStatus`**: Phát hiện **2 bản ghi lỗi** (`status = 'COMPLETED'`).
12. **`TimetableSlotStatus`**: Phát hiện **8 bản ghi lỗi** (`status = 'IN_PROGRESS'`).

> **Kết luận kiểm toán:** Toàn bộ cơ sở dữ liệu chỉ có chính xác 10 bản ghi không tương thích nằm trong 2 bảng `semesters` và `timetable_slots`.

---

## 3. THỰC HIỆN BẢO VỆ & VÁ DỮ LIỆU AN TOÀN (SAFE DATA PATCH)

Quy trình vá dữ liệu tuân thủ nghiêm ngặt chuẩn Database Administrator an toàn:

### Bước 1: Sao lưu các bản ghi bị ảnh hưởng trước khi vá
- Lưu tại: `backend/backups/pre_patch_records_backup_20261029.sql`.
- Lưu trữ snapshot trạng thái gốc của 2 học kỳ và 8 tiết học trước khi cập nhật.

### Bước 2: Tạo script vá dữ liệu có Transaction & Khẳng định toàn vẹn
- Script: `backend/scripts/patch_fpt_seed_enum_mismatch.sql`
- Nội dung logic:
  ```sql
  BEGIN;

  -- 1. Vá SemesterStatus: COMPLETED -> CLOSED
  UPDATE semesters
  SET status = 'CLOSED', updated_at = CURRENT_TIMESTAMP
  WHERE status = 'COMPLETED';

  -- 2. Vá TimetableSlotStatus: IN_PROGRESS -> SCHEDULED
  UPDATE timetable_slots
  SET status = 'SCHEDULED', updated_at = CURRENT_TIMESTAMP
  WHERE status = 'IN_PROGRESS';

  -- 3. Khẳng định toàn vẹn (Safety Assertion Guard)
  DO $$
  DECLARE
      invalid_semesters INT;
      invalid_slots INT;
  BEGIN
      SELECT COUNT(*) INTO invalid_semesters FROM semesters WHERE status = 'COMPLETED';
      SELECT COUNT(*) INTO invalid_slots FROM timetable_slots WHERE status = 'IN_PROGRESS';

      IF invalid_semesters > 0 OR invalid_slots > 0 THEN
          RAISE EXCEPTION 'Assertion Failed: Vẫn còn bản ghi mang giá trị enum không hợp lệ!';
      END IF;
  END $$;

  COMMIT;
  ```

### Bước 3: Kiểm thử trên Clone Database Cô Lập (`unicheck_patch_test`)
- Đã sao chép DB tạm thời `unicheck_patch_test` từ `unicheck_db`.
- Áp dụng patch: Thực thi thành công trong 15ms. Khẳng định an toàn không lỗi.
- Đã giải phóng database tạm `DROP DATABASE unicheck_patch_test`.

### Bước 4: Áp dụng lên Cơ Sở Dữ Liệu Phát Triển (`unicheck_db`)
- Đã áp dụng giao dịch lên `unicheck_db`:
  - `UPDATE 2` trên bảng `semesters` (`SPRING2026`, `SUMMER2026` chuyển sang `CLOSED`).
  - `UPDATE 8` trên bảng `timetable_slots` (các slot ngày 02..04/11 chuyển sang `SCHEDULED`).
- Khẳng định an toàn: Số lượng bản ghi `COMPLETED` và `IN_PROGRESS` trên DB = **0**.

---

## 4. CHỈNH SỬA TẬN GỐC NGUỒN TẠO DỮ LIỆU SEED (SOURCE PIPELINE)

Để đảm bảo các lần chạy scraping và seed trong tương lai không bao giờ tái diễn lỗi này, mã nguồn thu thập và tạo dữ liệu đã được cập nhật:

1. **`tools/fpt-data-collector/models.py`:**
   - Định nghĩa kiểu nghiêm ngặt `Literal` thay vì `str`:
     ```python
     status: Literal["ACTIVE", "UPCOMING", "CLOSED", "ARCHIVED"] = "ACTIVE"
     status: Literal["SCHEDULED", "COMPLETED", "CANCELLED", "RESCHEDULED"] = "SCHEDULED"
     ```
2. **`tools/fpt-data-collector/scrapers/fptu_scraper.py`:**
   - Cập nhật học kỳ đã kết thúc `SPRING2026` và `SUMMER2026` sang `status="CLOSED"`.
3. **`tools/fpt-data-collector/generators/synthetic_generator.py`:**
   - Sửa logic sinh trạng thái slot: Các slot chưa diễn ra được gán `s_status = "SCHEDULED"`.
4. **Tái tạo Artifacts:**
   - Tái tạo `tools/fpt-data-collector/data/seeds/01_fpt_master_demo_seed.sql`.
   - Tái tạo `tools/fpt-data-collector/data/normalized/fpt_master_demo_dataset.json`.
   - Xác minh: Cả 2 tệp trên có đúng **0** từ khóa `'IN_PROGRESS'` và **0** từ khóa `'COMPLETED'` cho `semesters`.

---

## 5. BỔ SUNG BÀI KIỂM THỬ TỰ ĐỘNG (AUTOMATED TEST SUITE)

Đã bổ sung các bài kiểm tra tự động chuyên biệt để ngăn chặn hồi quy (Regression Prevention):

### 5.1. Python Collector Enum Compliance Test
- **File:** `tools/fpt-data-collector/tests/test_collector.py`
- **Method:** `test_enum_compliance_for_java_jpa()`
- **Mục tiêu:** Quét toàn bộ danh sách bản ghi sinh ra và kiểm tra tính hợp lệ của enum với `VALID_SEMESTER_STATUSES`, `VALID_SLOT_STATUSES`, `VALID_SESSION_STATUSES`, `VALID_ATTENDANCE_STATUSES`, `VALID_USER_ROLES`, `VALID_USER_STATUSES`, `VALID_FACE_STATUSES`.
- **Kết quả:** `5 passed in 0.73s`.

### 5.2. Spring Boot Academic Catalog Integration Test
- **File:** `backend/src/test/java/com/unicheck/controller/AcademicCatalogIntegrationTest.java`
- **Method:** `shouldQuerySemestersWithAllValidStatusesSuccessfully()`
- **Mục tiêu:** Tạo các học kỳ với các trạng thái `ACTIVE`, `CLOSED`, `UPCOMING`. Gọi `GET /api/v1/semesters` và lọc `status=CLOSED`, kiểm tra serialization/deserialization JSON không lỗi 500.

### 5.3. Spring Boot Timetable Integration Test
- **File:** `backend/src/test/java/com/unicheck/controller/TimetableIntegrationTest.java`
- **Method:** `testTimetableSlotsWithValidStatuses()`
- **Mục tiêu:** Lưu các tiết học với các trạng thái `SCHEDULED`, `COMPLETED`, `CANCELLED`, `RESCHEDULED`. Gọi `GET /api/v1/timetable/slots` và lọc `status=SCHEDULED`, đảm bảo HTTP 200 OK và cấu trúc DTO chính xác.

---

## 6. KẾT QUẢ KIỂM THỬ HỒI QUY TOÀN DIỆN (FULL REGRESSION TESTING)

Toàn bộ hệ thống UniCheck đã được chạy kiểm thử đầy đủ ở tất cả các tầng:

| Tầng kiểm thử | Công cụ / Lệnh | Số lượng Test | Kết quả | Ghi chú |
| :--- | :--- | :---: | :---: | :--- |
| **Python Collector** | `pytest tools/fpt-data-collector/tests` | 5 | **PASS (5/5)** | Bao gồm kiểm thử tính tương thích enum JPA |
| **Backend API / Domain** | `mvn test -Dtest=AcademicCatalog...,Timetable...` | 21 | **PASS (21/21)** | Các endpoint bị lỗi trước đó đã PASS hoàn toàn |
| **Full Backend Suite** | `mvn test` (toàn bộ backend) | 165 | **PASS (165/165)** | 0 failures, 0 errors, 0 skipped |
| **Mobile Flutter** | `flutter test` | 89 | **PASS (89/89)** | Toàn bộ widget & unit tests mobile hoạt động chuẩn |
| **Frontend Unit Tests** | `npm test` | 114 | **PASS (114/114)** | Không có lỗi logic UI/Contract |
| **Frontend Build** | `npm run build` (`tsc -b && vite build`) | Bundle | **SUCCESS** | Biên dịch TypeScript & Vite không có lỗi syntax |
| **Database Timetable Collisions** | SQL Cross-Join Checking | 3 checks | **0 Xung đột** | 0 phòng, 0 giảng viên, 0 sinh viên trùng lịch |

---

## 7. KIỂM THỬ VẬN HÀNH TRÊN HỆ THỐNG THỰC TẾ (LIVE API VERIFICATION)

Đã gửi các yêu cầu HTTP thực tế tới dịch vụ Spring Boot đang chạy tại cổng `8080`:

1. **`GET /api/v1/semesters?size=10`**:
   - **Mã phản hồi:** HTTP 200 OK.
   - **Dữ liệu:** 3 học kỳ (`FALL2026` [ACTIVE], `SUMMER2026` [CLOSED], `SPRING2026` [CLOSED]).
2. **`GET /api/v1/semesters/active`**:
   - **Mã phản hồi:** HTTP 200 OK.
   - **Dữ liệu:** `FALL2026` (Active).
3. **`GET /api/v1/timetable/slots?startDate=2026-10-01&endDate=2026-12-31`**:
   - **Mã phản hồi:** HTTP 200 OK.
   - **Dữ liệu:** 132 slots được trả về chính xác với định dạng thời gian và phòng học.
4. **`GET /api/v1/timetable/me` (Giảng viên & Sinh viên)**:
   - **Mã phản hồi:** HTTP 200 OK.
   - **Dữ liệu:** Trả về chính xác các tiết học được phân công và ghi danh.
5. **Phiên điểm danh Session 43 & Mã QR Động**:
   - `GET /api/v1/attendance/sessions/43`: HTTP 200 OK (Status: `OPEN`).
   - `GET /api/v1/attendance/sessions/43/qr`: HTTP 200 OK (Sinh mã JWT Dynamic QR có thời hạn 15s).
   - `POST /api/v1/attendance/qr/validate`: HTTP 200 OK (Sinh viên quét mã xác thực `valid: true`, liên kết đúng lớp `SE1801-PRJ301` và phòng `AL-L201`).

---

## 8. CAM KẾT TOÀN VẸN DỮ LIỆU ĐẶC BIỆT

- **Dữ liệu FaceID:**
  - Bản ghi sinh trắc khuôn mặt gốc của User ID 2 (Vector 2048-byte) được **bảo toàn nguyên vẹn**.
  - Bản ghi sinh trắc mới đăng ký của User ID 14 (`sv_he180001`) được **bảo toàn nguyên vẹn**.
- **Tài khoản & Phân quyền:**
  - Không có người dùng nào bị thay đổi mật khẩu hoặc quyền hạn ngoài ý muốn.
  - Các tài khoản thực tế (`admin`, `datlt`, `thanhnv`) hoạt động bình thường song song với các tài khoản thử nghiệm của FPT.
- **Migration Flyway:** Không thay đổi bất kỳ file migration V1–V7 nào, đảm bảo tính bất biến của lịch sử migration.

---

## 9. KẾT LUẬN & KIẾN NGHỊ

1. Sự cố bất tương thích enum (BUG-01 và BUG-02) đã được xử lý dứt điểm từ cơ sở dữ liệu thực tế, bộ công cụ tạo seed, cho đến các bài kiểm thử tự động của dự án.
2. Hệ thống UniCheck hiện tại sẵn sàng 100% cho việc demo, kiểm thử nghiệp vụ và vận hành trên môi trường Development.
