# UniCheck Academic Catalog & Semester API Contract (TASK-02A)

> **Mã tài liệu:** API-CONTRACT-TASK-02A  
> **Phiên bản:** 1.0.0 (Frozen)  
> **Tính năng:** F-11 (Quản lý Danh mục Môn học) & F-12 (Quản lý Học kỳ & Niên khóa)  
> **Ngày lập:** 15/10/2026  
> **Người thực hiện:** Senior Spring Boot Engineer & React Engineer  
> **Trạng thái:** ACTIVE & TEST-VERIFIED (54/54 BE tests passed, 24/24 FE tests passed)  

---

## 1. Phạm Vi và Chính Sách Định Tuyến

Tài liệu này xác lập hợp đồng giao tiếp chuẩn (Single Source of Truth - SSOT) cho phân hệ Academic Catalog (F-11) và Semester Management (F-12) của **UniCheck**.

### 1.1. Dual-Mapping Routing Policy
Tất cả các REST controllers đều triển khai Dual-mapping để hỗ trợ song song:
- Tiền tố Canonical: `/api/v1/...` (Khuyến nghị bắt buộc cho Web React và Mobile)
- Tiền tố Legacy: `/api/...` (Tương thích ngược 100%)

---

## 2. Chuẩn Dữ Liệu Phản Hồi (Response Envelopes)

### 2.1. Standard Response (`ApiResponse<T>`)
```json
{
  "success": true,
  "data": { ... },
  "message": "Thành công",
  "errorCode": null
}
```

### 2.2. Paginated Response (`PagedResponse<T>`)
```json
{
  "content": [ ... ],
  "page": 0,
  "size": 10,
  "totalElements": 48,
  "totalPages": 5,
  "last": false
}
```

---

## 3. Danh Sách Endpoint — F-11: Quản Lý Học Phần (Courses)

### 3.1. Phân Trang Danh Mục Học Phần
- **Method:** `GET`
- **Path:** `/api/v1/courses` (Alias: `/api/courses`)
- **Phân quyền:** `ADMIN`, `LECTURER`, `STUDENT`
- **Query Params:**
  - `page` (int, default: 0)
  - `size` (int, default: 10)
  - `search` (string, optional: tìm kiếm theo mã hoặc tên học phần)
  - `credits` (int, optional: lọc theo số tín chỉ)
  - `status` (enum: `ACTIVE`, `INACTIVE`, `DRAFT`, default: all)
- **Response Data:** `PagedResponse<CourseResponse>`

### 3.2. Danh Sách Tóm Tắt (Summary Picker)
- **Method:** `GET`
- **Path:** `/api/v1/courses/summary` (Alias: `/api/courses/summary`)
- **Phân quyền:** `ADMIN`, `LECTURER`, `STUDENT`
- **Response Data:** `List<CourseSummaryDto>` (`id`, `code`, `name`, `credits`)

### 3.3. Xem Chi Tiết Học Phần
- **Method:** `GET`
- **Path:** `/api/v1/courses/{id}` (Alias: `/api/courses/{id}`)
- **Phân quyền:** `ADMIN`, `LECTURER`, `STUDENT`
- **Response Data:** `CourseResponse`

### 3.4. Kiểm Tra Mã Học Phần Trùng Lặp
- **Method:** `GET`
- **Path:** `/api/v1/courses/check-code` (Alias: `/api/courses/check-code`)
- **Phân quyền:** `ADMIN`
- **Query Params:** `code` (string, required)
- **Response Data:** `{ "exists": boolean, "code": string }`

### 3.5. Tạo Mới Học Phần
- **Method:** `POST`
- **Path:** `/api/v1/courses` (Alias: `/api/courses`)
- **Phân quyền:** `ADMIN`
- **Request Body (`CourseCreateRequest`):**
```json
{
  "code": "INT3101",
  "name": "Kiến trúc máy tính nâng cao",
  "description": "Cơ sở ngành kiến trúc máy tính và hệ vi xử lý",
  "credits": 3,
  "numberOfSlots": 45,
  "status": "ACTIVE",
  "isCalculatedInGpa": true,
  "prerequisiteIds": [1, 2]
}
```
- **Response Data:** `CourseResponse` (Status: 201 Created)

### 3.6. Cập Nhật Học Phần
- **Method:** `PUT`
- **Path:** `/api/v1/courses/{id}` (Alias: `/api/courses/{id}`)
- **Phân quyền:** `ADMIN`
- **Request Body (`CourseUpdateRequest`):**
```json
{
  "name": "Kiến trúc máy tính nâng cao (Hiệu chỉnh)",
  "description": "Bổ sung kiến trúc tập lệnh RISC-V",
  "credits": 3,
  "numberOfSlots": 45,
  "status": "ACTIVE",
  "isCalculatedInGpa": true,
  "prerequisiteIds": [1]
}
```
- **Response Data:** `CourseResponse`

### 3.7. Xóa Học Phần
- **Method:** `DELETE`
- **Path:** `/api/v1/courses/{id}` (Alias: `/api/courses/{id}`)
- **Phân quyền:** `ADMIN`
- **Response Data:** `null` (Message: "Xóa học phần thành công")

---

## 4. Danh Sách Endpoint — F-12: Quản Lý Học Kỳ (Semesters)

### 4.1. Phân Trang Danh Sách Học Kỳ
- **Method:** `GET`
- **Path:** `/api/v1/semesters` (Alias: `/api/semesters`)
- **Phân quyền:** `ADMIN`, `LECTURER`, `STUDENT`
- **Query Params:**
  - `page` (int, default: 0)
  - `size` (int, default: 10)
  - `search` (string, optional: tìm kiếm theo mã hoặc tên học kỳ)
  - `status` (enum: `ACTIVE`, `UPCOMING`, `CLOSED`, `ARCHIVED`, default: all)
- **Response Data:** `PagedResponse<SemesterResponse>`

### 4.2. Lấy Học Kỳ Hiện Hành (Active Semester)
- **Method:** `GET`
- **Path:** `/api/v1/semesters/active` (Alias: `/api/semesters/active`)
- **Phân quyền:** `ADMIN`, `LECTURER`, `STUDENT`
- **Response Data:** `SemesterResponse`

### 4.3. Xem Chi Tiết Học Kỳ
- **Method:** `GET`
- **Path:** `/api/v1/semesters/{id}` (Alias: `/api/semesters/{id}`)
- **Phân quyền:** `ADMIN`, `LECTURER`, `STUDENT`
- **Response Data:** `SemesterResponse`

### 4.4. Kiểm Tra Mã Học Kỳ Trùng Lặp
- **Method:** `GET`
- **Path:** `/api/v1/semesters/check-code` (Alias: `/api/semesters/check-code`)
- **Phân quyền:** `ADMIN`
- **Query Params:** `code` (string, required)
- **Response Data:** `{ "exists": boolean, "code": string }`

### 4.5. Tạo Mới Học Kỳ
- **Method:** `POST`
- **Path:** `/api/v1/semesters` (Alias: `/api/semesters`)
- **Phân quyền:** `ADMIN`
- **Request Body (`SemesterCreateRequest`):**
```json
{
  "code": "HK1_2024_2025",
  "name": "Học kỳ 1 (2024 - 2025)",
  "startDate": "2024-09-02",
  "endDate": "2025-01-18",
  "status": "ACTIVE",
  "description": "Học kỳ chính mùa Thu",
  "maxSlotPerDay": 6,
  "slotPerSubjectPerWeek": 4,
  "slotDuration": 50,
  "isPublished": true
}
```
- **Response Data:** `SemesterResponse` (Status: 201 Created)

### 4.6. Cập Nhật Học Kỳ
- **Method:** `PUT`
- **Path:** `/api/v1/semesters/{id}` (Alias: `/api/semesters/{id}`)
- **Phân quyền:** `ADMIN`
- **Request Body (`SemesterUpdateRequest`):**
```json
{
  "name": "Học kỳ 1 (2024 - 2025) - Điều chỉnh",
  "startDate": "2024-09-02",
  "endDate": "2025-01-25",
  "status": "ACTIVE",
  "description": "Gia hạn thêm 1 tuần ôn tập thi cuối kỳ",
  "maxSlotPerDay": 6,
  "slotPerSubjectPerWeek": 4,
  "slotDuration": 50,
  "isPublished": true
}
```
- **Response Data:** `SemesterResponse`

### 4.7. Khóa Học Kỳ (Lock Semester)
- **Method:** `PATCH`
- **Path:** `/api/v1/semesters/{id}/lock` (Alias: `/api/semesters/{id}/lock`)
- **Phân quyền:** `ADMIN`
- **Chức năng:** Chuyển trạng thái học kỳ sang `CLOSED`, khóa các thao tác sửa đổi lịch học và phiên điểm danh.
- **Response Data:** `SemesterResponse`

### 4.8. Xóa Học Kỳ
- **Method:** `DELETE`
- **Path:** `/api/v1/semesters/{id}` (Alias: `/api/semesters/{id}`)
- **Phân quyền:** `ADMIN`
- **Response Data:** `null` (Message: "Xóa học kỳ thành công")

---

## 5. Quy Tắc Nghiệp Vụ & Toàn Vẹn Dữ Liệu (Business Rules & Integrity)

| Mã Lỗi | Tên Lỗi | HTTP | Điều kiện kích hoạt |
| :--- | :--- | :---: | :--- |
| `ERR_4004` | `COURSE_NOT_FOUND` | 404 | Không tìm thấy học phần theo ID |
| `ERR_4007` | `SEMESTER_NOT_FOUND` | 404 | Không tìm thấy học kỳ theo ID |
| `ERR_4005` | `CANNOT_DELETE_REFERENCED_RESOURCE` | 400 | Không cho phép xóa học phần đang được làm môn tiên quyết cho học phần khác |
| `ERR_4006` | `CIRCULAR_PREREQUISITE` | 400 | Phát hiện phụ thuộc vòng giữa các học phần tiên quyết |
| `ERR_4002` | `DUPLICATE_CODE` | 409 | Trùng mã học phần (`Course.code`) hoặc mã học kỳ (`Semester.code`) |
| `ERR_4001` | `INVALID_INPUT` | 400 | Ngày bắt đầu >= ngày kết thúc học kỳ, hoặc số tín chỉ <= 0 |

### 5.1. Quy tắc đơn nhất học kỳ ACTIVE:
Khi một học kỳ được tạo mới với trạng thái `ACTIVE` hoặc cập nhật sang `ACTIVE`, hệ thống tự động cập nhật tất cả các học kỳ đang `ACTIVE` khác sang trạng thái `CLOSED`. Đảm bảo tại một thời điểm chỉ có duy nhất một học kỳ vận hành.
