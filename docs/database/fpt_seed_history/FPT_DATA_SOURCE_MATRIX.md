# FPT UNIVERSITY DATA SOURCE MATRIX & FEASIBILITY AUDIT

> **Dự án**: UniCheck – Smart Multi-Platform Attendance System  
> **Tài liệu**: Ma trận nguồn dữ liệu học vụ Đại học FPT & Đánh giá tính khả thi thu thập dữ liệu  
> **Phiên bản**: 1.0.0  
> **Ngày lập**: 29/10/2026  
> **Người thực hiện**: Senior Data Engineer & Database Architect  

---

## 1. TỔNG QUAN HỆ THỐNG NGUỒN DỮ LIỆU ĐẠI HỌC FPT

Hệ sinh thái thông tin học vụ và đào tạo của Trường Đại học FPT (FPT University - FPTU) bao gồm hai nhóm cổng thông tin cốt lõi:
1. **Cổng thông tin đào tạo & tuyển sinh công khai**: `https://daihoc.fpt.edu.vn/` và các trang vệ tinh của 5 campus (Hà Nội, TP.HCM, Đà Nẵng, Cần Thơ, Quy Nhơn).
2. **Cổng quản lý đào tạo & học vụ nội bộ (FAP - FPT Academic Portal)**: `https://fap.fpt.edu.vn/` (hệ thống phục vụ công tác tổ chức đào tạo, thời khóa biểu, điểm danh, chấm điểm, sinh viên).

---

## 2. PHÂN LOẠI CẤP ĐỘ TRUY CẬP VÀ PHÁP LÝ (ACCESS CLASSIFICATION)

Để đảm bảo tuân thủ nghiêm ngặt **Luật An ninh mạng Việt Nam 2018**, **Nghị định 13/2023/NĐ-CP về Bảo vệ dữ liệu cá nhân**, cùng quy chế bảo mật thông tin nội bộ của FPT Education, toàn bộ dữ liệu được phân định thành 4 nhóm:

- **Nhóm A – Dữ liệu công khai (Publicly Available)**: Dữ liệu công bố rộng rãi trên Internet (website chính thức, thông tin tuyển sinh, khung chương trình đào tạo tổng quát, danh mục ngành, cơ sở vật chất). Cho phép thu thập tự động có kiểm soát (Rate limiting, tôn trọng `robots.txt`).
- **Nhóm B – Dữ liệu giới hạn / Cần xác thực (Restricted / Authenticated)**: Dữ liệu nằm sau cổng đăng nhập Google OAuth / FeID của cán bộ, giảng viên, sinh viên trên FAP (thời khóa biểu cá nhân, báo cáo điểm danh, danh sách lớp). **Tuyệt đối không sử dụng bot tự động đăng nhập trái phép, không bypass xác thực hoặc thu thập chéo tài khoản**.
- **Nhóm C – Dữ liệu nhập từ file được ủy quyền (Authorized File Import)**: File mẫu xuất ra từ FAP (Excel/CSV thời khóa biểu, danh sách lớp) do chính giảng viên hoặc cán bộ quản trị học vụ có thẩm quyền trích xuất và cung cấp cho mục đích thử nghiệm hệ thống.
- **Nhóm D – Dữ liệu cấm thu thập (Forbidden / Prohibited)**: Dữ liệu định danh cá nhân (PII - Full name thật kèm số CCCD, số điện thoại riêng, địa chỉ, tài khoản ngân hàng, thông tin gia đình), dữ liệu điểm số cá nhân, dữ liệu sinh trắc học (ảnh/vector khuôn mặt của sinh viên thật ngoài đời). **Bắt buộc sử dụng 100% dữ liệu giả lập (SYNTHETIC MOCK DATA) cho nhóm này**.

---

## 3. MA TRẬN NGUỒN DỮ LIỆU CHI TIẾT (DATA SOURCE MATRIX)

| STT | Thực thể dữ liệu (Entity) | Cấp độ | Nguồn dữ liệu (Source URL / Origin) | Định dạng | Tần suất cập nhật | Tính khả thi thu thập (Feasibility) | Phương án xử lý cho UniCheck |
|:---:|:---|:---:|:---|:---:|:---:|:---:|:---|
| **1** | **Khối ngành & Ngành đào tạo** | Nhóm A | `https://daihoc.fpt.edu.vn/chuong-trinh-dao-tao/` | HTML / Web | Theo năm tuyển sinh | **Rất cao (100%)** | Thu thập tự động qua Scraper |
| **2** | **Chuyên ngành (Specializations)** | Nhóm A | `https://daihoc.fpt.edu.vn/chuyen-nganh/*` | HTML / Web | Theo năm tuyển sinh | **Rất cao (100%)** | Thu thập tự động qua Scraper |
| **3** | **Danh mục Môn học (Course Catalog)** | Nhóm A/C | Trang chuyên ngành FPTU / Syllabus chính thức (`CSD201`, `PRF192`, `PRO192`, `SWP391`...) | HTML / PDF / Excel | Hàng kỳ | **Cao (90%)** | Thu thập từ web + File syllabus chuẩn |
| **4** | **Số tín chỉ & Tiên quyết (Prerequisites)** | Nhóm A/C | Sổ tay sinh viên / Quy chế đào tạo FPTU | PDF / Docx | Hàng năm | **Cao (85%)** | Bóc tách từ tài liệu học vụ công khai |
| **5** | **Khung học kỳ (Semesters & Trimesters)** | Nhóm A | Lịch học vụ năm học (Spring, Summer, Fall) | HTML / Thông báo | 3 kỳ / năm | **Rất cao (100%)** | Trích xuất chuẩn lịch năm học 2026 |
| **6** | **Khung giờ học (Slot Types & Periods)** | Nhóm A/B | Quy định 6 slot/ngày của FPTU (Slot 1..6: 07:30 - 17:40) | Văn bản học vụ | Cố định | **Rất cao (100%)** | Chuẩn hóa theo quy định FPTU |
| **7** | **Cơ sở & Giảng đường (Campuses & Rooms)** | Nhóm A/B | Danh mục phòng học Hòa Lạc (`AL-Lxxx`, `BE-xxx`, `DE-xxx`), HCM, ĐN | Website / FAP | Ổn định | **Cao (90%)** | Thu thập danh mục tòa nhà + tạo danh mục phòng chuẩn FPT |
| **8** | **Wi-Fi Access Points & BSSID** | Nhóm B/D | Hệ thống mạng hạ tầng trường học (`FU-Staff`, `FU-Student`) | Đo đạc thực tế / Network Config | Ổn định | **Trung bình (Giả lập)** | Tạo danh mục Wi-Fi AP chuẩn hóa gắn với phòng học |
| **9** | **Giảng viên (Lecturers)** | Nhóm B/D | Danh bạ nội bộ FAP / Bộ môn | ASPX (Authenticated) | Thường xuyên | **Không thu thập thật (PII)** | Sinh tài khoản giảng viên giả lập (`gv_dunglnt@fpt.edu.vn`) |
| **10** | **Sinh viên (Students)** | Nhóm B/D | Dữ liệu sinh viên trên FAP | ASPX (Authenticated) | Hàng kỳ | **Không thu thập thật (PII)** | Sinh sinh viên giả lập (`sv_he180001@fpt.edu.vn`, K18/K19) |
| **11** | **Lớp học phần (Class Sections)** | Nhóm B/C | `ScheduleOfWeek.aspx` / FAP Export | ASPX / Excel | Hàng kỳ | **Khả thi qua file import** | Hỗ trợ nạp từ Excel FAP hoặc sinh dữ liệu lớp chuẩn FPT (`SE1801-PRJ301`) |
| **12** | **Ghi danh (Enrollments)** | Nhóm B/C | Danh sách điểm danh FAP | ASPX / Excel | Đầu mỗi kỳ | **Khả thi qua file import** | Nạp từ file danh sách lớp hoặc sinh ngẫu nhiên 25-30 SV/lớp |
| **13** | **Thời khóa biểu tuần (Weekly Timetable)** | Nhóm B/C | FAP `ScheduleOfWeek.aspx` | HTML Table / Excel | Hàng tuần | **Khả thi qua file import** | Parser đọc file Excel lịch học FAP + Sinh lịch học chuẩn 10-15 tuần |
| **14** | **Phiên & Bản ghi Điểm danh (Attendance)** | Nhóm B/D | `Report/Attendance.aspx` | Database nội bộ | Thời gian thực | **Không thu thập thật** | Sinh dữ liệu mô phỏng phiên điểm danh kèm lịch sử face/QR/manual |

---

## 4. ĐÁNH GIÁ CHI TIẾT TỪNG NGUỒN CÔNG KHAI

### 4.1. Nguồn `https://daihoc.fpt.edu.vn/`
- **Địa chỉ cụ thể**:
  - `https://daihoc.fpt.edu.vn/chuong-trinh-dao-tao/` (Tổng quan lộ trình 9 kỳ và các khối ngành).
  - `https://daihoc.fpt.edu.vn/nganh-hoc/cong-nghe-thong-tin/` (Ngành CNTT).
  - `https://daihoc.fpt.edu.vn/chuyen-nganh/ky-thuat-phan-mem/` (Chuyên ngành Kỹ thuật phần mềm - SE).
  - `https://daihoc.fpt.edu.vn/chuyen-nganh/tri-tue-nhan-tao/` (Chuyên ngành Trí tuệ nhân tạo - AI).
  - `https://daihoc.fpt.edu.vn/chuyen-nganh/an-toan-thong-tin/` (Chuyên ngành An toàn thông tin - IA).
  - `https://daihoc.fpt.edu.vn/chuyen-nganh/he-thong-thong-tin/` (Chuyên ngành Hệ thống thông tin - IS).
- **Khả năng khai thác**:
  - Cấu trúc HTML sử dụng WordPress hiện đại, nội dung mô tả chi tiết các giai đoạn: Giai đoạn nền tảng (Kỳ 1-5), Giai đoạn OJT (Kỳ 6), Giai đoạn chuyên sâu & Đồ án (Kỳ 7-9).
  - Hoàn toàn công khai, không chặn bot phổ thông nếu duy trì tần suất yêu cầu vừa phải (< 1 request / 2 giây).

### 4.2. Nguồn Cổng đào tạo FAP (`https://fap.fpt.edu.vn/`)
- **Đặc điểm kiến trúc**:
  - Nền tảng ASP.NET WebForms cổ điển (`ViewState`, `EventValidation`, form POST).
  - Có lớp tường lửa WAF / Cloudflare chặn các lệnh bot và curl cơ bản (trả mã 403 Forbidden).
  - Toàn bộ dữ liệu lớp học, thời khóa biểu, điểm danh đều nằm sau bước xác thực Google OAuth bằng tài khoản `@fpt.edu.vn` hoặc `@fe.edu.vn`.
- **Kết luận khả thi**:
  - **Không khả thi và không hợp lệ** nếu tiến hành tự động quét (crawling) trực tiếp vào FAP.
  - **Hoàn toàn khả thi và an toàn tuyệt đối** khi triển khai cơ chế **File Adapter / Importer**: Hỗ trợ người dùng có quyền (Admin/Giáo vụ) tải file Excel mẫu thời khóa biểu xuất từ FAP và đưa vào công cụ nhập liệu UniCheck.

---

## 5. KẾT LUẬN & ĐỀ XUẤT HƯỚNG TRIỂN KHAI

1. **Giai đoạn 1 (Thu thập công khai)**: Thu thập toàn bộ danh mục Ngành, Chuyên ngành, Môn học, Tín chỉ, Cấu trúc kỳ học từ `daihoc.fpt.edu.vn` bằng Python Scraper hợp pháp có rate-limiting.
2. **Giai đoạn 2 (Nhập khẩu học vụ FAP)**: Xây dựng module đọc file Excel / CSV theo đúng định dạng mẫu FAP xuất ra (`ScheduleOfWeek_Export.xlsx`).
3. **Giai đoạn 3 (Giả lập toàn diện - Synthetic Generator)**: Sinh bộ dữ liệu mẫu đầy đủ 100% bao gồm Giảng viên, Sinh viên, Phòng học Hòa Lạc, Lịch học Fall 2026 và các phiên điểm danh để kiểm thử toàn diện các luồng Web, Mobile, AI Service của UniCheck mà không xâm phạm thông tin cá nhân của bất kỳ ai.
