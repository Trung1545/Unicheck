# UniCheck — Biên Bản Nghiệm Thu Kỹ Thuật (Acceptance Report)
## TASK-02A: Semester & Course Catalog Management (F-11 & F-12)

> **Mã công việc:** `TASK-02A`  
> **Tính năng nghiệm thu:** F-11 (Quản lý Danh mục Môn học) & F-12 (Quản lý Học kỳ & Niên khóa)  
> **Phương pháp triển khai:** Vertical Slice Architecture  
> **Ngày thực hiện:** 15/10/2026  
> **Kỹ sư chịu trách nhiệm:** Senior Spring Boot Engineer & React Engineer  
> **Trạng thái nghiệm thu:** **ACCEPTED (100% Passed)**  

---

## 1. Tóm Tắt Kết Quả Nghiệm Thu (Executive Summary)

Đợt triển khai TASK-02A đã hoàn thiện toàn diện hai chức năng lõi học thuật F-11 và F-12 xuyên suốt từ Cơ sở dữ liệu Flyway V1, JPA Entities, Spring Boot REST Services đến giao diện Web React 18 chuẩn Google Stitch (`Academic Precision`).

- **Backend (Spring Boot 3.3.4, Java 21):**
  - Đã triển khai 3 JPA Entities (`Course`, `Semester`, `SemesterConfig`) và 2 Enums (`CourseStatus`, `SemesterStatus`).
  - Đã triển khai 3 Spring Data JPA Repositories với query kiểm tra toàn vẹn khóa ngoại.
  - Đã triển khai 2 Services (`CourseServiceImpl`, `SemesterServiceImpl`) với logic chống phụ thuộc vòng (DFS cycle detection), chống xóa môn học đang làm tiên quyết, tự động đóng học kỳ cũ khi kích hoạt học kỳ mới, và kiểm tra thứ tự thời gian.
  - Đã triển khai 2 REST Controllers với tổng cộng **15 endpoints** hỗ trợ song song Dual-mapping (`/api/v1/...` và `/api/...`).
  - Toàn bộ **54/54 tests Spring Boot backend passed 100%** (`AcademicCatalogIntegrationTest`, `UserManagementIntegrationTest`, `AuthenticationIntegrationTest`).

- **Frontend (React 18, TypeScript 5.6, Tailwind CSS 3, Vite 5):**
  - Màn hình Stitch Courses (`a9f520acd00440c8a26633aec9a8799c`) -> Triển khai tại [`frontend/src/pages/admin/CourseCatalogPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/admin/CourseCatalogPage.tsx) (`/admin/courses`).
  - Màn hình Stitch Semesters (`4f0245590b1b4c6ab231b412b5ba845d`) -> Triển khai tại [`frontend/src/pages/admin/SemesterManagementPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/admin/SemesterManagementPage.tsx) (`/admin/semesters`).
  - Tái sử dụng triệt để `common-ui` (`Button`, `Badge`, `Modal`, `Pagination`, `Skeleton`, `EmptyState`), `MainLayout`, `AdminRoute`.
  - Khai báo 2 API clients chuyên biệt [`courses.api.ts`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/api/courses.api.ts) và [`semesters.api.ts`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/api/semesters.api.ts) kết nối Axios instance thực tế.
  - Toàn bộ **24/24 tests frontend passed 100%** (`academic-catalog.test.ts`, `user-management.test.ts`, `auth-module.test.ts`).
  - Biên dịch TypeScript và đóng gói Vite production thành công: `tsc -b && vite build` (0 lỗi, hoàn thành trong 14.19s).

- **Cơ sở dữ liệu (PostgreSQL 15):**
  - Khớp 100% Flyway schema V1 hiện có (`courses`, `course_prerequisites`, `semesters`, `semester_configs`, `holidays`, `slot_types`).
  - Tuyệt đối không thay đổi migrations V1–V3, không tạo bảng trùng.

---

## 2. Ma Trận Đối Chiếu Chi Tiết (Detailed Verification Matrix)

### 2.1. Phân hệ F-11: Quản Lý Học Phần (Courses)

| STT | Yêu cầu Kỹ thuật / SDD | Thành phần triển khai | Trạng thái | Ghi chú & Bằng chứng |
| :---: | :--- | :--- | :---: | :--- |
| 1 | Bảng dữ liệu Flyway | `courses`, `course_prerequisites` | PASSED | Schema V1 giữ nguyên vẹn |
| 2 | JPA Entity & Enums | `Course.java`, `CourseStatus.java` | PASSED | Khóa chính tự tăng, `@ManyToMany` cho bảng trung gian `course_prerequisites` |
| 3 | Repository & Custom Query | `CourseRepository.java` | PASSED | Phương thức `isPrerequisiteForOthers(id)` kiểm tra toàn vẹn |
| 4 | Chống phụ thuộc vòng | `CourseServiceImpl.checkCircularDependency` | PASSED | Thuật toán DFS phát hiện cycle trước khi persist |
| 5 | Chặn xóa môn học đang được tham chiếu | `CourseServiceImpl.deleteCourse` | PASSED | Ném `CANNOT_DELETE_REFERENCED_RESOURCE` (`ERR_4005`) |
| 6 | 7 REST Endpoints | `CourseController.java` | PASSED | Hỗ trợ phân trang, lọc tín chỉ/trạng thái, tìm kiếm, check mã, CRUD |
| 7 | Giao diện chuẩn Stitch | `CourseCatalogPage.tsx` | PASSED | Bento grid 5 cards thống kê, bảng phân trang, drawer trượt thêm/sửa, modal xóa |
| 8 | RBAC Guard | `AdminRoute` + `@PreAuthorize` | PASSED | Chỉ `ADMIN` được tạo/sửa/xóa, các vai trò khác chỉ được đọc |

### 2.2. Phân hệ F-12: Quản Lý Học Kỳ & Niên Khóa (Semesters)

| STT | Yêu cầu Kỹ thuật / SDD | Thành phần triển khai | Trạng thái | Ghi chú & Bằng chứng |
| :---: | :--- | :--- | :---: | :--- |
| 1 | Bảng dữ liệu Flyway | `semesters`, `semester_configs` | PASSED | Schema V1 giữ nguyên vẹn |
| 2 | JPA Entity & Enums | `Semester.java`, `SemesterConfig.java`, `SemesterStatus.java` | PASSED | Quan hệ `@OneToOne` với cấu hình ca học |
| 3 | Repository | `SemesterRepository.java`, `SemesterConfigRepository.java` | PASSED | Tìm kiếm theo mã, trạng thái, học kỳ ACTIVE hiện hành |
| 4 | Kiểm tra thời gian bắt đầu & kết thúc | `SemesterServiceImpl.validateSemesterDates` | PASSED | Ném `INVALID_INPUT` (`ERR_4001`) nếu `startDate >= endDate` |
| 5 | Quy tắc đơn nhất học kỳ ACTIVE | `SemesterServiceImpl.createSemester/updateSemester` | PASSED | Tự động chuyển các học kỳ `ACTIVE` cũ sang `CLOSED` |
| 6 | Khóa học kỳ (Lock Semester) | `PATCH /api/v1/semesters/{id}/lock` | PASSED | Chuyển học kỳ sang `CLOSED`, chặn cập nhật lịch học |
| 7 | 8 REST Endpoints | `SemesterController.java` | PASSED | Phân trang, lấy học kỳ hiện hành, check trùng mã, lock, CRUD |
| 8 | Giao diện chuẩn Stitch | `SemesterManagementPage.tsx` | PASSED | Card học kỳ hiện hành nổi bật, grid thống kê, bảng phân trang, modal thêm/sửa |

---

## 3. Bằng Chứng Kiểm Thử Tự Động (Automated Test Evidence)

### 3.1. Spring Boot Backend Test Suite (`mvn test`)
```text
[INFO] Running com.unicheck.controller.AcademicCatalogIntegrationTest
2026-10-15T14:48:05.120+07:00  INFO 21340 --- [unicheck-backend-test] [           main] c.u.c.AcademicCatalogIntegrationTest     : Started AcademicCatalogIntegrationTest in 3.125 seconds
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.842 s -- in com.unicheck.controller.AcademicCatalogIntegrationTest
...
[INFO] Running com.unicheck.controller.UserManagementIntegrationTest
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.215 s
...
[INFO] Running com.unicheck.controller.AuthenticationIntegrationTest
[INFO] Tests run: 14, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.410 s
...
[INFO] Results:
[INFO] Tests run: 54, Failures: 0, Errors: 0, Skipped: 0
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

### 3.2. React Frontend Test Suite (`npm test`)
```text
> unicheck-web@1.0.0 test
> node --experimental-strip-types --test src/test/*.test.ts

✔ 1. Course Creation Contract & Credit Constraints (2.274ms)
✔ 2. Course Code & Credits Boundary Constraints (0.3379ms)
✔ 3. Circular Prerequisite Detection Logic (0.2906ms)
✔ 4. Referential Integrity Guard (Cannot delete prerequisite course) (0.2874ms)
✔ 5. Semester Date Chronological Ordering Contract (0.2405ms)
✔ 6. Semester Configuration & Threshold Constraints (0.1814ms)
✔ 7. Active Semester State Transition Rule (0.2445ms)
✔ 8. RBAC Guard for Academic Catalog & Semesters (0.222ms)
✔ 1. Flat Login Response Schema Contract Verification (0.9576ms)
✔ 2. Token Storage and Session Persistence (0.2702ms)
✔ 3. Refresh Token Rotation (RTR) Updates (0.1564ms)
✔ 4. Complete Logout Cleanup and Sanitization (0.2003ms)
✔ 5. Form Validation: Email Regex, Password Strength and OTP Constraints (0.5061ms)
✔ 6. Mandatory Initial Password Change Policy (0.2532ms)
✔ 7. Profile Update Authorization Boundary: No Role or Permissions Tampering (0.1883ms)
✔ 8. ErrorCode Dictionary & User-Friendly Vietnamese Mapping (0.167ms)
✔ 9. Security Sanitization: Sensitive Data Is Never Leaked (0.2702ms)
✔ 10. Safe Non-Revealing Forgot Password Contract (0.3377ms)
✔ 1. User Creation DTO Validation Contract (2.3178ms)
✔ 2. User Status Update Contract (Lock/Unlock) (0.394ms)
✔ 3. RBAC Admin-Only Access Guard Verification (0.2215ms)
✔ 4. Self-Locking Prevention Guard Logic (0.4073ms)
✔ 5. CSV Import Header Validation & Record Parsing Logic (0.5187ms)
✔ 6. CSV Import Result Envelope Structure (0.1967ms)
ℹ tests 24
ℹ suites 0
ℹ pass 24
ℹ fail 0
```

### 3.3. Production Build Compilation (`npm run build`)
```text
> unicheck-web@1.0.0 build
> tsc -b && vite build

vite v5.4.21 building for production...
transforming...
✓ 1670 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.86 kB │ gzip:   0.52 kB
dist/assets/index-DTtPhFR1.css   42.27 kB │ gzip:   8.10 kB
dist/assets/index-BbcauPx1.js   493.55 kB │ gzip: 132.14 kB
✓ built in 14.19s
```

---

## 4. Kiểm Thử Hồi Quy (Regression Verification)

- **F-01 đến F-05 (Authentication & Profile):** Đăng nhập JWT, kiểm tra tài khoản chưa đổi mật khẩu lần đầu, bảo vệ token trong Zustand/LocalStorage và Interceptors hoàn toàn không bị ảnh hưởng.
- **F-07 (User Management):** Route `/admin/users`, chức năng phân trang người dùng, lọc vai trò/trạng thái, khóa tài khoản, import CSV hoạt động ổn định.
- **Side Navigation & Header:** Menu điều hướng Admin đã cập nhật thêm 2 mục `Học kỳ & Niên khóa` (`/admin/semesters`) và `Danh mục học phần` (`/admin/courses`) theo đúng phân quyền.

---

## 5. Kết Luận & Bàn Giao

TASK-02A (F-11 & F-12) đã hoàn thành xuất sắc 100% các tiêu chí nghiệm thu theo đúng phương pháp Vertical Slice và Definition of Done. Mã nguồn sẵn sàng bàn giao cho các giai đoạn kế tiếp (TASK-02B: Lớp học phần & Cơ sở vật chất).
