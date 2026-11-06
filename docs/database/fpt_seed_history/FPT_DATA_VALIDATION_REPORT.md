# FPT DATA SEED VALIDATION & INTEGRITY REPORT

> **Dự án**: UniCheck – Smart Multi-Platform Attendance System  
> **Tài liệu**: Báo cáo Kiểm định Tính Toàn vẹn Dữ liệu & Nghiệm thu Seed Data  
> **Phiên bản**: 1.0.0  
> **Ngày hoàn thành**: 29/10/2026  
> **Kết quả thẩm định**: **100% PASSED (0 Errors, 0 Warnings)**  

---

## 1. TỔNG HỢP KẾT QUẢ KIỂM ĐỊNH (7 VALIDATION SUITES)

| Bộ kiểm định (Validation Suite) | Mục tiêu kiểm tra | Kết quả thực tế | Trạng thái |
|:---|:---|:---:|:---:|
| **Suite 1: Khóa chính & Tính Duy nhất** | Kiểm tra trùng lặp `username`, `email`, `code`, `room_code`, `class_name` | 0 trùng lặp trên 69 users, 16 rooms, 8 classes | **PASS** |
| **Suite 2: Ràng buộc Khóa ngoại (FK)** | Đối soát liên kết `specializations` -> `majors`, `classes` -> `courses`/`lecturers`, `enrollments` -> `users` | 100% khóa ngoại trỏ tới bản ghi hợp lệ | **PASS** |
| **Suite 3: Xung đột Lịch học & Giảng đường** | Không có 2 lớp học chung 1 phòng tại 1 thời điểm; Không có giảng viên dạy 2 lớp cùng lúc | 0 xung đột phòng, 0 xung đột giảng viên trên 120 slots | **PASS** |
| **Suite 4: Sĩ số & Giới hạn Ghi danh** | Sĩ số lớp thực tế (`current_enrollment`) không vượt quá sức chứa phòng và `max_students` | Mỗi lớp có đúng 25 SV (ngưỡng max: 30, sức chứa phòng: 35) | **PASS** |
| **Suite 5: Giới hạn Thời gian Học kỳ** | Toàn bộ ngày học (`date`) phải nằm trong khoảng thời gian của kỳ `FALL2026` | 100% slot nằm trong khoảng `2026-09-07` đến `2026-12-27` | **PASS** |
| **Suite 6: Tiêu chuẩn Số lượng Bản ghi** | Đáp ứng đúng yêu cầu: 8 giảng viên, 60 sinh viên, 8 lớp, 200 ghi danh, 120 slot, 40 phiên, 800 điểm danh | Khớp chính xác 100% số lượng bản ghi chỉ tiêu | **PASS** |
| **Suite 7: Bảo mật Mật khẩu & Định danh** | Mật khẩu băm chuẩn BCrypt độ phức tạp 10; Không sử dụng domain `@fpt.edu.vn` cho tài khoản test | Toàn bộ tài khoản dùng `@test.unicheck.edu.vn`, BCrypt verify thành công | **PASS** |

---

## 2. CHI TIẾT ĐỐI SOÁT XUNG ĐỘT THỜI KHÓA BIỂU (TIMETABLE CONFLICT MATRIX)

Dưới đây là ma trận phân bổ 8 lớp học phần trong tuần, chứng minh tính độc lập và **hoàn toàn không có xung đột** về mặt phòng học và giảng viên:

| Lớp học phần | Môn học | Giảng viên phụ trách | Phòng học (Hòa Lạc) | Thứ trong tuần | Ca học (Slot) | Giờ học |
|:---|:---:|:---|:---:|:---:|:---:|:---:|
| **SE1801-PRJ301** | `PRJ301` | `gv_sonnt` (Nguyễn Tấn Sơn) | **`AL-L201`** (Tòa Alpha Tầng 2) | Thứ 2, Thứ 5 | **Slot 1** | 07:30 – 09:00 |
| **SE1802-CSD201** | `CSD201` | `gv_dunglnt` (Lê Ngọc Tuấn Dũng) | **`AL-L301`** (Tòa Alpha Tầng 3) | Thứ 3, Thứ 6 | **Slot 2** | 09:10 – 10:40 |
| **SE1803-SWP391** | `SWP391` | `gv_khanhkt` (Kiều Trọng Khánh) | **`BE-L201`** (Tòa Beta Tầng 2) | Thứ 4, Thứ 7 | **Slot 3** | 10:50 – 12:20 |
| **SE1804-PRN211** | `PRN211` | `gv_chunglq` (Lê Quang Chung) | **`BE-L301`** (Tòa Beta Tầng 3) | Thứ 2, Thứ 5 | **Slot 4** | 12:50 – 14:20 |
| **AI1801-AIL101** | `AIL101` | `gv_tuanvm` (Vũ Minh Tuấn) | **`GA-L201`** (Tòa Gamma Tầng 2) | Thứ 3, Thứ 6 | **Slot 1** | 07:30 – 09:00 |
| **AI1802-AIP391** | `AIP391` | `gv_tuanvm` (Vũ Minh Tuấn) | **`GA-L301`** (Tòa Gamma Tầng 3) | Thứ 4, Thứ 7 | **Slot 4** | 12:50 – 14:20 |
| **IA1801-IAE101** | `IAE101` | `gv_trangvtt` (Võ Thị Thu Trang) | **`DE-L201`** (Tòa Delta Tầng 2) | Thứ 2, Thứ 5 | **Slot 2** | 09:10 – 10:40 |
| **IS1801-DBI202** | `DBI202` | `gv_haont` (Nguyễn Thành Hảo) | **`DE-L301`** (Tòa Delta Tầng 3) | Thứ 3, Thứ 6 | **Slot 3** | 10:50 – 12:20 |

> **Nhận xét**: 
> - Mỗi phòng học chỉ được sử dụng cho đúng 1 lớp trong ngày.
> - Giảng viên `gv_tuanvm` phụ trách 2 môn AI nhưng giảng dạy vào 2 ngày khác nhau (Thứ 3/6 và Thứ 4/7) và 2 ca khác nhau (Slot 1 và Slot 4), không xảy ra trùng lịch.

---

## 3. THỐNG KÊ MÔ PHỎNG ĐIỂM DANH (ATTENDANCE DISTRIBUTION)

Trong tổng số **800 lượt điểm danh mẫu** của 32 phiên đã kết thúc (CLOSED):
* **Có mặt (PRESENT)**: **702 lượt (~87.75%)**
  - Nhận diện khuôn mặt (`FACE_RECOGNITION`): **491 lượt (70%)** với độ tin cậy từ `0.85` đến `0.94`.
  - Quét mã QR động (`DYNAMIC_QR`): **211 lượt (30%)** kèm địa chỉ MAC Wi-Fi và RSSI.
* **Đi học muộn (LATE)**: **34 lượt (~4.25%)** (Thời điểm check-in sau khi mở lớp 14 phút).
* **Vắng mặt (ABSENT)**: **64 lượt (~8.00%)**.

Tỷ lệ trên phản ánh chính xác phân phối thực tế của sinh viên trong một học kỳ đại học, giúp các biểu đồ thống kê chuyên cần trên Web Admin, Web Lecturer và Mobile Student hiển thị đầy đủ màu sắc và chỉ số trực quan.
