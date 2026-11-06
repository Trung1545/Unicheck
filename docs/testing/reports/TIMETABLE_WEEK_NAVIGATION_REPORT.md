# BÁO CÁO NÂNG CẤP ĐIỀU HƯỚNG TUẦN THỜI KHÓA BIỂU — TASK-02D
**UniCheck — Hệ thống Điểm danh Sinh trắc học**  
**Phân hệ:** Quản lý Thời khóa biểu & Phân bổ Giảng đường (TASK-02D / Feature F-16)  
**Ngày hoàn thành:** 18/10/2026  
**Trạng thái kiểm thử:** **PASSED (90/90 Tests Pass & Production Build Succeeded)**  
**Đối chiếu thiết kế Google Stitch:** Screen ID `ac1b85bea7f6478e9c77fd6a4e9594f9` | Project ID `3214444012266330806`

---

## 1. TỔNG QUAN YÊU CẦU & KẾT QUẢ TRIỂN KHAI

Hệ thống quản lý thời khóa biểu đã được nâng cấp toàn diện để cho phép người dùng (ADMIN, LECTURER, STUDENT) xem và điều hướng thời khóa biểu của **tuần hiện tại, tuần trước và các tuần tiếp theo** một cách chính xác theo múi giờ `Asia/Ho_Chi_Minh`, loại bỏ hoàn toàn lỗi lệch ngày do chuyển đổi UTC, hỗ trợ đủ 7 ngày trong tuần (Thứ Hai đến Chủ Nhật) và tuân thủ phân quyền RBAC.

### Các tiêu chí nghiệm thu đạt được:
1. **Bộ điều hướng tuần chuẩn Stitch UI:**
   - Nút **"Tuần trước"** (biểu tượng mũi tên trái `ChevronLeft`): Giảm chính xác 7 ngày.
   - Nút **"Tuần sau"** (biểu tượng mũi tên phải `ChevronRight`): Tăng chính xác 7 ngày.
   - Nút **"Hiện tại"**: Trở về ngay tuần học chứa ngày hôm nay theo thời gian thực.
   - Hiển thị nhãn tuần: `Tuần [N] (DD/MM/YYYY - DD/MM/YYYY)` tính toán theo ngày bắt đầu của học kỳ.
   - Tích hợp **Bộ chọn ngày trực quan (Date Picker)**: Nhấp vào nhãn ngày để chọn ngày bất kỳ và lập tức chuyển đến tuần tương ứng.
2. **Quy tắc tuần & Múi giờ Asia/Ho_Chi_Minh:**
   - Tuần bắt đầu từ **Thứ Hai** (Day 1) và kết thúc vào **Chủ Nhật** (Day 7).
   - Lưới lịch hiển thị đầy đủ 7 cột (trước đây chỉ có 6 cột từ Thứ Hai đến Thứ Bảy, dẫn đến việc các tiết học vào Chủ Nhật bị ẩn).
   - Xử lý hoàn hảo khi chuyển ranh giới tháng (ví dụ 26/10–01/11/2026) và ranh giới năm (ví dụ 28/12/2026–03/01/2027).
   - Không sử dụng `toISOString().split('T')[0]` tại nửa đêm (gây lệch lùi 1 ngày do UTC-0 so với UTC+7); thay vào đó sử dụng các hàm trích xuất lịch địa phương an toàn tuyệt đối.
3. **Phân quyền thực tế (RBAC):**
   - **ADMIN (`/admin/timetable`, `/dashboard/timetable`):** Xem toàn trường, lọc theo phòng học / giảng viên / học kỳ, toàn quyền Thêm / Sửa / Xóa tiết học, Công bố TKB, Nhập/Xuất Excel.
   - **LECTURER (`/lecturer/timetable`):** Xem lịch giảng dạy cá nhân thông qua API `/api/v1/timetable/me`, có nút truy cập nhanh "Vào điểm danh" (chuyển tiếp tới TASK-05), không thể tự ý sửa/xóa TKB.
   - **STUDENT (`/student/timetable`, `/timetable`):** Xem lịch học các lớp học phần đã đăng ký thành công thông qua API `/api/v1/timetable/me`, chế độ xem chỉ đọc.

---

## 2. DANH SÁCH FILE THAY ĐỔI & BỔ SUNG

| STT | Đường dẫn File | Loại thay đổi | Mô tả nội dung xử lý |
| :---: | :--- | :---: | :--- |
| **1** | `frontend/src/utils/timetable-date.utils.ts` | **Tạo mới** | Module tiện ích lịch học chuẩn hóa: tính toán Thứ Hai, Chủ Nhật, bước nhảy tuần (+/- 7 ngày), 7 ngày trong tuần, số tuần trong học kỳ, kiểm tra ngoài khung học kỳ, định dạng YYYY-MM-DD và DD/MM/YYYY không bị lệch UTC. |
| **2** | `frontend/src/test/timetable-date.test.ts` | **Tạo mới** | Bộ unit test kiểm thử 9 kịch bản trọng yếu: bắt đầu Thứ Hai kết thúc Chủ Nhật, tiến tuần, lùi tuần, vượt tháng (Oct-Nov), vượt năm (2026-2027), đủ 7 ngày, chống lệch UTC tại 00:00:00, tính số tuần học kỳ, và kiểm tra biên học kỳ. |
| **3** | `frontend/src/pages/admin/MasterTimetablePage.tsx` | **Cập nhật** | - Tích hợp `timetable-date.utils.ts`.<br>- Bổ sung đầy đủ 7 cột cho lưới lịch tuần (Thứ Hai đến Chủ Nhật) với `grid-cols-[130px_repeat(7,1fr)]`.<br>- Thanh công cụ điều hướng tuần chuẩn Stitch UI có Date Picker.<br>- Tải dữ liệu động theo phân quyền: Admin dùng `getTimetableSlotsApi`, Giảng viên/Sinh viên dùng `getMyTimetableApi`.<br>- Ẩn/hiện tác vụ chỉnh sửa theo vai trò người dùng. |
| **4** | `frontend/src/routes/index.tsx` | **Cập nhật** | Đăng ký các route thời khóa biểu cho Giảng viên và Sinh viên: `/lecturer/timetable`, `/student/timetable`, và `/timetable`. |

---

## 3. CÁC API BACKEND SỬ DỤNG

Hệ thống tái sử dụng 100% các API hiện có của Spring Boot `TimetableController` (`/api/v1/timetable`), không làm phát sinh endpoint thừa:

1. **`GET /api/v1/timetable/slots`**:
   - Tham số: `startDate`, `endDate`, `semesterId`, `lecturerId`, `roomId`, `status`.
   - Phân quyền: `isAuthenticated()`.
   - Sử dụng cho ADMIN để tải lịch tổng thể toàn trường hoặc lọc đa tiêu chí theo tuần được chọn.
2. **`GET /api/v1/timetable/me`**:
   - Tham số: `startDate`, `endDate`.
   - Phân quyền: `isAuthenticated()`.
   - Tự động nhận diện `UserPrincipal`:
     - Nếu `STUDENT`: Truy vấn các lớp sinh viên đã `ENROLLED` (`findStudentTimetable`).
     - Nếu `LECTURER`: Truy vấn các lớp giảng viên được phân công (`findLecturerTimetable`).
     - Nếu `ADMIN`: Truy vấn toàn bộ slot trong khoảng ngày.
3. **`GET /api/v1/timetable/stats`**:
   - Tham số: `semesterId`, `weekStartDate`.
   - Trả về KPI thống kê số tiết học, số lớp, cảnh báo trùng lịch và tỷ lệ sử dụng phòng.
4. **`POST /api/v1/timetable/conflicts/check`**:
   - Kiểm tra xung đột trước khi lưu (Pre-flight check) phòng học, giảng viên, lớp học phần và ngày nghỉ lễ.

---

## 4. CÁCH HỆ THỐNG XỬ LÝ LỊCH HỌC LẶP THEO TUẦN (RECURRING SCHEDULES)

Hệ thống UniCheck xử lý lịch học lặp theo quy chuẩn dữ liệu tường minh (Materialized Occurrences):

1. **Khi tạo lịch học với tùy chọn "Lặp lại hàng tuần" (`recurring: true`):**
   - Backend xác định ngày kết thúc lặp (`recurringUntil`), tối đa không vượt quá ngày kết thúc của học kỳ (`semester.getEndDate()`).
   - Vòng lặp `while (!nextDate.isAfter(recurEnd))` tiến từng tuần (`plusWeeks(1)`).
   - Tại mỗi tuần, hệ thống tự động:
     - Kiểm tra ngày nghỉ lễ thông qua `holidayRepository.existsBySemesterIdAndHolidayDate(...)`. Nếu rơi vào ngày nghỉ lễ, **tự động bỏ qua tuần đó** mà không làm đứt chuỗi lặp.
     - Kiểm tra xung đột phòng học, giảng viên và lớp học phần.
     - Nếu hợp lệ, lưu một bản ghi `TimetableSlot` riêng biệt với `date = nextDate` vào PostgreSQL.
2. **Khi người dùng điều hướng sang tuần khác trên giao diện:**
   - Giao diện gửi `startDate` (Thứ Hai) và `endDate` (Chủ Nhật) của tuần được chọn lên Backend.
   - Backend lọc chính xác các bản ghi có `s.date BETWEEN :startDate AND :endDate`.
   - **Đảm bảo tính chân thực của dữ liệu:** Nếu một buổi học chỉ diễn ra 1 ngày duy nhất (`recurring: false`), các tuần sau sẽ hiển thị ô trống; giao diện tuyệt đối không tự ý sao chép hay hiển thị dữ liệu giả ngoài khoảng thời gian học kỳ.

---

## 5. KẾT QUẢ KIỂM THỬ THỰC TẾ

### 5.1. Kiểm thử Unit Test (Frontend)
- Tổng số test case thực thi: **90 / 90 tests PASSED** (0 failures).
- Bao gồm 9 test case mới trong `frontend/src/test/timetable-date.test.ts`:
  - `✔ 1. Monday Start & Sunday End: Given 18/10/2026 (Sunday), returns week 12/10/2026 - 18/10/2026`
  - `✔ 2. Forward Navigation: Week 12/10-18/10 -> Week 19/10-25/10/2026`
  - `✔ 3. Month Boundary Crossing: Week 19/10-25/10 -> Week 26/10-01/11/2026`
  - `✔ 4. Backward Navigation: Week 26/10-01/11 -> Week 19/10-25/10 -> Week 12/10-18/10`
  - `✔ 5. Year Boundary Crossing: Week containing New Year 2027 (28/12/2026 - 03/01/2027)`
  - `✔ 6. Strict 7 Days Generation: Monday (Thứ Hai) to Sunday (Chủ Nhật)`
  - `✔ 7. Zero UTC Off-By-One Bug: Local calendar methods never subtract 1 day`
  - `✔ 8. Semester Week Number Calculation (FALL2026 started 2026-10-18)`
  - `✔ 9. Semester Window Bounds Check`

### 5.2. Kiểm thử API qua các tuần cụ thể
| Tuần kiểm thử | Khoảng ngày (`startDate` - `endDate`) | Kết quả trả về | Ghi chú kiểm chứng |
| :--- | :--- | :---: | :--- |
| **Tuần 1** | `2026-10-12` – `2026-10-18` | **1 slot** (Lớp `IT301` ngày 18/10/2026 - Chủ Nhật) | Hiển thị chính xác tại cột Chủ Nhật trên lưới lịch 7 ngày. |
| **Tuần 2** | `2026-10-19` – `2026-10-25` | **0 slot** | Tuần không có lịch, hiển thị ô trống sạch sẽ, không có dữ liệu rác. |
| **Tuần 3** | `2026-10-26` – `2026-11-01` | **0 slot** | Chuyển tiếp tháng 10 sang tháng 11 chính xác (Chủ Nhật là 01/11). |
| **Ranh giới năm** | `2026-12-28` – `2027-01-03` | **HTTP 200 OK** | Chuyển năm 2026 sang 2027 mượt mà, không gặp lỗi tràn ngày/tháng. |
| **Phân quyền** | `GET /api/v1/timetable/me` | **HTTP 200 OK** | Giảng viên và Sinh viên chỉ thấy đúng lịch thuộc phạm vi phân công/ghi danh. |
| **Ngày nghỉ lễ** | `POST /api/v1/timetable/conflicts/check` | `hasConflict: true` | Phát hiện chính xác ngày nghỉ lễ của học kỳ và chặn xếp lịch vi phạm. |

### 5.3. Kiểm tra Build & Triển khai Docker
- `npm run build`: Hoàn thành trong **11.14s**, 1687 modules transformed, không có lỗi kiểu TypeScript.
- Triển khai bản build mới vào container `unicheck_frontend` và reload Nginx thành công.

---

## 6. HƯỚNG DẪN TRẢI NGHIỆM TRÊN TRÌNH DUYỆT

1. Mở trình duyệt và truy cập trang Thời khóa biểu:
   - Dành cho Quản trị viên: [http://localhost/admin/timetable](http://localhost/admin/timetable)
   - Dành cho Giảng viên: [http://localhost/lecturer/timetable](http://localhost/lecturer/timetable)
   - Dành cho Sinh viên: [http://localhost/student/timetable](http://localhost/student/timetable)
2. Nhấn `Ctrl + F5` để tải tài nguyên web mới nhất.
3. Thao tác điều hướng:
   - Nhấn **`>`** (Tuần sau): Khoảng ngày chuyển thành `(19/10/2026 - 25/10/2026)` -> Lưới lịch tuần cập nhật sang tuần tiếp theo (lịch trống).
   - Nhấn **`<`** (Tuần trước): Quay về `(12/10/2026 - 18/10/2026)` -> Xuất hiện ngay buổi học `IT301` tại cột **Chủ Nhật 18/10**.
   - Nhấp trực tiếp vào nhãn `(DD/MM/YYYY - DD/MM/YYYY)` để mở Date Picker và chọn một ngày bất kỳ.
   - Nhấn nút **"Hiện tại"** để trở về tuần hiện hành của hôm nay bất kỳ lúc nào.
