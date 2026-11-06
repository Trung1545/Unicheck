# FPT UNIVERSITY TO UNICHECK SCHEMA MAPPING SPECIFICATION

> **Dự án**: UniCheck – Smart Multi-Platform Attendance System  
> **Tài liệu**: Quy chuẩn Ánh xạ Dữ liệu FPT sang Cơ sở Dữ liệu UniCheck  
> **Phiên bản**: 1.0.0  
> **Ngày lập**: 29/10/2026  
> **Áp dụng cho**: Flyway Migration V1..V7 (PostgreSQL 15+)  

---

## 1. NGUYÊN TẮC ÁNH XẠ (MAPPING PRINCIPLES)

1. **Tuân thủ toàn vẹn Schema gốc**: Không thêm cột, không đổi kiểu dữ liệu, không xóa ràng buộc (constraints) sẵn có trong database UniCheck.
2. **Khóa tự tăng & Quan hệ khóa ngoại**: Mọi bảng phụ thuộc (dependent tables) phải được chèn sau bảng danh mục gốc và tham chiếu chính xác khóa ngoại (`id` hoặc `class_name`).
3. **Chuẩn hóa chuỗi và định danh (Formatting)**:
   - Mã môn học FPT: Viết hoa toàn bộ không dấu (ví dụ: `PRF192`, `PRO192`, `CSD201`, `SWP391`).
   - Mã học kỳ FPT: Viết hoa không dấu (ví dụ: `FALL2026`, `SPRING2026`, `SUMMER2026`).
   - Mã phòng học: Chuẩn Campus Hòa Lạc (ví dụ: `AL-L201`, `BE-102`, `DE-304`).
   - Email người dùng: Định dạng `@fpt.edu.vn` cho cả sinh viên và giảng viên.
   - Vai trò (Role): Khớp chính xác với enum UniCheck (`ADMIN`, `LECTURER`, `STUDENT`).

---

## 2. CHI TIẾT ÁNH XẠ TỪNG THỰC THỂ (ENTITY MAPPINGS)

### 2.1. Ngành & Chuyên ngành đào tạo (`majors` & `specializations`)

#### Bảng `majors`
| Trường FPT | Cột UniCheck | Kiểu dữ liệu | Quy tắc ánh xạ / Dữ liệu mẫu |
|:---|:---|:---|:---|
| Mã ngành đào tạo | `code` | `VARCHAR(20)` | `7480201` (CNTT), `7340101` (QTKD), `7320106` (CNTT) |
| Tên ngành đào tạo | `name` | `VARCHAR(200)` | "Công nghệ thông tin", "Quản trị kinh doanh" |
| Mô tả ngành | `description` | `TEXT` | Nội dung giới thiệu từ trang web tuyển sinh |
| Thời gian đào tạo | `program_duration` | `VARCHAR(50)` | "4 năm (9 học kỳ chính khóa)" |
| Trạng thái | `status` | `VARCHAR(20)` | `'ACTIVE'` |

#### Bảng `specializations`
| Trường FPT | Cột UniCheck | Kiểu dữ liệu | Quy tắc ánh xạ / Dữ liệu mẫu |
|:---|:---|:---|:---|
| Mã chuyên ngành | `code` | `VARCHAR(20)` | `SE`, `AI`, `IA`, `IS`, `GD`, `MKT`, `IB` |
| Tên chuyên ngành | `name` | `VARCHAR(200)` | "Kỹ thuật phần mềm", "Trí tuệ nhân tạo", "An toàn thông tin" |
| Mã ngành trực thuộc | `major_id` | `BIGINT` | Khóa ngoại trỏ đến `majors.id` |
| Trạng thái | `status` | `VARCHAR(20)` | `'ACTIVE'` |

---

### 2.2. Môn học & Tiên quyết (`courses` & `course_prerequisites`)

#### Bảng `courses`
| Trường FPT | Cột UniCheck | Kiểu dữ liệu | Quy tắc ánh xạ / Dữ liệu mẫu |
|:---|:---|:---|:---|
| Subject Code (Mã môn) | `code` | `VARCHAR(20)` | Unique, ví dụ: `PRF192`, `PRO192`, `CSD201`, `DBI202`, `SWP391` |
| Subject Name (Tên môn) | `name` | `VARCHAR(200)` | "Programming Fundamentals", "Object-Oriented Programming" |
| Mô tả đề cương môn | `description` | `TEXT` | Tóm tắt mục tiêu môn học từ Syllabus FPT |
| Số tín chỉ (Credits) | `credits` | `INT` | Thông thường `3` tín chỉ (hoặc `4` cho đồ án/thực tập) |
| Tổng số slot (Slots) | `number_of_slots` | `INT` | 3 tín chỉ = `30` slots (mỗi slot 90 phút) |
| Tính vào điểm GPA | `is_calculated_in_gpa` | `BOOLEAN` | `TRUE` (các môn Giáo dục thể chất, Tiếng Anh chuẩn bị = `FALSE`) |
| Trạng thái | `status` | `VARCHAR(20)` | `'ACTIVE'` |

#### Bảng `course_prerequisites`
| Trường FPT | Cột UniCheck | Kiểu dữ liệu | Quy tắc ánh xạ |
|:---|:---|:---|:---|
| Môn học yêu cầu | `course_id` | `BIGINT` | ID của môn sau (ví dụ `PRO192`) |
| Môn học tiên quyết | `prerequisite_id` | `BIGINT` | ID của môn trước (ví dụ `PRF192` là tiên quyết của `PRO192`) |

---

### 2.3. Học kỳ & Cấu hình Slot (`semesters`, `semester_configs`, `slot_types`)

#### Bảng `semesters`
| Trường FPT | Cột UniCheck | Kiểu dữ liệu | Quy tắc ánh xạ / Dữ liệu mẫu |
|:---|:---|:---|:---|
| Semester Code | `code` | `VARCHAR(20)` | `FALL2026`, `SPRING2026`, `SUMMER2026` |
| Semester Name | `name` | `VARCHAR(100)` | "Học kỳ Fall 2026", "Học kỳ Spring 2026" |
| Ngày bắt đầu kỳ | `start_date` | `DATE` | `2026-09-07` (Kỳ Fall thường bắt đầu đầu tháng 9) |
| Ngày kết thúc kỳ | `end_date` | `DATE` | `2026-12-25` (Kéo dài khoảng 15-16 tuần) |
| Trạng thái | `status` | `VARCHAR(20)` | `'ACTIVE'` |

#### Bảng `slot_types` (Chuẩn 6 Slot/ngày của Đại học FPT)
| Slot FPT | Cột `name` | Cột `slot_index` | Cột `start_time` | Cột `end_time` | Cột `duration` |
|:---:|:---|:---:|:---:|:---:|:---:|
| **Slot 1** | "Slot 1 (07:30 - 09:00)" | 1 | `07:30:00` | `09:00:00` | "90m" |
| **Slot 2** | "Slot 2 (09:10 - 10:40)" | 2 | `09:10:00` | `10:40:00` | "90m" |
| **Slot 3** | "Slot 3 (10:50 - 12:20)" | 3 | `10:50:00` | `12:20:00` | "90m" |
| **Slot 4** | "Slot 4 (12:50 - 14:20)" | 4 | `12:50:00` | `14:20:00` | "90m" |
| **Slot 5** | "Slot 5 (14:30 - 16:00)" | 5 | `14:30:00` | `16:00:00` | "90m" |
| **Slot 6** | "Slot 6 (16:10 - 17:40)" | 6 | `16:10:00` | `17:40:00` | "90m" |

---

### 2.4. Giảng đường & Cơ sở vật chất (`rooms`, `wifi_access_points`, `room_wifi_access_points`)

#### Bảng `rooms`
| Trường FPT | Cột UniCheck | Kiểu dữ liệu | Quy tắc ánh xạ / Dữ liệu mẫu |
|:---|:---|:---|:---|
| Mã phòng học FPT | `code` | `VARCHAR(20)` | `AL-L201`, `AL-L302`, `BE-102`, `BE-205`, `DE-101` |
| Tên phòng học | `name` | `VARCHAR(100)` | "Phòng lý thuyết 201 - Tòa Alpha", "Lab Máy tính 102 - Tòa Beta" |
| Sức chứa chuẩn FPT | `capacity` | `INT` | Lớp chuẩn FPT từ 30 đến 35 sinh viên (gán `35`) |
| Tòa nhà (Building) | `building` | `VARCHAR(50)` | "Alpha", "Beta", "Gamma", "Delta" (Campus Hòa Lạc) |
| Tầng (Floor) | `floor` | `INT` | 1, 2, 3, 4 |
| Loại phòng | `type` | `VARCHAR(20)` | `'THEORY'` (Lý thuyết) hoặc `'LAB'` (Phòng thực hành máy tính) |
| Trạng thái | `status` | `VARCHAR(20)` | `'AVAILABLE'` |

#### Bảng `wifi_access_points` & `room_wifi_access_points`
- SSID: `FU-Staff` hoặc `FU-Student`.
- BSSID: Địa chỉ MAC chuẩn (ví dụ: `00:1A:2B:3C:4D:01`).
- Liên kết phòng: Gán mỗi phòng 1 Wi-Fi AP chính (`is_primary = TRUE`, `signal_strength = -55`).

---

### 2.5. Người dùng, Giảng viên & Sinh viên (`users`, `student_profiles`, `lecturer_profiles`)

#### Bảng `users` (Tất cả tài khoản đều là Synthetic Mock an toàn)
| Đối tượng | Cột `code` | Cột `username` | Cột `email` | Cột `role` | Cột `status` | Cột `face_data_status` |
|:---|:---|:---|:---|:---|:---|:---|
| **Admin** | `ADM001` | `admin` | `admin@unicheck.edu.vn` | `ADMIN` | `ACTIVE` | `NOT_REGISTERED` |
| **Giảng viên** | `DungLNT` | `gv_dunglnt` | `dunglnt@fpt.edu.vn` | `LECTURER` | `ACTIVE` | `NOT_REGISTERED` |
| **Giảng viên** | `SonNT` | `gv_sonnt` | `sonnt@fpt.edu.vn` | `LECTURER` | `ACTIVE` | `NOT_REGISTERED` |
| **Sinh viên** | `HE180001` | `sv_he180001` | `he180001@fpt.edu.vn` | `STUDENT` | `ACTIVE` | `REGISTERED` |
| **Sinh viên** | `HE180002` | `sv_he180002` | `he180002@fpt.edu.vn` | `STUDENT` | `ACTIVE` | `NOT_REGISTERED` |

*Ghi chú*: Mật khẩu mặc định toàn hệ thống thử nghiệm được mã hóa BCrypt của `Password@123`.

#### Bảng `student_profiles`
- `course`: Niên khóa, ví dụ `K18`, `K19`.
- `gpa`: Điểm trung bình mẫu (ví dụ: `3.25`, `3.60`).
- `major_id`: Trỏ tới ngành CNTT.
- `specialization_id`: Trỏ tới Kỹ thuật phần mềm (SE) hoặc AI.

#### Bảng `lecturer_profiles`
- `department`: "Bộ môn Kỹ thuật phần mềm" hoặc "Bộ môn Khoa học máy tính".
- `expertise`: "Java Web, Microservices, Cloud Computing" / "Machine Learning & AI".

---

### 2.6. Lớp học phần & Ghi danh (`class_sections` & `enrollments`)

#### Bảng `class_sections`
| Trường FPT | Cột UniCheck | Kiểu dữ liệu | Quy tắc ánh xạ / Dữ liệu mẫu |
|:---|:---|:---|:---|
| Tên lớp học phần | `class_name` | `VARCHAR(50)` | Primary Key. Ví dụ: `SE1801-PRJ301`, `SE1802-CSD201`, `AI1801-AIL101` |
| Môn học | `course_id` | `BIGINT` | Khóa ngoại trỏ đến `courses.id` |
| Học kỳ | `semester_id` | `BIGINT` | Khóa ngoại trỏ đến `semesters.id` (ví dụ kỳ Fall 2026) |
| Giảng viên phụ trách | `lecturer_id` | `BIGINT` | Khóa ngoại trỏ đến `users.id` của giảng viên |
| Tổng số slot của môn | `number_of_slots` | `INT` | 30 slots |
| Sĩ số tối đa | `max_students` | `INT` | 30 sinh viên |
| Sĩ số hiện tại | `current_enrollment` | `INT` | Số sinh viên thực tế đã ghi danh trong `enrollments` |
| Trạng thái lớp | `status` | `VARCHAR(20)` | `'OPEN'` hoặc `'IN_PROGRESS'` |

#### Bảng `enrollments`
- `class_name`: Tên lớp học phần.
- `student_code`: Mã số sinh viên (ví dụ: `HE180001`).
- `student_id`: Khóa ngoại trỏ tới `users.id`.
- `status`: `'ENROLLED'`.
- *Ràng buộc chống trùng*: `idx_enrollments_class_student_unique (class_name, student_id)`.

---

### 2.7. Lịch học & Điểm danh (`timetable_slots`, `attendance_sessions`, `student_attendances`)

#### Bảng `timetable_slots`
- `class_name`: Khóa ngoại trỏ tới `class_sections`.
- `room_id`: Khóa ngoại trỏ tới `rooms.id`.
- `slot_type_id`: Khóa ngoại trỏ tới `slot_types.id`.
- `date`: Ngày diễn ra buổi học (tuân thủ Thứ trong tuần).
- `day_of_week`: 1 (Thứ Hai) đến 6 (Thứ Bảy).
- `slot_number`: 1 đến 6.
- `status`: `'SCHEDULED'`, `'IN_PROGRESS'`, hoặc `'COMPLETED'`.

#### Bảng `attendance_sessions`
- `timetable_slot_id`: Khóa ngoại duy nhất 1-1 với `timetable_slots.id`.
- `lecturer_id`: Giảng viên mở phiên điểm danh.
- `opened_at`: Thời điểm mở phiên (Timestamp).
- `closed_at`: Thời điểm đóng phiên.
- `status`: `'CREATED'`, `'OPEN'`, hoặc `'CLOSED'`.

#### Bảng `student_attendances`
- `session_id`: Khóa ngoại trỏ tới `attendance_sessions.id`.
- `student_id`: Khóa ngoại trỏ tới `users.id`.
- `status`: `'PRESENT'`, `'ABSENT'`, hoặc `'LATE'`.
- `method`: `'FACE_RECOGNITION'`, `'DYNAMIC_QR'`, hoặc `'MANUAL'`.
- `face_confidence`: Giá trị cosine similarity giả lập (ví dụ: `0.85` đến `0.94` khi nhận diện thành công).
- `check_in_time`: Timestamp thời điểm điểm danh.
