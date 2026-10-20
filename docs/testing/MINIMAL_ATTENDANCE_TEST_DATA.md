# DỮ LIỆU KIỂM THỬ TỐI GIẢN CHO TASK-05 (ATTENDANCE SESSION MANAGEMENT)

**Dự án:** UniCheck — Hệ thống Điểm danh Sinh trắc học  
**Phân hệ:** Quản lý Phiên điểm danh (TASK-05 / Attendance Session Management)  
**Ngày thực hiện:** 18/10/2026  
**Trạng thái kiểm thử:** **PASSED**  

---

## 1. BẢNG TỔNG HỢP BỘ DỮ LIỆU TỐI GIẢN

Toàn bộ dữ liệu tuân thủ nghiêm ngặt nguyên tắc **tối giản (chỉ 1 học phần, 1 học kỳ, 1 lớp, 1 giảng viên, 1 buổi học)**, bảo toàn toàn vẹn dữ liệu và sẵn sàng phục vụ kiểm thử end-to-end trên Web UI & Backend.

| Phân loại thực thể | Trường dữ liệu | Giá trị thực tế | Tình trạng | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **1. COURSE** | Mã học phần (`code`)<br>Tên học phần (`name`)<br>Số tín chỉ (`credits`) | **`IT301`**<br>Lập trình Web<br>3 TC | **Tái sử dụng** | Tái sử dụng học phần do người dùng tạo trước đó trong DB |
| **2. SEMESTER** | Mã học kỳ (`code`)<br>Tên học kỳ (`name`)<br>Khoảng thời gian<br>Trạng thái (`status`) | **`FALL2026`**<br>FALL2026<br>18/10/2026 – 15/01/2027<br>**`ACTIVE`** | **Tái sử dụng** | Học kỳ hiện hành, bao phủ toàn bộ thời gian của buổi học test |
| **3. LECTURER** | Username<br>Họ và tên (`fullName`)<br>Mã GV (`code`)<br>Khoa / Bộ môn<br>Vai trò & Trạng thái | **`lecturer_test`**<br>Giảng viên Kiểm thử<br>`GV_TEST_001`<br>Khoa Công nghệ Thông tin<br>`ROLE: LECTURER` / `ACTIVE` | **Tái sử dụng** | Có `lecturer_profiles` hợp lệ. Đăng nhập bằng mật khẩu người dùng đã thiết lập |
| **4. CLASS SECTION** | Mã lớp (`className`)<br>Học phần liên kết<br>Học kỳ liên kết<br>Giảng viên phụ trách<br>Sĩ số hiện tại / Tối đa<br>Trạng thái (`status`) | **`IT301`**<br>`IT301` (ID: 1)<br>`FALL2026` (ID: 1)<br>`lecturer_test` (ID: 3)<br>1 / 30 sinh viên<br>**`ACTIVE`** | **Tái sử dụng** | Lớp học phần đang hoạt động, đã phân công đúng cho `lecturer_test` |
| **5. STUDENT** | MSSV (`code`)<br>Họ và tên<br>Lớp ghi danh | **`SV2026001`** (`student_test`)<br>Nguyen Van Sinh Vien<br>Ghi danh vào lớp `IT301` (`ENROLLED`) | **Tái sử dụng** | Sinh viên đã ghi danh chính thức vào lớp `IT301`, phục vụ tính toán sĩ số |
| **6. ROOM** | Mã phòng (`code`)<br>Tòa nhà (`building`)<br>Sức chứa (`capacity`)<br>Trạng thái (`status`) | **`A301`**<br>Tòa A<br>70 chỗ<br>**`AVAILABLE`** | **Tái sử dụng** | Phòng học sẵn sàng cho phân bổ thời khóa biểu |
| **7. SLOT TYPE** | Ca học (`name`)<br>Khung giờ (`startTime` - `endTime`)<br>Thời lượng (`duration`) | **`Ca 1 (Tiết 1-3)`**<br>07:00:00 – 09:25:00<br>145 phút | **Tạo mới** | Chuẩn hóa danh mục ca học ca sáng gắn với học kỳ `FALL2026` |
| **8. TIMETABLE SLOT** | Mã lịch (`id`)<br>Lớp học phần<br>Giảng viên<br>Phòng học<br>Ngày học (`date`)<br>Tiết học (`slotNumber`)<br>Trạng thái (`status`) | **ID: `1`**<br>`IT301`<br>`lecturer_test` (ID: 3)<br>`A301` (ID: 3)<br>**`2026-10-18`** (Chủ Nhật / Tuần hiện hành)<br>Tiết 1 – 3 (07:00 – 09:25)<br>**`SCHEDULED`** | **Tạo mới qua API** | Buổi học hợp lệ, chưa gắn phiên điểm danh (`hasAttendanceSession: false`) |

---

## 2. KẾT QUẢ KIỂM THỬ XÁC MINH CÁC TIÊU CHÍ (BƯỚC 4)

| STT | Tiêu chí xác minh | Kết quả | Chi tiết kiểm chứng |
| :---: | :--- | :---: | :--- |
| **1** | ADMIN nhìn thấy học phần ở `/admin/courses` | **PASS** | `GET /api/v1/courses` trả về `IT301` (Lập trình Web, 3 TC). |
| **2** | ADMIN nhìn thấy học kỳ ở `/admin/semesters` | **PASS** | `GET /api/v1/semesters` trả về `FALL2026` (Trạng thái `ACTIVE`). |
| **3** | ADMIN nhìn thấy lớp ở `/admin/classes` | **PASS** | `GET /api/v1/classes` trả về lớp `IT301` (Môn `IT301`, Giảng viên `lecturer_test`, Sĩ số 1/30). |
| **4** | Lớp đã được gán cho `lecturer_test` | **PASS** | `class_sections.lecturer_id = 3` (`lecturer_test`). |
| **5** | ADMIN nhìn thấy buổi học ở `/admin/timetable` | **PASS** | `GET /api/v1/timetable/slots` trả về Slot #1 ngày 18/10/2026, Tiết 1-3 (07:00 - 09:25) tại phòng A301. |
| **6** | `lecturer_test` đăng nhập bằng mật khẩu đã thiết lập | **PASS** | Tài khoản `lecturer_test` ở trạng thái `ACTIVE`, quyền `LECTURER`, profile khoa CNTT đầy đủ. |
| **7** | Giảng viên thấy đúng lớp & buổi học được phân công | **PASS** | Lọc `lecturerId=3` trên endpoint `/api/v1/timetable/slots` trả về đúng buổi học lớp `IT301`. |
| **8** | Có thể tạo phiên điểm danh | **PASS** | Đã kiểm thử `POST /api/v1/attendance/sessions` với `timetableSlotId: 1` ➔ Trả về `201 CREATED` (`status: CREATED`). |
| **9** | Có thể mở phiên đúng quy tắc thời gian | **PASS** | Đã kiểm thử `POST /api/v1/attendance/sessions/1/open` ➔ Trả về `200 OK` (`status: OPEN`, `openedAt` ghi nhận thời gian thực). |
| **10** | Có thể đóng phiên | **PASS** | Đã kiểm thử `POST /api/v1/attendance/sessions/1/close` ➔ Trả về `200 OK` (`status: CLOSED`, `closedAt` ghi nhận thời gian thực). |
| **11** | Trạng thái phiên được lưu thật trong PostgreSQL | **PASS** | Đã kiểm tra trực tiếp bảng `attendance_sessions` trong PostgreSQL. Dữ liệu đã được reset sạch sẽ để người dùng tự tay thao tác trực tiếp trên giao diện. |

---

## 3. HƯỚNG DẪN KIỂM THỬ TRỰC TIẾP TRÊN GIAO DIỆN WEB

Người dùng có thể đăng nhập và trải nghiệm toàn bộ quy trình tại các URL sau:

### 3.1. Dành cho Giảng viên (`lecturer_test`):
1. **Đăng nhập:** Truy cập [http://localhost/login](http://localhost/login)
   - Tên đăng nhập: `lecturer_test`
   - Mật khẩu: *(Mật khẩu bạn đã thiết lập khi tạo tài khoản)*
2. **Quản lý Phiên điểm danh:** Truy cập [http://localhost/lecturer/attendance/sessions](http://localhost/lecturer/attendance/sessions) (hoặc qua menu bên trái).
3. **Thao tác tạo phiên:**
   - Nhấn nút **"Khởi tạo phiên điểm danh"** (màu xanh dương).
   - Trong dropdown chọn buổi học, chọn:  
     `IT301 - A301 | 2026-10-18 (Tiết 1: 07:00 - 09:25)`
   - Nhấn **"Tạo phiên điểm danh"** ➔ Phiên xuất hiện trên bảng với trạng thái **`Chưa mở (CREATED)`**.
4. **Mở phiên:**
   - Nhấn nút **"Mở phiên"** (màu xanh lá) tại dòng phiên vừa tạo ➔ Xác nhận modal ➔ Trạng thái chuyển sang **`Đang diễn ra (OPEN)`**.
5. **Theo dõi trạng thái:**
   - Xem thông tin sĩ số: 1 sinh viên (`SV2026001 - Nguyen Van Sinh Vien`).
6. **Đóng phiên:**
   - Nhấn nút **"Đóng phiên"** (màu đỏ) ➔ Xác nhận modal ➔ Trạng thái chuyển sang **`Đã kết thúc (CLOSED)`**.
7. **Xem lại phiên:**
   - Nhấn vào hàng của phiên hoặc nút **"Chi tiết"** để mở Slide-out Drawer xem lại thông tin tổng kết.

### 3.2. Dành cho Quản trị viên (`admin`):
- Xem Catalog Môn học: [http://localhost/admin/courses](http://localhost/admin/courses)
- Xem Học kỳ & Niên khóa: [http://localhost/admin/semesters](http://localhost/admin/semesters)
- Xem Lớp học phần: [http://localhost/admin/classes](http://localhost/admin/classes)
- Xem Thời khóa biểu: [http://localhost/admin/timetable](http://localhost/admin/timetable)
- Quản lý / Giám sát toàn bộ Phiên điểm danh: [http://localhost/admin/attendance/sessions](http://localhost/admin/attendance/sessions)
