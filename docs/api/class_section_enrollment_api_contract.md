# UniCheck Class Section & Enrollment API Contract (TASK-02B)

> **Mã tài liệu:** API-CONTRACT-TASK-02B  
> **Phiên bản:** 1.0.0 (Frozen)  
> **Tính năng:** F-14 (Quản lý Lớp học phần) & F-15 (Quản lý Ghi danh sinh viên)  
> **Ngày lập:** 16/10/2026  
> **Người thực hiện:** Senior Spring Boot Engineer, React Engineer & QA Lead  
> **Trạng thái:** ACTIVE & TEST-VERIFIED (72/72 BE tests passed, 32/32 FE tests passed)  

---

## 1. Phạm Vi và Chính Sách Định Tuyến

Tài liệu này xác lập hợp đồng giao tiếp chuẩn (SSOT) cho phân hệ Class Section Management (F-14) và Enrollment Management (F-15) của hệ thống **UniCheck**.

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
  "message": "Thao tác thành công",
  "errorCode": null
}
```

### 2.2. Paginated Response (`PageResponse<T>`)
```json
{
  "content": [ ... ],
  "page": 0,
  "size": 10,
  "totalElements": 25,
  "totalPages": 3,
  "last": false
}
```

---

## 3. Danh Sách Endpoint — F-14: Lớp Học Phần (Class Sections)

### 3.1. Phân Trang Danh Sách Lớp Học Phần
- **Method:** `GET`
- **Path:** `/api/v1/classes` (Alias: `/api/classes`)
- **Phân quyền:**
  - `ADMIN`: Xem tất cả lớp học phần.
  - `LECTURER`: Xem các lớp được phân công giảng dạy.
  - `STUDENT`: Xem các lớp mở đăng ký hoặc đã ghi danh.
- **Query Params:**
  - `page` (int, default: 0)
  - `size` (int, default: 10)
  - `search` (string, optional: tìm kiếm theo mã lớp, mã môn, tên môn)
  - `semesterId` (Long, optional: lọc theo học kỳ)
  - `courseId` (Long, optional: lọc theo học phần)
  - `lecturerId` (Long, optional: lọc theo giảng viên)
  - `status` (enum: `OPEN`, `ACTIVE`, `CLOSED`, `CANCELLED`, default: all)
  - `sort` (string, default: `className,asc`)

### 3.2. Lấy Tóm Tắt Lớp Học Phần (Cho Dropdown Selection)
- **Method:** `GET`
- **Path:** `/api/v1/classes/summaries` (Alias: `/api/classes/summaries`)
- **Query Params:** `semesterId` (Long, optional)
- **Response:** `List<ClassSectionSummaryDto>`

### 3.3. Thống Kê Bento Metrics Cho Lớp Học Phần
- **Method:** `GET`
- **Path:** `/api/v1/classes/stats` (Alias: `/api/classes/stats`)
- **Query Params:** `semesterId` (Long, optional)
- **Response:** `ClassSectionStatsResponse` (`totalClasses`, `activeClasses`, `fullCapacityClasses`, `underCapacityClasses`)

### 3.4. Kiểm Tra Tính Khả Dụng Của Mã Lớp
- **Method:** `GET`
- **Path:** `/api/v1/classes/check-name` (Alias: `/api/classes/check-name`)
- **Query Params:** `className` (String, required)
- **Response:** `{ "available": true }`

### 3.5. Chi Tiết Lớp Học Phần
- **Method:** `GET`
- **Path:** `/api/v1/classes/{className}` (Alias: `/api/classes/{className}`)
- **Response:** `ClassSectionResponse`

### 3.6. Tạo Mới Lớp Học Phần
- **Method:** `POST`
- **Path:** `/api/v1/classes` (Alias: `/api/classes`)
- **Phân quyền:** `ADMIN`
- **Request Body (`ClassSectionCreateRequest`):**
```json
{
  "className": "IT301.01",
  "courseId": 1,
  "semesterId": 1,
  "lecturerId": 2,
  "numberOfSlots": 70,
  "maxStudents": 70,
  "status": "OPEN"
}
```

### 3.7. Cập Nhật Thông Tin Lớp Học Phần
- **Method:** `PUT`
- **Path:** `/api/v1/classes/{className}` (Alias: `/api/classes/{className}`)
- **Phân quyền:** `ADMIN`
- **Request Body (`ClassSectionUpdateRequest`):**
```json
{
  "lecturerId": 3,
  "numberOfSlots": 75,
  "maxStudents": 75,
  "status": "ACTIVE"
}
```

### 3.8. Xóa Lớp Học Phần
- **Method:** `DELETE`
- **Path:** `/api/v1/classes/{className}` (Alias: `/api/classes/{className}`)
- **Phân quyền:** `ADMIN`
- **Ràng buộc:** Chặn xóa nếu lớp đã có sinh viên ghi danh hoặc lịch sử phiên điểm danh. Trả lỗi `CONFLICT` (409) rõ ràng.

### 3.9. Danh Sách Sinh Viên Theo Lớp Học Phần (Nested Route)
- **Method:** `GET`
- **Path:** `/api/v1/classes/{className}/students` (Alias: `/api/classes/{className}/students`)
- **Phân quyền:** `ADMIN`, `LECTURER` (lớp phụ trách)
- **Response:** `List<EnrollmentResponse>`

### 3.10. Ghi Danh Sinh Viên Vào Lớp (Nested Route)
- **Method:** `POST`
- **Path:** `/api/v1/classes/{className}/students` (Alias: `/api/classes/{className}/students`)
- **Phân quyền:** `ADMIN`
- **Request Body:** `{ "studentId": 101 }`

---

## 4. Danh Sách Endpoint — F-15: Ghi Danh Sinh Viên (Enrollments)

### 4.1. Phân Trang Danh Sách Ghi Danh Toàn Hệ Thống
- **Method:** `GET`
- **Path:** `/api/v1/enrollments` (Alias: `/api/enrollments`)
- **Phân quyền:** `ADMIN`
- **Query Params:**
  - `page` (int, default: 0)
  - `size` (int, default: 10)
  - `className` (String, optional)
  - `studentId` (Long, optional)
  - `status` (enum: `ENROLLED`, `DROPPED`, `CANCELLED`, default: all)
  - `search` (String, optional: tìm kiếm MSSV, tên SV, email)
  - `sort` (String, default: `id,desc`)

### 4.2. Chi Tiết Bản Ghi Ghi Danh
- **Method:** `GET`
- **Path:** `/api/v1/enrollments/{id}` (Alias: `/api/enrollments/{id}`)
- **Response:** `EnrollmentResponse`

### 4.3. Tạo Mới Ghi Danh (Enroll Student)
- **Method:** `POST`
- **Path:** `/api/v1/enrollments` (Alias: `/api/enrollments`)
- **Phân quyền:** `ADMIN`
- **Request Body (`EnrollmentCreateRequest`):**
```json
{
  "className": "IT301.01",
  "studentId": 105
}
```
- **Quy tắc kiểm duyệt nghiệp vụ:**
  1. Người dùng phải có role `STUDENT` (`INVALID_STUDENT_ROLE`).
  2. Lớp học phần phải tồn tại và đang ở trạng thái cho phép (`CLASS_NOT_FOUND`, `CLASS_NOT_OPEN`).
  3. Chặn ghi danh trùng lặp cùng sinh viên vào cùng lớp (`DUPLICATE_ENROLLMENT`). Được bảo vệ 2 lớp: Unique Constraint DB `V4` + logic Service.
  4. Sĩ số lớp không được vượt quá số chỗ tối đa (`numberOfSlots` / `maxStudents`) (`CLASS_CAPACITY_EXCEEDED`).

### 4.4. Hủy Ghi Danh (Unenroll / Drop)
- **Method:** `DELETE`
- **Path:** `/api/v1/enrollments/{id}` (Alias: `/api/enrollments/{id}`)
- **Phân quyền:** `ADMIN`
- **Ràng buộc:** Hủy an toàn, cập nhật sĩ số thời gian thực mà không làm mất tính toàn vẹn dữ liệu.

---

## 5. Từ Điển Mã Lỗi Chuẩn Hóa (ErrorCode Dictionary)

| Mã Lỗi | HTTP Status | Thông Điệp Tiếng Việt |
| :--- | :---: | :--- |
| `CLASS_NOT_FOUND` | 404 | Lớp học phần không tồn tại |
| `ENROLLMENT_NOT_FOUND` | 404 | Bản ghi ghi danh không tồn tại |
| `STUDENT_NOT_FOUND` | 404 | Sinh viên không tồn tại |
| `INVALID_STUDENT_ROLE` | 400 | Người dùng không phải là sinh viên |
| `DUPLICATE_ENROLLMENT` | 409 | Sinh viên đã được ghi danh vào lớp học phần này |
| `INVALID_LECTURER_ROLE`| 400 | Người dùng được phân công không có vai trò giảng viên |
| `CLASS_ALREADY_EXISTS` | 409 | Mã lớp học phần đã tồn tại trong hệ thống |
| `CLASS_NOT_OPEN` | 400 | Lớp học phần không ở trạng thái mở đăng ký |
| `CANNOT_MODIFY_CLASS_NAME` | 400 | Không thể thay đổi mã định danh lớp học phần |
| `CLASS_CAPACITY_EXCEEDED` | 400 | Lớp học phần đã đạt sĩ số tối đa |
