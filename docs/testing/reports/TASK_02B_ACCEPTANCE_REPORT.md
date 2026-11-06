# UniCheck — Biên Bản Nghiệm Thu Kỹ Thuật (Acceptance Report)
## TASK-02B: Class Section Management & Enrollment Management (F-14 & F-15)

> **Mã công việc:** `TASK-02B`  
> **Tính năng nghiệm thu:** F-14 (Quản lý Lớp học phần) & F-15 (Quản lý Ghi danh sinh viên)  
> **Phương pháp triển khai:** Full-Stack Vertical Slice Architecture  
> **Ngày thực hiện:** 16/10/2026  
> **Kỹ sư chịu trách nhiệm:** Senior Spring Boot Engineer, Senior React Engineer, Database Architect & QA Lead  
> **Trạng thái nghiệm thu:** **ACCEPTED (100% Passed)**  

---

## 1. Tóm Tắt Kết Quả Nghiệm Thu (Executive Summary)

Đợt triển khai TASK-02B đã hoàn thiện toàn diện hai chức năng lõi học vụ F-14 và F-15 xuyên suốt từ Cơ sở dữ liệu PostgreSQL 18 & Flyway Migration V4, JPA Entities, Spring Boot REST Services đến giao diện Web React 18 chuẩn Google Stitch (`Academic Precision`):

- **Cơ sở dữ liệu (PostgreSQL 18 & Flyway Migration V4):**
  - Tuân thủ chính xác bảng Flyway V1 hiện có:
    - Bảng `class_sections`: Khóa chính là `class_name VARCHAR(50)` (không thay bằng ID tự tăng surrogate key). Liên kết Foreign Key tới `courses(id)`, `semesters(id)` và `users(id)` cho giảng viên.
    - Bảng `enrollments`: Khóa chính `id BIGSERIAL`, liên kết `class_name VARCHAR(50)` và `student_id BIGINT` tới `users(id)`.
    - Bảng `teaching_assignments`: Ánh xạ phân công giảng dạy cho lớp học phần.
  - Tuyệt đối giữ nguyên vẹn không chỉnh sửa Flyway V1–V3.
  - Tạo mới migration an toàn [`V4__add_enrollment_unique_and_indexes.sql`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/resources/db/migration/V4__add_enrollment_unique_and_indexes.sql):
    - Unique Constraint `uk_enrollment_class_student` trên `enrollments(class_name, student_id)` ngăn ngừa triệt để race condition khi ghi danh trùng lặp.
    - Performance indexes tối ưu hóa truy vấn: `idx_enrollments_student_id`, `idx_enrollments_class_name`, `idx_class_sections_semester_id`, `idx_class_sections_course_id`, `idx_class_sections_lecturer_id`.

- **Backend (Spring Boot 3.3.4, Java 22):**
  - Đã triển khai 3 JPA Entities (`ClassSection`, `Enrollment`, `TeachingAssignment`) và 2 Enums (`ClassSectionStatus`, `EnrollmentStatus`).
  - Đã triển khai 3 Spring Data JPA Repositories (`ClassSectionRepository`, `EnrollmentRepository`, `TeachingAssignmentRepository`) kèm query đếm sĩ số, lọc theo học kỳ, và tìm kiếm.
  - Đã triển khai 2 Services (`ClassSectionServiceImpl`, `EnrollmentServiceImpl`) với các nghiệp vụ:
    - Kiểm tra `class_name` không trùng lặp khi tạo mới, không cho phép đổi primary key `class_name`.
    - Kiểm tra ràng buộc vai trò: Giảng viên phải có role `LECTURER`, Sinh viên phải có role `STUDENT`.
    - Chặn ghi danh vượt quá sĩ số tối đa của phòng học/lớp học phần (`numberOfSlots` / `maxStudents`).
    - Chặn ghi danh kép (2 lớp bảo vệ: Database Unique Constraint + Service check).
    - Chặn xóa hard-delete lớp học phần khi đã có sinh viên ghi danh hoặc phiên điểm danh.
    - RBAC phân quyền chặt chẽ theo principal người dùng đăng nhập (ADMIN có quyền quản trị toàn diện, LECTURER chỉ xem lớp được phân công, STUDENT chỉ xem lớp đã ghi danh).
  - Đã triển khai 2 REST Controllers (`ClassSectionController`, `EnrollmentController`) với tổng cộng **13 endpoints** hỗ trợ song song Dual-mapping (`/api/v1/...` và `/api/...`).
  - Toàn bộ **72/72 tests Spring Boot backend passed 100%** (`ClassSectionEnrollmentIntegrationTest` với 18 tests, `AcademicCatalogIntegrationTest`, `UserManagementIntegrationTest`, `AuthenticationIntegrationTest`).

- **Frontend (React 18, TypeScript 5.6, Tailwind CSS 3, Vite 5):**
  - Màn hình Stitch 1 — Lớp học phần (`495a21f075ca479698f5f5075cee8a41`):
    - Triển khai tại [`frontend/src/pages/admin/ClassSectionPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/admin/ClassSectionPage.tsx) (`/admin/classes` và `/dashboard/classes`).
    - Bố cục Bento Grid 4 cards thống kê (Tổng số lớp, Lớp đang hoạt động, Lớp đầy sĩ số, Tỷ lệ chuyên cần trung bình).
    - Dải tìm kiếm & lọc đa tiêu chí (học kỳ, học phần, trạng thái).
    - Bảng dữ liệu lớp học phần kèm thanh tiến độ sĩ số trực quan, trạng thái màu sắc Semantic.
    - Drawer trượt hiển thị danh sách sinh viên ghi danh và danh sách ca học.
    - Modal thêm mới / chỉnh sửa / xác nhận xóa an toàn.
  - Màn hình Stitch 2 — Ghi danh sinh viên (`1a99da032e154d86b432c579ec4e4bf1`):
    - Triển khai tại [`frontend/src/pages/admin/EnrollmentManagementPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/admin/EnrollmentManagementPage.tsx) (`/admin/enrollments` và `/dashboard/enrollments`).
    - Bento chọn học kỳ điều hành và lớp học phần mục tiêu (hỗ trợ liên kết trực tiếp qua URL `?className=...`).
    - Bento Ribbon 4 chỉ số sĩ số và hiệu suất chuyên cần (Công suất phòng, Tỷ lệ chuyên cần chung, Đủ điều kiện dự thi, Cảnh báo cấm thi >20% vắng).
    - Panel ghi danh bổ sung thời gian thực tích hợp Động cơ kiểm duyệt xung đột (tra cứu sinh viên, chỉ báo lịch học hợp lệ, phát hiện trùng lặp).
    - Khối hiển thị báo cáo kiểm duyệt tệp ghi danh (DS_Ghidanh_Dot1.xlsx) với các thẻ lỗi phân loại chi tiết.
    - Bảng danh sách sinh viên chính thức: STT, MSSV, Họ tên (ảnh thẻ sinh viên), Lớp sinh hoạt, Ngày ghi danh, Tình trạng học phí, Tỷ lệ vắng/tổng, Trạng thái Face-ID Kiosk, Thao tác chuyển lớp / xem lịch sử / hủy ghi danh.
    - Modal xác nhận hủy ghi danh an toàn (Safety Academic Guard) với lý do bắt buộc lưu trữ.
    - Modal tải lên file Excel ghi danh hàng loạt.
  - Khai báo 2 API clients [`classes.api.ts`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/api/classes.api.ts) và [`enrollments.api.ts`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/api/enrollments.api.ts).
  - Cập nhật định tuyến React Router trong [`frontend/src/routes/index.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/routes/index.tsx) và thanh điều hướng trong [`frontend/src/config/navigation.config.ts`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/config/navigation.config.ts).
  - Toàn bộ **32/32 tests frontend passed 100%** (`class-section-enrollment.test.ts`, `academic-catalog.test.ts`, `user-management.test.ts`, `auth-module.test.ts`).
  - Đóng gói Vite production thành công: `tsc -b && vite build` (0 lỗi, hoàn thành trong 21.68s).

---

## 2. Ma Trận Đối Chiếu Chi Tiết (Detailed Verification Matrix)

### 2.1. Phân hệ F-14: Quản Lý Lớp Học Phần (Class Sections)

| STT | Yêu cầu Kỹ thuật / SDD | Thành phần triển khai | Trạng thái | Bằng chứng & Ghi chú |
| :---: | :--- | :--- | :---: | :--- |
| 1 | Bảng dữ liệu PostgreSQL | `class_sections` (PK: `class_name`) | PASSED | Schema V1 giữ nguyên vẹn, PK `class_name VARCHAR(50)` |
| 2 | JPA Entity & Enums | `ClassSection.java`, `ClassSectionStatus.java` | PASSED | `@Id` String, `@ManyToOne` LAZY tới Course, Semester, User |
| 3 | Repository & Custom Queries | `ClassSectionRepository.java` | PASSED | Tìm kiếm phân trang, lọc theo học kỳ, giảng viên, đếm sĩ số |
| 4 | Kiểm tra trùng lặp mã lớp | `ClassSectionServiceImpl.createClassSection` | PASSED | Ném `CLASS_ALREADY_EXISTS` nếu `class_name` đã tồn tại |
| 5 | Bất biến Primary Key | `ClassSectionServiceImpl.updateClassSection` | PASSED | Không cho phép đổi `class_name`, chỉ sửa thông tin thuộc tính |
| 6 | Chặn xóa lớp có dữ liệu phụ thuộc | `ClassSectionServiceImpl.deleteClassSection` | PASSED | Chặn xóa khi có sinh viên ghi danh hoặc lịch sử phiên |
| 7 | 8 REST Endpoints | `ClassSectionController.java` | PASSED | Dual-mapping `/api/v1/classes` & `/api/classes` |
| 8 | Giao diện chuẩn Stitch Screen 1 | `ClassSectionPage.tsx` | PASSED | Bento metrics, bộ lọc, bảng dữ liệu, drawer roster, modals |
| 9 | RBAC Guard | `@PreAuthorize` + `AdminRoute` | PASSED | ADMIN quản trị; LECTURER giới hạn theo lớp phụ trách |

### 2.2. Phân hệ F-15: Quản Lý Ghi Danh Sinh Viên (Enrollments)

| STT | Yêu cầu Kỹ thuật / SDD | Thành phần triển khai | Trạng thái | Bằng chứng & Ghi chú |
| :---: | :--- | :--- | :---: | :--- |
| 1 | Bảng dữ liệu PostgreSQL | `enrollments` (PK: `id BIGSERIAL`) | PASSED | FK `class_name` và `student_id` |
| 2 | Migration V4 Constraints | `V4__add_enrollment_unique_and_indexes.sql` | PASSED | `uk_enrollment_class_student` chống race condition |
| 3 | JPA Entity & Enums | `Enrollment.java`, `EnrollmentStatus.java` | PASSED | `@ManyToOne` LAZY tới ClassSection và User |
| 4 | Kiểm tra vai trò sinh viên | `EnrollmentServiceImpl.enrollStudent` | PASSED | Ném `INVALID_STUDENT_ROLE` nếu người dùng không phải STUDENT |
| 5 | Chặn ghi danh trùng lặp | Service + Database Unique Constraint | PASSED | Ném `DUPLICATE_ENROLLMENT` (`ERR_409`) |
| 6 | Kiểm tra giới hạn sĩ số | `EnrollmentServiceImpl.enrollStudent` | PASSED | Ném `CLASS_CAPACITY_EXCEEDED` nếu lớp đã đủ chỗ |
| 7 | 5 REST Endpoints | `EnrollmentController.java` | PASSED | Dual-mapping `/api/v1/enrollments` & `/api/enrollments` |
| 8 | Nested Route lấy/thêm SV | `ClassSectionController` `/classes/{name}/students` | PASSED | Trả về danh sách sinh viên ghi danh của lớp |
| 9 | Giao diện chuẩn Stitch Screen 2 | `EnrollmentManagementPage.tsx` | PASSED | Bento chọn lớp, Ribbon 4 chỉ số, Conflict Engine, Modal xóa an toàn |

---

## 3. Bằng Chứng Kiểm Thử Tự Động (Automated Test Evidence)

### 3.1. Spring Boot Backend Test Suite (`mvn test`)
```text
[INFO] Running com.unicheck.controller.ClassSectionEnrollmentIntegrationTest
2026-10-16T13:44:28.140+07:00  INFO 24264 --- [unicheck-backend-test] [           main] c.u.c.ClassSectionEnrollmentIntegrationTest : Started ClassSectionEnrollmentIntegrationTest in 3.421 seconds
[INFO] Tests run: 18, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 2.145 s -- in com.unicheck.controller.ClassSectionEnrollmentIntegrationTest
[INFO] Running com.unicheck.controller.AcademicCatalogIntegrationTest
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.802 s
[INFO] Running com.unicheck.controller.UserManagementIntegrationTest
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.154 s
[INFO] Running com.unicheck.controller.AuthenticationIntegrationTest
[INFO] Tests run: 14, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.120 s
...
[INFO] Results:
[INFO] Tests run: 72, Failures: 0, Errors: 0, Skipped: 0
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  24.715 s
[INFO] Finished at: 2026-10-16T13:44:39+07:00
```

### 3.2. React Frontend Test Suite (`npm test`)
```text
> unicheck-web@1.0.0 test
> node --experimental-strip-types --test src/test/*.test.ts

✔ 1. Course Creation Contract & Credit Constraints (1.494ms)
✔ 2. Course Code & Credits Boundary Constraints (0.1813ms)
✔ 3. Circular Prerequisite Detection Logic (0.1599ms)
✔ 4. Referential Integrity Guard (Cannot delete prerequisite course) (0.1827ms)
✔ 5. Semester Date Chronological Ordering Contract (0.1408ms)
✔ 6. Semester Configuration & Threshold Constraints (0.1067ms)
✔ 7. Active Semester State Transition Rule (0.1414ms)
✔ 8. RBAC Guard for Academic Catalog & Semesters (0.1499ms)
✔ 1. Flat Login Response Schema Contract Verification (0.9633ms)
✔ 2. Token Storage and Session Persistence (0.2022ms)
✔ 3. Refresh Token Rotation (RTR) Updates (0.135ms)
✔ 4. Complete Logout Cleanup and Sanitization (0.1386ms)
✔ 5. Form Validation: Email Regex, Password Strength and OTP Constraints (0.3365ms)
✔ 6. Mandatory Initial Password Change Policy (0.1218ms)
✔ 7. Profile Update Authorization Boundary: No Role or Permissions Tampering (0.1244ms)
✔ 8. ErrorCode Dictionary & User-Friendly Vietnamese Mapping (0.1271ms)
✔ 9. Security Sanitization: Sensitive Data Is Never Leaked (0.1962ms)
✔ 10. Safe Non-Revealing Forgot Password Contract (0.2665ms)
✔ 1. ClassSectionCreateRequest Contract & Primary Key Validation (0.7801ms)
✔ 2. Class Section Primary Key & Capacity Constraints (0.2004ms)
✔ 3. Class Capacity Guard: Prevent Enrolling Past Max Slots (0.1169ms)
✔ 4. Enrollment Duplicate Prevention Guard (0.1446ms)
✔ 5. Student Role Enforcement for Enrollment (0.1548ms)
✔ 6. Class Section Status Lifecycle Validation (0.137ms)
✔ 7. Capacity Update Guard: Cannot Reduce Below Enrolled Count (0.1095ms)
✔ 8. RBAC Matrix for Class & Enrollment Management (0.1064ms)
✔ 1. User Creation DTO Validation Contract (0.8114ms)
✔ 2. User Status Update Contract (Lock/Unlock) (0.1425ms)
✔ 3. RBAC Admin-Only Access Guard Verification (0.1368ms)
✔ 4. Self-Locking Prevention Guard Logic (0.1437ms)
✔ 5. CSV Import Header Validation & Record Parsing Logic (0.2115ms)
✔ 6. CSV Import Result Envelope Structure (0.0936ms)
ℹ tests 32
ℹ suites 0
ℹ pass 32
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 138.9962
```

### 3.3. Frontend Production Build (`npm run build`)
```text
> unicheck-web@1.0.0 build
> tsc -b && vite build

vite v5.4.21 building for production...
transforming...
✓ 1674 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.86 kB │ gzip:   0.53 kB
dist/assets/index-xjN6yWEk.css   45.33 kB │ gzip:   8.60 kB
dist/assets/index-zxottTZT.js   568.47 kB │ gzip: 145.45 kB
✓ built in 21.68s
```

---

## 4. Kết Luận & Bàn Giao

TASK-02B đã hoàn thành toàn diện 100% mục tiêu:
1. Đảm bảo toàn vẹn dữ liệu schema PostgreSQL hiện hữu (`class_sections`, `enrollments`, `teaching_assignments`).
2. Bổ sung migration Flyway V4 an toàn với unique constraint và performance indexes.
3. Hoàn thiện 13 REST APIs Spring Boot chuẩn OpenAPI kèm RBAC.
4. Tái hiện trung thực 2 màn hình Google Stitch (`495a21f075ca479698f5f5075cee8a41` và `1a99da032e154d86b432c579ec4e4bf1`) trên React 18, Tailwind CSS và TypeScript.
5. Kiểm thử tự động 100% Passed trên cả Backend (72 tests) và Frontend (32 tests), không có lỗi biên dịch.
