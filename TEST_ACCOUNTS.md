# 🔑 Danh Sách Tài Khoản & Mật Khẩu Kiểm Thử Hệ Thống (UniCheck Test Accounts)

Tài liệu này tổng hợp toàn bộ danh sách tài khoản, mật khẩu và vai trò (Roles) đã được cấu hình sẵn trong hệ thống **UniCheck** để các thành viên trong nhóm tiện đăng nhập và kiểm thử tính năng trên **Web Admin/Lecturer** và **Mobile App Student**.

---

## ⚡ 1. Quy ước mật khẩu chung (Default Password)

Hầu hết tất cả các tài khoản thử nghiệm (Admin, Giảng viên, Sinh viên) đều sử dụng chung một mật khẩu chuẩn:

> 🔐 **Mật khẩu mặc định:** **`Password@123`**  
> *(Đối với các tài khoản test ban đầu: `admin` / `Admin@123`, `lecturer_test` / `Lecturer@123`, `student_test` / `Student@123`)*

---

## 🛠️ 2. Lệnh nạp dữ liệu mẫu (Nếu cơ sở dữ liệu mới khởi tạo chưa có dữ liệu)

Nếu thành viên mới cài đặt Docker lần đầu mà cơ sở dữ liệu chưa có người dùng, chỉ cần chạy **1 lệnh duy nhất** sau trong terminal tại thư mục gốc:

```bash
docker compose exec -T postgres psql -U unicheck_user -d unicheck_db < tools/fpt-data-collector/data/seeds/01_fpt_master_demo_seed.sql
```
*(Lệnh này an toàn, tự động bỏ qua nếu dữ liệu đã tồn tại, không làm mất dữ liệu cũ).*

---

## 👑 3. Tài khoản Quản trị viên (ADMIN)

Dùng để đăng nhập vào **Web Quản trị** để quản lý môn học, lớp học phần, phòng học, phân công giảng viên và giám sát tất cả các phiên điểm danh.

| Username | Mật khẩu | Quyền (Role) | Email | Chức năng kiểm thử chính |
| :--- | :--- | :---: | :--- | :--- |
| **`admin`** | `Password@123`<br>*(hoặc `Admin@123`)* | `ADMIN` | `admin@test.unicheck.edu.vn` | - Quản lý Học kỳ & Ngành học<br>- Quản lý Môn học (`/admin/courses`)<br>- Quản lý Lớp học phần (`/admin/classes`)<br>- Quản lý Thời khóa biểu (`/admin/timetable`)<br>- Giám sát tất cả các phiên điểm danh |

👉 **URL đăng nhập Web**: [http://localhost](http://localhost) hoặc [http://localhost:5173/login](http://localhost:5173/login)

---

## 👨‍🏫 4. Danh sách tài khoản Giảng viên (LECTURERS)

Dùng để đăng nhập vào **Web Giảng viên** để xem lịch dạy, tạo phiên điểm danh, mở phiên điểm danh hiển thị Dynamic QR Code và đóng phiên.

| Username | Mật khẩu | Họ và tên | Mã GV | Môn học phụ trách | Lớp giảng dạy mẫu |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **`gv_sonnt`** | `Password@123` | Nguyễn Tấn Sơn | `TEST_LEC_01` | **PRJ301** (Java Web Application) | `SE1801-PRJ301` |
| **`gv_dunglnt`** | `Password@123` | Lê Ngọc Tuấn Dũng | `TEST_LEC_02` | **CSD201** (Data Structures) | `SE1802-CSD201` |
| **`gv_khanhkt`** | `Password@123` | Kiều Trọng Khánh | `TEST_LEC_04` | **SWP391** (Software Project) | `SE1803-SWP391` |
| **`gv_chunglq`** | `Password@123` | Lê Quang Chung | `TEST_LEC_05` | **PRN211** (.NET Core) | `SE1804-PRN211` |
| **`gv_tuanvm`** | `Password@123` | Vũ Minh Tuấn | `TEST_LEC_03` | **AIL101** & **AIP391** (AI) | `AI1801-AIL101`, `AI1802` |
| **`gv_trangvtt`** | `Password@123` | Võ Thị Thu Trang | `TEST_LEC_06` | **IAE101** (Information Assurance) | `IA1801-IAE101` |
| **`gv_haont`** | `Password@123` | Nguyễn Thành Hảo | `TEST_LEC_08` | **DBI202** (Databases) | `IS1801-DBI202` |
| **`gv_namph`** | `Password@123` | Phạm Hữu Nam | `TEST_LEC_07` | **MKT101** (Kinh tế) | Lớp dự phòng |
| **`lecturer_test`** | `Lecturer@123`<br>*(hoặc `Password@123`)* | Giảng viên Kiểm thử | `GV_TEST_001` | **IT301** (Lập trình Web) | `IT301` |

---

## 🎓 5. Danh sách tài khoản Sinh viên (STUDENTS)

Dùng để đăng nhập vào **Flutter Mobile App** (hoặc Web) để:
1. Xem thời khóa biểu cá nhân.
2. Quét Dynamic QR Code trên màn hình của giảng viên.
3. Điểm danh nhận diện khuôn mặt (Face Recognition) & kiểm tra thực thể sống (Liveness Detection).
4. Xem lịch sử điểm danh cá nhân (Có mặt / Đi muộn / Vắng mặt).

| Username | Mật khẩu | Mã SV (RollNo) | Họ và tên | Chuyên ngành | Lớp đã ghi danh |
| :--- | :--- | :---: | :--- | :--- | :--- |
| **`student_test`** | `Student@123`<br>*(hoặc `Password@123`)* | `SV2026001` | Nguyen Van Sinh Vien | Kỹ thuật phần mềm | Lớp `IT301`<br>*(Đã đăng ký sẵn FaceID mẫu)* |
| **`sv_he180001`** | `Password@123` | `HE180001` | Bùi Thị An | K18 - Kỹ thuật phần mềm | `SE1801-PRJ301` |
| **`sv_he180002`** | `Password@123` | `HE180002` | Trần Bảo Long | K18 - Kỹ thuật phần mềm | `SE1801-PRJ301` |
| **`sv_he180003`** | `Password@123` | `HE180003` | Lê Hoàng Nam | K18 - Kỹ thuật phần mềm | `SE1801-PRJ301` |
| **`sv_he180021`** | `Password@123` | `HE180021` | Phạm Minh Tuấn | K18 - Kỹ thuật phần mềm | `SE1802-CSD201` |
| **`sv_he180031`** | `Password@123` | `HE180031` | Hoàng Thu Trang | K18 - Trí tuệ nhân tạo (AI) | `AI1801-AIL101` |
| **`sv_he180041`** | `Password@123` | `HE180041` | Đỗ Đức Hùng | K18 - An toàn thông tin (IA) | `IA1801-IAE101` |
| **`sv_he180051`** | `Password@123` | `HE180051` | Vũ Phương Anh | K18 - Hệ thống thông tin (IS)| `IS1801-DBI202` |

> 💡 **Mẹo:** Hệ thống có sẵn **60 sinh viên** với username theo định dạng từ **`sv_he180001`** đến **`sv_he180060`** (mã SV tương ứng từ `HE180001` đến `HE180060`), tất cả đều dùng chung mật khẩu **`Password@123`**.

---

## 🎯 6. Kịch bản kiểm thử mẫu nhanh (Quick Test Workflow)

Để kiểm thử nhanh toàn bộ luồng điểm danh trong nhóm:

1. **Bước 1 - Giảng viên tạo và mở phiên:**
   * Đăng nhập tài khoản `gv_sonnt` / `Password@123` trên trình duyệt.
   * Vào mục **Điểm danh (Attendance Sessions)** ➔ Chọn buổi học lớp `SE1801-PRJ301` ➔ Bấm **Tạo phiên điểm danh** ➔ Bấm **Mở phiên**.
   * Màn hình giảng viên sẽ hiện mã **Dynamic QR Code** tự động nhảy theo chu kỳ thời gian.

2. **Bước 2 - Sinh viên điểm danh:**
   * Mở ứng dụng **Flutter Mobile App**, đăng nhập tài khoản `sv_he180001` / `Password@123`.
   * Chọn chức năng **Điểm danh** ➔ Hướng camera quét Dynamic QR Code trên màn hình giảng viên.
   * Thực hiện nhận diện khuôn mặt & liveness theo chỉ dẫn trên màn hình điện thoại.

3. **Bước 3 - Xác nhận kết quả:**
   * Màn hình điện thoại báo điểm danh thành công.
   * Trên màn hình Web của Giảng viên (`gv_sonnt`), sinh viên `HE180001 - Bùi Thị An` sẽ lập tức chuyển trạng thái sang **Có mặt (PRESENT)** theo thời gian thực (qua WebSocket).
