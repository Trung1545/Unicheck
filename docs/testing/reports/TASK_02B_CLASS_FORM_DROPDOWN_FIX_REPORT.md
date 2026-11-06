# BÁO CÁO NGHIỆM THU: DEBUG VÀ SỬA LỖI FORM "THÊM LỚP HỌC PHẦN MỚI" (TASK-02B)

**Dự án:** UniCheck — Hệ thống Điểm danh Sinh trắc học  
**Phân hệ:** Quản lý Lớp học phần & Kế hoạch Đào tạo (TASK-02B / F-14 & F-15)  
**Ngày thực hiện:** 18/10/2026  
**Trạng thái:** **PASSED / RESOLVED**  

---

## 1. TỔNG QUAN VÀ BỐI CẢNH

Theo phản ánh từ QA và Admin, tại trang `/admin/classes` xuất hiện các lỗi giao diện và trải nghiệm khi mở modal **"Thêm Lớp học phần Mới"**:
1. Dropdown *"Chọn Môn học từ Catalog đào tạo"* không có lựa chọn nào, chỉ hiển thị placeholder mặc định.
2. Dropdown *"Học kỳ & niên khóa"* không thể lựa chọn học kỳ.
3. Dropdown *"Giảng viên giảng dạy"* cần được xác minh khả năng liên kết với tài khoản Giảng viên ACTIVE từ phân hệ F-07.
4. Modal xuất hiện cùng lúc **hai nút "Hủy"** ở hai khu vực khác nhau gây nhầm lẫn giao diện.

---

## 2. KẾT QUẢ KIỂM TRA POSTGRESQL (PHẦN 1)

Kiểm tra trực tiếp trong Docker container `unicheck_postgres` (Database: `unicheck_db`):

```sql
SELECT id, code, name, credits FROM courses;
SELECT id, code, name, status FROM semesters;
SELECT id, username, role, status FROM users WHERE role = 'LECTURER';
SELECT class_name, course_id, semester_id, lecturer_id, max_students, status FROM class_sections;
```

### Kết quả dữ liệu:
- **Bảng `courses`:** 1 bản ghi (`id=1`, `code=IT301`, `name="Lập trình Web"`, `credits=3`).
- **Bảng `semesters`:** 1 bản ghi (`id=1`, `code=FALL2026`, `name="FALL2026"`, `status=ACTIVE`).
- **Bảng `users` / `lecturer_profiles`:** 1 bản ghi giảng viên (`id=3`, `username=lecturer_test`, `role=LECTURER`, `status=ACTIVE`, `department="Khoa Công nghệ Thông tin"`).
- **Bảng `class_sections`:** Đã lưu trữ lớp ban đầu `IT301` và sau kiểm thử tích hợp đã lưu thành công lớp thứ hai `IT301.02`.

> [!NOTE]
> Khóa ngoại trong PostgreSQL: `class_sections.course_id -> courses.id`, `class_sections.semester_id -> semesters.id`, `class_sections.lecturer_id -> users.id`. Toàn bộ dữ liệu đều tuân thủ toàn vẹn tham chiếu (Referential Integrity).

---

## 3. KẾT QUẢ KIỂM TRA BACKEND API (PHẦN 2)

Đã kiểm tra trực tiếp các REST API trên Spring Boot (`http://localhost:8080`):

| Endpoint | Quyền | Status | Cấu trúc Envelope | Dữ liệu trả về |
| :--- | :--- | :--- | :--- | :--- |
| `GET /api/v1/courses/summaries` | ADMIN, LECTURER | `200 OK` | `ApiResponse<List<CourseSummaryDto>>` | `[{"id":1, "code":"IT301", "name":"Lập trình Web", "credits":3}]` |
| `GET /api/v1/semesters?size=100` | ADMIN, LECTURER | `200 OK` | `ApiResponse<PageResponse<SemesterResponse>>` | `data.content: [{"id":1, "code":"FALL2026", "status":"ACTIVE"}]` |
| `GET /api/v1/users?role=LECTURER&status=ACTIVE&size=100` | ADMIN | `200 OK` | `ApiResponse<PageResponse<UserResponse>>` | `data.content: [{"id":3, "username":"lecturer_test", "role":"LECTURER", "status":"ACTIVE"}]` |
| `POST /api/v1/classes` | ADMIN | `200 OK` | `ApiResponse<ClassSectionResponse>` | Tạo lớp học phần mới và trả về DTO hoàn chỉnh |

Các backend API hoạt động chuẩn theo OpenAPI contract, phân quyền Spring Security RBAC chuẩn xác, không có lỗi 401, 403 hay 500.

---

## 4. NGUYÊN NHÂN GỐC RỄ & GIẢI PHÁP FRONTEND (PHẦN 3 & 4)

### 4.1. Lỗi hai nút "Hủy" trên Modal
- **Nguyên nhân:** Component `<Modal>` tại `frontend/src/common-ui/Modal.tsx` mặc định render một footer chứa button *"Hủy"* (`cancelText = 'Hủy'`) trừ khi prop `hideFooter={true}` được truyền vào. Trong khi đó, component `ClassSectionPage.tsx` lại định nghĩa một hàng nút hành động riêng (`Button "Hủy bỏ"` và `Button "Lưu & Mở lớp"`) nằm bên trong form con của modal. Điều này khiến cả hai footer cùng xuất hiện. Tình trạng tương tự cũng xảy ra ở modal Sửa và modal Xác nhận xóa.
- **Giải pháp:** Bổ sung `hideFooter={true}` cho cả 3 modal (`isCreateModalOpen`, `isEditModalOpen`, `isDeleteModalOpen`), đảm bảo chỉ hiển thị duy nhất bộ nút điều khiển của form.

### 4.2. Dropdown Môn học và Học kỳ trống hoặc không chọn được
- **Nguyên nhân:** 
  1. Khi database ban đầu trống (chưa có Môn học/Học kỳ nào được tạo), hàm `loadLookups` chỉ được gọi 1 lần duy nhất khi mount trang và lưu mảng rỗng `[]`.
  2. Khi người dùng bấm nút *"Thêm lớp học phần mới"*, hàm `handleOpenCreateModal` trước đây không thực hiện re-fetch danh mục mới nhất, dẫn đến form luôn giữ trạng thái mảng rỗng.
  3. Form thiếu trạng thái tải (`isLookupsLoading`), thiếu xử lý lỗi kết nối (`lookupsError`), và không có thông báo Empty State hướng dẫn người dùng tạo dữ liệu danh mục khi database trống.
  4. Trước đây `loadLookups` còn bị ràng buộc phụ thuộc vào `selectedSemester`, khiến việc tải danh mục môn học và giảng viên bị chậm hoặc chập chờn.
- **Giải pháp:**
  1. Tách biệt `loadLookups` để fetch toàn bộ danh mục (`getCourseSummariesApi()`, `getSemestersApi({ size: 100 })`, `getUsersApi({ role: 'LECTURER', status: 'ACTIVE', size: 100 })`) độc lập với bộ lọc của bảng.
  2. Bổ sung `await loadLookups()` ngay khi kích hoạt `handleOpenCreateModal` để luôn đồng bộ danh mục mới nhất.
  3. Bổ sung `isLookupsLoading` kèm hiệu ứng Loading Spinner trực quan cho từng dropdown.
  4. Bổ sung Empty State Alert Banner màu hổ phách kèm nút điều hướng trực tiếp:
     - Nếu chưa có môn học: Hiển thị cảnh báo và nút *"Tạo Môn học"* dẫn tới `/admin/courses`.
     - Nếu chưa có học kỳ: Hiển thị cảnh báo và nút *"Tạo Học kỳ"* dẫn tới `/admin/semesters`.
  5. Tự động đồng bộ (Auto-sync) giá trị mặc định cho form khi dữ liệu lookups được tải về (tự chọn môn học đầu tiên, tự chọn học kỳ có trạng thái `ACTIVE`).
  6. Chuẩn hóa nhãn hiển thị cho dropdown:
     - Môn học: `${c.code} — ${c.name} (${c.credits} TC)`
     - Học kỳ: `${s.name} (${s.code}) [Học kỳ hiện hành]`
     - Giảng viên: `${lec.fullName} (${lec.code || lec.username}) — ${lec.department}`

---

## 5. KẾT QUẢ KIỂM THỬ VÀ XÁC MINH (PHẦN 5)

### 5.1. Unit Test Suite (`npm test -- --run`)
Đã bổ sung 3 test cases mới vào `frontend/src/test/class-section-enrollment.test.ts`:
- **Test 9:** Lookup Dropdown Label Formatting Contract (`PASS`).
- **Test 10:** Lookup Empty State Guards & Submission Safety (`PASS`).
- **Test 11:** Modal `hideFooter` Guard against Duplicate Cancel Buttons (`PASS`).

**Kết quả tổng hợp:** **81 / 81 tests PASS** (100% Passed, 0 Failures).

### 5.2. Frontend Build (`npm run build`)
```
✓ 1686 modules transformed.
dist/index.html                   0.86 kB │ gzip:   0.53 kB
dist/assets/index-D7x5ABWY.css   61.70 kB │ gzip:  10.75 kB
dist/assets/index-6zevfEVK.js   926.91 kB │ gzip: 234.55 kB
✓ built in 10.06s
Exit code: 0
```

### 5.3. Triển khai và kiểm thử Docker Nginx Runtime
- Copy toàn bộ bản build mới vào container `unicheck_frontend`:
  `docker cp frontend/dist/. unicheck_frontend:/usr/share/nginx/html/`
- Nginx reload: `docker exec unicheck_frontend nginx -s reload` thành công.
- Trình duyệt và client truy cập `http://localhost/admin/classes` tải file bundle mới `index-6zevfEVK.js`.

### 5.4. Xác minh tạo lớp và lưu trữ vào PostgreSQL
- Gọi POST `/api/v1/classes` với payload:
  ```json
  {
    "className": "IT301.02",
    "courseId": 1,
    "semesterId": 1,
    "lecturerId": 3,
    "maxStudents": 45,
    "numberOfSlots": 45,
    "status": "OPEN"
  }
  ```
- Kết quả API: `200 OK`, `success: true`.
- Kết quả truy vấn Database:
  ```
   class_name | course_id | semester_id | lecturer_id | max_students | status |         created_at         
  ------------+-----------+-------------+-------------+--------------+--------+----------------------------
   IT301      |         1 |           1 |           3 |           30 | ACTIVE | 2026-10-18 15:19:25.346646
   IT301.02   |         1 |           1 |           3 |           45 | OPEN   | 2026-10-18 15:25:52.672831
  ```
- Dữ liệu lớp học phần `IT301.02` đã được lưu bền vững vào PostgreSQL, đầy đủ liên kết tới môn học `IT301`, học kỳ `FALL2026`, và giảng viên `lecturer_test`.

---

## 6. KẾT LUẬN

Toàn bộ 4 vấn đề được nêu trong yêu cầu nhiệm vụ đã được khắc phục triệt để:
1. Dropdown Môn học tải và hiển thị chính xác tên, mã môn, số tín chỉ từ Catalog đào tạo thật.
2. Dropdown Học kỳ tải và đánh dấu rõ học kỳ hiện hành `[Học kỳ hiện hành]`.
3. Dropdown Giảng viên tải danh sách giảng viên ACTIVE kèm mã và đơn vị công tác.
4. Triệt tiêu hoàn toàn nút "Hủy" bị trùng lặp trên tất cả các Modal.
5. Bản build mới đã được deploy và kiểm chứng hoạt động ổn định trên môi trường Docker.
