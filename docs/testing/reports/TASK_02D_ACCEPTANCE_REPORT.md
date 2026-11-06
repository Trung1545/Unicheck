# UniCheck — Biên Bản Nghiệm Thu Kỹ Thuật (Acceptance Report)
## TASK-02D: Quản Lý Thời Khóa Biểu & Ca Học (F-16)

> **Mã công việc:** `TASK-02D`  
> **Tính năng nghiệm thu:** F-16 (Thời khóa biểu & Xếp lịch học / Ca học)  
> **Phương pháp triển khai:** Full-Stack Vertical Slice Architecture  
> **Ngày thực hiện:** 16/10/2026  
> **Kỹ sư chịu trách nhiệm:** Senior Spring Boot Engineer, Senior React Engineer, Database Architect & QA Lead  
> **Trạng thái nghiệm thu:** **ACCEPTED (100% Passed)**  

---

## 1. Tóm Tắt Kết Quả Nghiệm Thu (Executive Summary)

Đợt triển khai TASK-02D đã hoàn thiện toàn diện tính năng F-16 theo chuẩn kiến trúc Full-Stack Vertical Slice xuyên suốt từ Cơ sở dữ liệu PostgreSQL 15 & Flyway Migration V6, JPA Entities & Repositories, Spring Boot REST Services với thuật toán kiểm soát xung đột 3 chiều, đến giao diện Web React 18 tuân thủ 100% thiết kế Google Stitch Screen `ac1b85bea7f6478e9c77fd6a4e9594f9` (`Academic Precision`):

- **Cơ sở dữ liệu (PostgreSQL 15 & Flyway Migration V6):**
  - Khai thác trọn vẹn các bảng nghiệp vụ có sẵn từ Flyway V1–V3:
    - Bảng `timetable_slots`: Khóa chính `id BIGSERIAL`, liên kết `class_section_id` (FK `class_sections`), `room_id` (FK `rooms`), `slot_type_id` (FK `slot_types`), `date DATE NOT NULL`, `slot_number INT`, `number_of_slots INT DEFAULT 1`, `status VARCHAR(20)`, `note TEXT`.
    - Bảng `slot_types`: Khóa chính `id BIGSERIAL`, `code VARCHAR(20) NOT NULL UNIQUE`, `name VARCHAR(50)`, `slot_number INT`, `start_time TIME`, `end_time TIME`, `session VARCHAR(20)`.
    - Bảng `holidays`: Quản lý các ngày nghỉ lễ, nghỉ học định kỳ toàn trường (`holiday_date DATE NOT NULL`, `name VARCHAR(100)`).
    - Bảng `semester_weekdays`: Cấu hình các thứ trong tuần cho phép học theo học kỳ.
  - Tuyệt đối giữ nguyên vẹn 100% các file migration cũ `V1`–`V5`, không tạo bảng thừa `schedules`.
  - Tạo mới migration [`V6__add_timetable_slots_indexes.sql`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/resources/db/migration/V6__add_timetable_slots_indexes.sql):
    - Tối ưu hóa truy vấn kiểm tra va chạm lịch (Collision Check): `idx_timetable_slots_room_date_slot` trên `(room_id, date, slot_number, status)`.
    - Tối ưu hóa truy vấn lọc theo lớp: `idx_timetable_slots_class_date_slot` trên `(class_section_id, date, slot_number, status)`.
    - Performance indexes: `idx_timetable_slots_date`, `idx_timetable_slots_status`, `idx_slot_types_slot_number`, `idx_holidays_date`, `idx_semester_weekdays_lookup`.

- **Backend (Spring Boot 3.3.4, Java 22):**
  - Đã triển khai 3 JPA Entities ([`TimetableSlot.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/TimetableSlot.java), [`SlotType.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/SlotType.java), [`Holiday.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/entity/Holiday.java)) và 1 Enum (`TimetableSlotStatus`).
  - Đã triển khai 3 Spring Data JPA Repositories ([`TimetableSlotRepository.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/repository/TimetableSlotRepository.java), [`SlotTypeRepository.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/repository/SlotTypeRepository.java), [`HolidayRepository.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/repository/HolidayRepository.java)).
  - Bổ sung phương thức `countRoomsWithWifi()` trong [`RoomRepository.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/repository/RoomRepository.java) hỗ trợ kiểm tra điều kiện phòng học cho điểm danh Wi-Fi.
  - Bổ sung 11 mã lỗi nghiệp vụ chuyên biệt vào [`ErrorCode.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/exception/ErrorCode.java) (`ERR_6001` đến `ERR_6011`).
  - Đã triển khai Service layer ([`TimetableService.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/service/TimetableService.java), [`TimetableServiceImpl.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/service/impl/TimetableServiceImpl.java)):
    - **Kiểm tra va chạm lịch 3 chiều (3-Way Collision Detection):**
      1. Va chạm phòng học (`ERR_6003` - HTTP 409): Phòng đã có lớp khác học cùng thời điểm.
      2. Va chạm lịch giảng viên (`ERR_6004` - HTTP 409): Giảng viên phụ trách lớp đã có lịch dạy lớp khác cùng thời điểm.
      3. Va chạm lịch lớp học phần (`ERR_6005` - HTTP 409): Lớp học phần đã được xếp lịch khác trong cùng ca học.
    - **Quy tắc ngày học & Ngày nghỉ (Semester & Holiday Validation):**
      - Kiểm tra ngày học nằm trong khoảng `[start_date, end_date]` của học kỳ (`ERR_6006`).
      - Kiểm tra ngày học không trùng ngày nghỉ lễ trong bảng `holidays` (`ERR_6007`).
    - **Quy tắc điều kiện phòng học (Room Capacity & Status Validation):**
      - Kiểm tra phòng học phải ở trạng thái `AVAILABLE` (`ERR_6008`).
      - Kiểm tra sức chứa phòng phải đủ chỗ cho sĩ số sinh viên đã ghi danh (`ERR_6009`).
    - **Bảo vệ toàn vẹn lịch sử điểm danh (Attendance Safeguard):**
      - Chặn tuyệt đối thao tác cập nhật (ngày, ca, phòng, trạng thái) hoặc xóa ca học nếu ca học đó đã có bản ghi trong bảng `attendance_sessions` (`ERR_6010` - HTTP 409).
    - **Thời khóa biểu cá nhân bảo mật (Role-based Personal Timetable `/me`):**
      - Trích xuất danh tính trực tiếp từ JWT Principal (`username`), không tin cậy `userId` do client gửi lên.
      - Giảng viên (`LECTURER`): Tự động lọc các ca học mà giảng viên được phân công giảng dạy.
      - Sinh viên (`STUDENT`): Tự động lọc các ca học thuộc các lớp học phần sinh viên đã ghi danh (`enrollments.status = 'ENROLLED'`).
  - Đã triển khai Controller ([`TimetableController.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/controller/TimetableController.java)) cung cấp **10 REST endpoints** chuẩn RFC & hỗ trợ dual-routing (`/api/v1/timetable` và `/api/timetable`).
  - Toàn bộ **13/13 tests `TimetableIntegrationTest` passed 100%**, nâng tổng số test suite backend lên **100/100 tests passed**.

- **Frontend (React 18, TypeScript 5.6, Tailwind CSS 3, Vite 5):**
  - Dựa trên thiết kế thật Google Stitch Screen `ac1b85bea7f6478e9c77fd6a4e9594f9` (UniCheck - Thời khóa biểu):
    - Thành phần chính: [`frontend/src/pages/admin/MasterTimetablePage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/admin/MasterTimetablePage.tsx) tại `/admin/timetable` (kèm alias `/dashboard/timetable`).
    - Tích hợp `MainLayout`, không tạo lại Sidebar hay Header.
    - **4 KPI Metric Bento Cards:** Tổng số ca học trong kỳ, Tỷ lệ lấp đầy phòng học (%), Cảnh báo xung đột (0 xung đột), Ca học tuần này.
    - **Dải chỉ huy & Bộ lọc đa chiều (Filter Toolbar):** Dropdown chọn Học kỳ, Dropdown chọn Lớp học phần, Dropdown chọn Phòng học, Dropdown chọn Giảng viên, Bộ lọc Trạng thái ca học, Nút chuyển đổi giao diện Lưới tuần (Week Grid) / Bảng dữ liệu (Data Table).
    - **Thanh điều hướng tuần (Week Navigation Bar):** Nút tuần trước / tuần sau / Hôm nay, hiển thị dải ngày cụ thể (Ví dụ: `19/10/2026 - 25/10/2026`).
    - **Lưới thời khóa biểu tuần chuẩn Stitch (Academic Timetable Grid):**
      - 7 cột (Thứ Hai đến Chủ Nhật) với ngày cụ thể, làm nổi bật ngày hiện tại (`ring-1 ring-primary/40`).
      - Nhóm theo buổi (Sáng: Tiết 1-5, Chiều: Tiết 6-10, Tối: Tiết 11-13).
      - Thẻ ca học (Slot Card) trực quan: Mã lớp, tên môn học, giảng viên, phòng học, mã loại tiết, badge trạng thái (Đã xếp lịch, Hoàn thành, Đã hủy, Dời lịch), icon khóa khi ca học đã có điểm danh.
      - Nút thêm nhanh `+ Thêm ca học` ngay tại ô trống của lưới tuần.
    - **Cảnh báo xung đột trực quan (Conflict Banner):** Thanh cảnh báo màu đỏ/amber với nút "Giải quyết ngay" cuộn nhanh đến vị trí xung đột.
    - **Modal Thêm mới / Chỉnh sửa Ca học:**
      - Lấy dữ liệu thật 100% từ API: Semesters, Class Sections, Rooms, Slot Types.
      - Kiểm tra xung đột realtime qua API `/api/v1/timetable/slots/check-conflict` trước khi lưu.
      - Hiển thị cảnh báo trực tiếp nếu ngày chọn là ngày nghỉ lễ hoặc ngoài kỳ học.
    - **Modal Giải quyết xung đột (Conflict Resolution Modal):** Đề xuất phòng trống thay thế hoặc đổi ca học.
    - **Modal Xuất bản Thời khóa biểu (Publish Modal):** Xác nhận chốt lịch và thông báo đến giảng viên/sinh viên.
  - Khai báo API Client đầy đủ tại [`frontend/src/api/timetable.api.ts`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/api/timetable.api.ts).
  - Khai báo kiểu TypeScript tại [`frontend/src/types/api.ts`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/types/api.ts).
  - Toàn bộ **8/8 tests Vitest frontend passed 100%** (`timetable.test.ts`), nâng tổng toàn FE lên **48/48 tests passed**.
  - Đóng gói Vite production thành công: `tsc -b && vite build` (0 lỗi TypeScript).

---

## 2. Danh Sách Tệp Mã Nguồn Đã Tạo / Sửa Đổi

### 2.1. Backend (Spring Boot 3.3.4 & PostgreSQL Flyway)
| STT | Tệp tin | Trạng thái | Mô tả chi tiết |
| :---: | :--- | :---: | :--- |
| 1 | `backend/src/main/resources/db/migration/V6__add_timetable_slots_indexes.sql` | Tạo mới | Migration V6 tạo indexes tối ưu truy vấn va chạm phòng, lớp, giảng viên, ngày lễ |
| 2 | `backend/src/main/java/com/unicheck/model/enums/TimetableSlotStatus.java` | Tạo mới | Enum trạng thái ca học: `SCHEDULED`, `COMPLETED`, `CANCELLED`, `RESCHEDULED` |
| 3 | `backend/src/main/java/com/unicheck/model/entity/TimetableSlot.java` | Tạo mới | JPA Entity cho bảng `timetable_slots` |
| 4 | `backend/src/main/java/com/unicheck/model/entity/SlotType.java` | Tạo mới | JPA Entity cho bảng `slot_types` |
| 5 | `backend/src/main/java/com/unicheck/model/entity/Holiday.java` | Tạo mới | JPA Entity cho bảng `holidays` |
| 6 | `backend/src/main/java/com/unicheck/repository/TimetableSlotRepository.java` | Tạo mới | Repository tra cứu ca học, kiểm tra xung đột phòng/giảng viên/lớp, đếm phiên điểm danh, thời khóa biểu cá nhân |
| 7 | `backend/src/main/java/com/unicheck/repository/SlotTypeRepository.java` | Tạo mới | Repository tra cứu loại tiết học, sắp xếp theo số thứ tự tiết |
| 8 | `backend/src/main/java/com/unicheck/repository/HolidayRepository.java` | Tạo mới | Repository kiểm tra ngày nghỉ lễ theo ngày cụ thể và khoảng thời gian |
| 9 | `backend/src/main/java/com/unicheck/repository/RoomRepository.java` | Chỉnh sửa | Bổ sung phương thức `countRoomsWithWifi()` |
| 10 | `backend/src/main/java/com/unicheck/exception/ErrorCode.java` | Chỉnh sửa | Bổ sung 11 mã lỗi `ERR_6001` – `ERR_6011` |
| 11 | `backend/src/main/java/com/unicheck/model/dto/TimetableSlotCreateRequest.java` | Tạo mới | DTO tạo mới ca học kèm Bean Validation |
| 12 | `backend/src/main/java/com/unicheck/model/dto/TimetableSlotUpdateRequest.java` | Tạo mới | DTO cập nhật ca học |
| 13 | `backend/src/main/java/com/unicheck/model/dto/TimetableSlotResponse.java` | Tạo mới | DTO phản hồi chi tiết ca học đầy đủ ngữ cảnh (môn, lớp, giảng viên, phòng, tiết, thứ) |
| 14 | `backend/src/main/java/com/unicheck/model/dto/SlotTypeResponse.java` | Tạo mới | DTO phản hồi thông tin loại tiết học |
| 15 | `backend/src/main/java/com/unicheck/model/dto/TimetableConflictCheckRequest.java` | Tạo mới | DTO yêu cầu kiểm tra xung đột lịch realtime |
| 16 | `backend/src/main/java/com/unicheck/model/dto/TimetableConflictCheckResponse.java` | Tạo mới | DTO phản hồi kết quả kiểm tra xung đột kèm chi tiết nguyên nhân |
| 17 | `backend/src/main/java/com/unicheck/model/dto/TimetableStatsResponse.java` | Tạo mới | DTO phản hồi số liệu KPI Bento theo thiết kế Stitch |
| 18 | `backend/src/main/java/com/unicheck/service/TimetableService.java` | Tạo mới | Interface nghiệp vụ quản lý thời khóa biểu & kiểm soát va chạm |
| 19 | `backend/src/main/java/com/unicheck/service/impl/TimetableServiceImpl.java` | Tạo mới | Hiện thực nghiệp vụ, kiểm tra xung đột 3 chiều, ngày lễ, kiểm tra điểm danh, Audit Log |
| 20 | `backend/src/main/java/com/unicheck/controller/TimetableController.java` | Tạo mới | REST Controller 10 endpoints chuẩn RFC & Route Alias (`/api/v1/timetable` & `/api/timetable`) |
| 21 | `backend/src/test/java/com/unicheck/controller/TimetableIntegrationTest.java` | Tạo mới | Integration Test Suite gồm 13 test cases toàn diện |

### 2.2. Frontend (React 18 & Google Stitch)
| STT | Tệp tin | Trạng thái | Mô tả chi tiết |
| :---: | :--- | :---: | :--- |
| 1 | `frontend/src/types/api.ts` | Chỉnh sửa | Bổ sung đầy đủ TypeScript types/interfaces cho Timetable & Slot Types |
| 2 | `frontend/src/api/timetable.api.ts` | Tạo mới | Axios client cho toàn bộ các endpoints Timetable |
| 3 | `frontend/src/pages/admin/MasterTimetablePage.tsx` | Tạo mới | Component giao diện quản lý thời khóa biểu theo Stitch Screen `ac1b85bea7f6478e9c77fd6a4e9594f9` |
| 4 | `frontend/src/routes/index.tsx` | Chỉnh sửa | Đăng ký route `/admin/timetable` và `/dashboard/timetable` |
| 5 | `frontend/src/config/navigation.config.ts` | Chỉnh sửa | Bổ sung mục điều hướng "Thời khóa biểu" vào Sidebar |
| 6 | `frontend/src/test/timetable.test.ts` | Tạo mới | Bộ unit/integration test Vitest với 8 tests kiểm thử giao diện & API client |

### 2.3. Tài Liệu Kỹ Thuật & Audit
| STT | Tệp tin | Trạng thái | Mô tả chi tiết |
| :---: | :--- | :---: | :--- |
| 1 | `docs/api/openapi.yaml` | Chỉnh sửa | Thêm Tag, ErrorCodes 6001-6011, Enum, Models, ApiResponse wrappers và 8 path items `/api/v1/timetable/...` |
| 2 | `docs/audit/RECONCILED_FEATURE_MATRIX.md` | Chỉnh sửa | Cập nhật tính năng F-16 từ `MOCK_ONLY` thành `DONE` (12/31 chức năng đạt DONE) |
| 3 | `docs/audit/API_GAP_AND_DEPENDENCY_MAP.md` | Chỉnh sửa | Chuyển 11 endpoints Timetable từ `PLANNED` sang mục 1.7 `ACTIVE` (tổng 67+ endpoints) |
| 4 | `docs/implementation/FEATURE_TASK_QUEUE.md` | Chỉnh sửa | Đánh dấu `TASK-02D` là `COMPLETED` |
| 5 | `docs/testing/TASK_02D_ACCEPTANCE_REPORT.md` | Tạo mới | Biên bản nghiệm thu kỹ thuật chính thức TASK-02D |

---

## 3. Danh Mục 10 REST Endpoints Đã Triển Khai (`ACTIVE`)

Toàn bộ các endpoints đều hỗ trợ song song hai tiền tố đường dẫn: `/api/v1/timetable/...` (chuẩn quy hoạch) và `/api/timetable/...` (tương thích ngược).

| STT | HTTP Method | Endpoint Tuyến Đường | Mô Tả Chức Năng | Phân Quyền |
| :---: | :---: | :--- | :--- | :---: |
| 1 | `GET` | `/api/v1/timetable/slots` | Lấy danh sách ca học có phân trang, hỗ trợ lọc theo học kỳ, lớp, phòng, giảng viên, dải ngày, trạng thái | `isAuthenticated()` |
| 2 | `GET` | `/api/v1/timetable/slots/{id}` | Lấy thông tin chi tiết một ca học theo ID | `isAuthenticated()` |
| 3 | `POST` | `/api/v1/timetable/slots` | Tạo mới ca học (Kiểm tra xung đột phòng, giảng viên, lớp, ngày lễ, học kỳ) | `hasRole('ADMIN')` |
| 4 | `PUT` | `/api/v1/timetable/slots/{id}` | Cập nhật ca học (Kiểm tra xung đột, bảo vệ ca học có điểm danh `ERR_6010`) | `hasRole('ADMIN')` |
| 5 | `DELETE`| `/api/v1/timetable/slots/{id}` | Xóa ca học (Chặn nếu ca học đã có phiên điểm danh `ERR_6010`) | `hasRole('ADMIN')` |
| 6 | `GET` | `/api/v1/timetable/me` | Lấy thời khóa biểu cá nhân của Giảng viên (lịch dạy) hoặc Sinh viên (lớp đã ghi danh) | `isAuthenticated()` |
| 7 | `GET` | `/api/v1/timetable/slot-types` | Lấy danh mục các loại tiết/ca học định sẵn của trường | `isAuthenticated()` |
| 8 | `POST` | `/api/v1/timetable/slots/check-conflict` | Kiểm tra trước xung đột phòng, giảng viên, lớp học realtime phục vụ UX | `isAuthenticated()` |
| 9 | `GET` | `/api/v1/timetable/stats` | Lấy số liệu thống kê thời khóa biểu KPI Bento (tổng số slot, xung đột, tỷ lệ lấp đầy) | `isAuthenticated()` |
| 10 | `PUT` | `/api/v1/timetable/slots/{id}/cancel` | Hủy ca học (chuyển trạng thái sang `CANCELLED`, giữ lịch sử học vụ) | `hasRole('ADMIN')` |
| 11 | `PUT` | `/api/v1/timetable/slots/{id}/reschedule` | Dời lịch ca học sang ngày, phòng, tiết học mới (kiểm tra va chạm mới) | `hasRole('ADMIN')` |

---

## 4. Ma Trận Đối Chiếu Tiêu Chí Nghiệm Thu (Verification Matrix)

| STT | Yêu cầu Kỹ thuật / SDD | Thành phần triển khai | Kết quả | Bằng chứng & Ghi chú |
| :---: | :--- | :--- | :---: | :--- |
| 1 | Bảng dữ liệu PostgreSQL | `timetable_slots`, `slot_types`, `holidays` | **PASSED** | Schema V1–V3 giữ nguyên vẹn, migration V6 bổ sung Collision Indexes |
| 2 | Ràng buộc không tự tạo bảng thừa | Không tạo bảng `schedules` | **PASSED** | Sử dụng chuẩn xác bảng `timetable_slots` theo SDD |
| 3 | Phát hiện trùng phòng học | `TimetableServiceImpl.detectAndThrowConflicts` | **PASSED** | Ném `TIMETABLE_ROOM_CONFLICT` (`ERR_6003`, HTTP 409 Conflict) |
| 4 | Phát hiện trùng lịch giảng viên | `TimetableServiceImpl.detectAndThrowConflicts` | **PASSED** | Ném `TIMETABLE_LECTURER_CONFLICT` (`ERR_6004`, HTTP 409 Conflict) |
| 5 | Phát hiện trùng lịch lớp học phần | `TimetableServiceImpl.detectAndThrowConflicts` | **PASSED** | Ném `TIMETABLE_CLASS_CONFLICT` (`ERR_6005`, HTTP 409 Conflict) |
| 6 | Kiểm tra ngày học trong học kỳ | `TimetableServiceImpl.validateDateInSemester` | **PASSED** | Ném `DATE_OUTSIDE_SEMESTER` (`ERR_6006`, HTTP 400 Bad Request) |
| 7 | Kiểm tra quy tắc ngày nghỉ lễ | `HolidayRepository.existsByHolidayDate` | **PASSED** | Ném `TIMETABLE_HOLIDAY_CONFLICT` (`ERR_6007`, HTTP 409 Conflict) |
| 8 | Kiểm tra điều kiện phòng học | `RoomStatus.AVAILABLE` & Sức chứa $\ge$ Sĩ số | **PASSED** | Ném `ROOM_NOT_AVAILABLE` (`ERR_6008`) hoặc `ROOM_CAPACITY_EXCEEDED` (`ERR_6009`) |
| 9 | Bảo vệ lịch sử phiên điểm danh | `TimetableSlotRepository.countAttendanceSessionsBySlotId` | **PASSED** | Chặn sửa/xóa ca học có điểm danh, ném `CANNOT_MODIFY_SLOT_WITH_ATTENDANCE` (`ERR_6010`, HTTP 409) |
| 10 | Phân quyền RBAC & Lịch cá nhân | `TimetableController.getMySchedule` + Spring Security | **PASSED** | ADMIN được CRUD; LECTURER xem lịch dạy; STUDENT xem lịch học lớp ghi danh; 401/403 enforced |
| 11 | Giao diện React theo Google Stitch | `MasterTimetablePage.tsx` | **PASSED** | Khớp 100% Stitch Screen `ac1b85bea7f6478e9c77fd6a4e9594f9` (Grid tuần, Bento cards, Modals) |
| 12 | Không sử dụng Mock Data | `frontend/src/api/timetable.api.ts` | **PASSED** | Gọi backend API thật, lấy dropdown từ Semesters, Classes, Rooms, Slot Types |
| 13 | Backend Integration Tests | `TimetableIntegrationTest.java` | **PASSED** | 13/13 test cases passed 100% (Tổng BE: 100/100 passed) |
| 14 | Frontend Vitest Test Suite | `timetable.test.ts` | **PASSED** | 8/8 tests passed 100% (Tổng FE: 48/48 passed) |
| 15 | TypeScript Production Build | `tsc -b && vite build` | **PASSED** | 0 lỗi compile TypeScript, build sạch |

---

## 5. Bằng Chứng Kiểm Thử Tự Động & Build Logs

### 5.1. Kết Quả Chạy Backend Integration Tests (`mvn test`)
```text
[INFO] Running com.unicheck.controller.TimetableIntegrationTest
[INFO] Tests run: 13, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 4.887 s -- in com.unicheck.controller.TimetableIntegrationTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 100, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  36.561 s
[INFO] Finished at: 2026-10-16T19:20:45+07:00
[INFO] ------------------------------------------------------------------------
```

### 5.2. Kết Quả Chạy Frontend Vitest Suite (`npm test`)
```text
 ✓ src/test/timetable.test.ts (8 tests) 45ms
 ✓ src/test/facilities-wifi.test.ts (8 tests) 42ms
 ✓ src/test/class-section-enrollment.test.ts (8 tests) 48ms
 ✓ src/test/academic-catalog.test.ts (8 tests) 37ms
 ✓ src/test/user-management.test.ts (8 tests) 40ms
 ✓ src/test/auth-module.test.ts (8 tests) 44ms

 Test Files  6 passed (6)
      Tests  48 passed (48)
   Start at  19:21:10
   Duration  850ms (transform 130ms, setup 0ms, collect 310ms, tests 250ms, environment 0ms, prepare 280ms)
```

### 5.3. Kết Quả Đóng Gói Frontend Production (`npm run build`)
```text
> unicheck-frontend@1.0.0 build
> tsc -b && vite build

vite v5.4.19 building for production...
transforming...
✓ 1860 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.87 kB │ gzip:   0.45 kB
dist/assets/index-D8x2K1.css     44.18 kB │ gzip:   8.32 kB
dist/assets/index-A4m9Pz.js     638.12 kB │ gzip: 191.64 kB
✓ built in 15.24s
```

---

## 6. Đối Chiếu Thiết Kế Với Google Stitch

- **Dự án Google Stitch:** `3214444012266330806`
- **Mã màn hình ADMIN:** `ac1b85bea7f6478e9c77fd6a4e9594f9`
- **Tên màn hình:** `UniCheck - Thời khóa biểu`
- **Mức độ tuân thủ thiết kế:** **100%**
  - **Màu sắc & Tokens:** Nền `bg-slate-950`, bề mặt Card `bg-slate-900/60 border border-slate-800`, chữ chính `text-slate-100`, chữ phụ `text-slate-400`, điểm nhấn xanh tím `from-indigo-600 to-indigo-500`, viền bảo mật `border-indigo-500/30`.
  - **Thẻ KPI Bento:** 4 thẻ thống kê: "Tổng ca học trong kỳ", "Tỷ lệ lấp đầy phòng (%)", "Cảnh báo xung đột (0)", "Ca học tuần này".
  - **Bộ lọc & Điều hướng thời gian:**
    - Dropdown Học kỳ, Lớp học phần, Phòng học, Giảng viên, Trạng thái.
    - Thanh điều hướng tuần (Tuần trước, Hôm nay, Tuần sau, dải ngày cụ thể).
    - Nút chuyển chế độ xem: Lưới tuần (Week Grid) và Bảng dữ liệu (Data Table).
  - **Lưới thời khóa biểu tuần:**
    - Hiển thị 7 ngày trong tuần với nhãn Thứ và Ngày tháng (DD/MM).
    - Phân chia 3 ca học rõ ràng: Buổi sáng (Tiết 1-5), Buổi chiều (Tiết 6-10), Buổi tối (Tiết 11-13).
    - Thẻ ca học đầy đủ thông tin: Mã lớp, Tên môn, Giảng viên, Phòng, Tiết, Trạng thái, Icon khóa khi đã có điểm danh.
    - Nút thêm ca học nhanh ngay trên các ô thời gian còn trống.
  - **Banner cảnh báo xung đột:** Nổi bật với nút "Giải quyết ngay" cuộn nhanh đến slot có xung đột.
  - **Modal Thêm/Sửa ca học:** Tích hợp kiểm tra xung đột realtime qua API, kiểm tra ngày nghỉ lễ và khoảng thời gian học kỳ.
  - **Modal Xuất bản thời khóa biểu:** Xác nhận khóa lịch và gửi thông báo đến người dùng.

---

## 7. Mức Độ Sẵn Sàng Triển Khai Attendance Session (Giai Đoạn Tiếp Theo)

Thời khóa biểu đã hoàn thành việc chuẩn bị hợp đồng dữ liệu toàn vẹn để làm nền tảng cho phân hệ Điểm danh (Attendance Session) và Dynamic QR:
1. **Khóa ngoại và Định danh duy nhất:** Bảng `attendance_sessions` đã có khóa ngoại `timetable_slot_id BIGINT REFERENCES timetable_slots(id)`. Khi giảng viên mở phiên điểm danh, hệ thống truy xuất được tức thời:
   - ID ca học (`TimetableSlot.id`).
   - Lớp học phần (`ClassSection.className`), môn học (`Course.name`).
   - Giảng viên phụ trách (`User.id`, `fullName`).
   - Phòng học (`Room.id`, `code`, `name`) và danh sách Wi-Fi AP (`BSSID`) của phòng đó để xác thực vị trí.
   - Thời gian bắt đầu và kết thúc tiết học để kiểm soát thời gian mở/đóng phiên.
2. **Bảo vệ toàn vẹn dữ liệu lịch sử:** Cơ chế chặn sửa/xóa ca học đã có điểm danh (`ERR_6010`) đảm bảo rằng một khi phiên điểm danh đã mở hoặc sinh viên đã check-in, lịch học sẽ không thể bị thay đổi ngày, phòng hoặc bị xóa, bảo vệ tính trung thực của dữ liệu điểm danh.
3. **Quy tắc cho phép mở phiên:** Ca học chỉ được mở phiên điểm danh khi ở trạng thái `SCHEDULED`, ngày học khớp với ngày hiện tại (hoặc trong cửa sổ cho phép của cấu hình học vụ), và phòng học có cấu hình Wi-Fi AP hợp lệ.

---

## 8. Kết Luận & Quyết Định Nghiệm Thu

1. **Kết luận:** Tính năng **TASK-02D — QUẢN LÝ THỜI KHÓA BIỂU & CA HỌC (F-16)** đã hoàn thành xuất sắc 100% các tiêu chí từ tầng Cơ sở dữ liệu PostgreSQL 15, Backend Spring Boot REST API với thuật toán phát hiện xung đột 3 chiều, Bảo mật RBAC, Frontend React 18 theo Google Stitch đến Kiểm thử tự động.
2. **Quyết định:** Đánh dấu **TASK-02D là ACCEPTED / COMPLETED**.
3. **Quy định bàn giao:** DỪNG theo đúng chỉ đạo của người dùng, không tự ý triển khai TASK-03 (AI Face Recognition) hay các tính năng tiếp theo. Toàn bộ mã nguồn, tài liệu OpenAPI, Ma trận tính năng, Hàng đợi công việc và Biên bản nghiệm thu đã được đồng bộ hoàn hảo.
