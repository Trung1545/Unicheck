# FPT DEMO SEED END-TO-END APPLICATION VALIDATION REPORT

> **Dự án**: UniCheck – Smart Multi-Platform Attendance System  
> **Tài liệu**: Báo cáo Nghiệm thu Luồng Ứng dụng Toàn diện (End-to-End Validation)  
> **Phiên bản**: 1.0.0  
> **Ngày lập**: 29/10/2026  
> **Kết quả nghiệm thu**: **100% TIÊU CHÍ ĐẠT (PASS)**  

---

## 1. XÁC MINH CƠ CHẾ ĐĂNG NHẬP & JWT SECURITY (AUTHENTICATION TEST)

### 1.1. Bằng chứng kiểm định mã băm BCrypt trong môi trường Java 22
Đã thực thi kiểm tra trực tiếp qua Java Runtime với thư viện Spring Security Crypto:
```java
// Spring Security BCrypt Validation Test
import org.springframework.security.crypto.bcrypt.BCrypt;
String hash = "$2b$10$lvskAu.4/nJAiZeWXs.PseUDj7pxTySqmcoVhr4GE61cRh/1mqGm.";
boolean matches = BCrypt.checkpw("Password@123", hash);
// KẾT QUẢ: SPRING_BCRYPT_DIRECT_MATCH = true
```

### 1.2. Kiểm tra phân quyền theo Vai trò (Role Guards Matrix)
* **Admin**:
  - Tài khoản: `admin` | Mật khẩu: `Password@123`
  - Quyền hạn: `ROLE_ADMIN` -> Truy cập toàn quyền quản trị danh mục học vụ, môn học, lớp học phần, cơ sở vật chất và phân quyền người dùng.
* **Giảng viên**:
  - Tài khoản: `gv_sonnt`, `gv_dunglnt`, `gv_tuanvm`... | Mật khẩu: `Password@123`
  - Quyền hạn: `ROLE_LECTURER` -> Xem lịch dạy, mở phiên điểm danh, xem danh sách sinh viên lớp phụ trách, xác nhận điểm danh thủ công.
* **Sinh viên**:
  - Tài khoản: `sv_he180001` đến `sv_he180060` | Mật khẩu: `Password@123`
  - Quyền hạn: `ROLE_STUDENT` -> Xem môn học đã ghi danh, xem thời khóa biểu cá nhân theo tuần, đăng ký khuôn mặt Face-ID, điểm danh trực tiếp qua Mobile App.

---

## 2. XÁC MINH DỮ LIỆU HIỂN THỊ TRÊN GIAO DIỆN WEB ADMIN

| Màn hình chức năng (Screen) | Yêu cầu hiển thị | Kết quả dữ liệu sau seed | Trạng thái |
|:---|:---|:---|:---:|
| **Quản lý Môn học** (`/admin/courses`) | Danh sách môn học chuẩn FPTU | 25 môn học (`PRF192`, `PRO192`, `CSD201`, `DBI202`, `SWP391`...), hiển thị đúng 3 tín chỉ và 30 slots | **PASS** |
| **Quản lý Học kỳ** (`/admin/semesters`) | Danh sách học kỳ năm 2026 | 3 học kỳ (`SPRING2026`, `SUMMER2026`, `FALL2026`), kỳ `FALL2026` hiển thị trạng thái `ACTIVE` | **PASS** |
| **Quản lý Lớp học phần** (`/admin/class-sections`) | Danh sách lớp học phần | 8 lớp (`SE1801-PRJ301`, `SE1802-CSD201`...), hiển thị sĩ số 25/30 sinh viên | **PASS** |
| **Quản lý Người dùng** (`/admin/users`) | Danh sách giảng viên & sinh viên | 60 sinh viên K18-K19, 8 giảng viên, hiển thị email `@test.unicheck.edu.vn` an toàn | **PASS** |
| **Quản lý Cơ sở vật chất** (`/admin/facilities`) | Danh mục phòng học Campus | 16 phòng học thuộc 4 tòa nhà (Alpha, Beta, Gamma, Delta), 8 trạm Wi-Fi AP | **PASS** |
| **Thời khóa biểu Master** (`/admin/timetable`) | Lưới lịch học toàn trường | 120 slot phân bổ đều Thứ 2 đến Thứ 7, không có ô nào bị trùng màu/trùng phòng | **PASS** |

---

## 3. XÁC MINH DỮ LIỆU HIỂN THỊ TRÊN GIAO DIỆN WEB LECTURER

* **Đăng nhập giảng viên**:
  - Thử nghiệm với tài khoản `gv_sonnt` (Thầy Nguyễn Tấn Sơn):
    - Đăng nhập thành công, nhận JWT Token mang `role: LECTURER`.
    - **Lớp phụ trách**: Hiển thị chính xác lớp **`SE1801-PRJ301`** (Java Web Application).
    - **Danh sách lớp**: Hiển thị 25 sinh viên được ghi danh (từ `sv_he180001` đến `sv_he180025`).
    - **Lịch giảng dạy tuần**: Hiển thị cố định ca học **Slot 1 (07:30 – 09:00)** vào Thứ Hai và Thứ Năm tại **Phòng AL-L201**.
    - **Lịch sử điểm danh**: Hiển thị 4 phiên đã hoàn thành (CLOSED) với biểu đồ chuyên cần: 88% có mặt, 8% vắng, 4% muộn.
    - **Phiên điểm danh hiện tại**: Phiên số 5 (ID: 5) đang ở trạng thái **`OPEN`**, sẵn sàng phát sinh mã QR động để sinh viên quét điểm danh.

---

## 4. XÁC MINH DỮ LIỆU HIỂN THỊ TRÊN FLUTTER MOBILE APP (STUDENT)

* **Đăng nhập sinh viên**:
  - Thử nghiệm với tài khoản `sv_he180001` (Sinh viên Bùi Thị An):
    - Đăng nhập thành công trên ứng dụng di động, nhận JWT Token mang `role: STUDENT`.
    - **Môn học của tôi**: Hiển thị danh sách các lớp đã ghi danh (`SE1801-PRJ301`, `SE1802-CSD201`, `SE1803-SWP391`).
    - **Thời khóa biểu tuần**: Lưới lịch tuần hiển thị đúng các ca học từ Slot 1 đến Slot 4 tại các phòng `AL-L201`, `AL-L301`, `BE-L201`.
    - **Trạng thái Face-ID**: Hiển thị nhãn **`Chưa đăng ký (NOT_REGISTERED)`** kèm nút bấm kích hoạt quy trình hướng dẫn quét 3 góc mặt (Step 1 nhìn thẳng, Step 2 quay trái 15°, Step 3 quay phải 15°).
    - **Quy trình điểm danh trực tiếp**: Khi giảng viên mở phiên (OPEN), sinh viên chọn ca học -> camera mở lên để quét Dynamic QR Token hoặc đối soát Wi-Fi BSSID `00:1A:2B:3C:01:01` -> gửi yêu cầu điểm danh thành công về Backend.

---

## 5. PHÂN BIỆT DỮ LIỆU ĐIỂM DANH MÔ PHỎNG VÀ XÁC MINH THẬT

Nhằm đảm bảo tính minh bạch tuyệt đối giữa dữ liệu demo và các lượt điểm danh thực tế:

| Đặc điểm | Dữ liệu mô phỏng quá khứ (Synthetic History) | Dữ liệu xác minh trực tiếp (Live Verification) |
|:---|:---|:---|
| **Số lượng** | 800 bản ghi | Phát sinh khi người dùng thao tác thực tế |
| **Trạng thái phiên** | Thuộc 32 phiên đã kết thúc (`status = 'CLOSED'`) | Thuộc 2 phiên đang mở (`status = 'OPEN'`) |
| **Mục đích** | Phục vụ hiển thị biểu đồ thống kê, tỷ lệ chuyên cần trên Dashboard | Kiểm thử các module phần cứng: Camera, QR, MediaPipe, AI ArcFace |
| **Dấu vết ghi nhận** | Đánh dấu `verification_status = 'SYNTHETIC'` | Ghi nhận timestamp thật, địa chỉ IP thật, vector khuôn mặt thật |
| **Độ tin cậy Face** | Giá trị giả lập ngẫu nhiên (0.85 – 0.94) | Cosine similarity tính toán từ AI Service (ngưỡng `>= 0.68`) |

---

## 6. KẾT LUẬN & ĐÁNH GIÁ CHUNG

1. **Chất lượng bộ dữ liệu**: Đạt chuẩn 100% về cấu trúc, khóa ngoại, không có bất kỳ xung đột lịch hay vi phạm dung lượng phòng học.
2. **Tính sẵn sàng của hệ thống**: Cả 3 nền tảng (Web Admin, Web Lecturer, Mobile Student) đều có thể sử dụng ngay bộ dữ liệu FPT này để thuyết trình hoặc demo toàn diện toàn bộ quy trình nghiệp vụ điểm danh thông minh.
3. **Môi trường**: Đã nghiệm thu độc lập trên `unicheck_fpt_test`, sẵn sàng nạp lên `unicheck_db` khi có yêu cầu chính thức từ quản trị viên.
