# BẢNG KIỂM KÊ VÀ ĐỐI CHIẾU API (API INVENTORY & USAGE AUDIT)
**Mã tài liệu:** AUDIT-API-INVENTORY-2026  
**Ngày kiểm toán:** 15/10/2026  
**Nguồn đối chiếu:**
* Backend: [`AuthController.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/controller/AuthController.java), [`UserController.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/controller/UserController.java)
* Đặc tả: [`docs/api/openapi.yaml`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/docs/api/openapi.yaml), [`docs/api/auth_api_contract.md`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/docs/api/auth_api_contract.md)
* Web Client: [`frontend/src/api/auth.api.ts`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/api/auth.api.ts)
* Mobile Client: [`mobile/lib/feature/auth/services/auth_api_service.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/auth/services/auth_api_service.dart)
* AI Service: [`ai-service/app.py`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/ai-service/app.py)

---

## 1. DANH SÁCH ENDPOINT HIỆN CÓ PHÍA BACKEND

Tất cả các endpoint Backend hỗ trợ cấu chế kép: **Canonical Prefix** (`/api/v1/...`) và **Legacy Alias Prefix** (`/api/...`) thông qua bộ điều khiển `@RequestMapping({"/api/...", "/api/v1/..."})`.

### 1.1. Module Xác thực & Hồ sơ (Authentication & Self-Service)

| Phương thức | Endpoint Canonical | File Controller | Quyền yêu cầu | Trạng thái Backend | Sử dụng tại Web FE (`frontend/`) | Sử dụng tại Mobile (`mobile/`) |
| :---: | :--- | :--- | :--- | :---: | :---: | :---: |
| `POST` | `/api/v1/auth/login` | `AuthController:L20` | Công khai | `ACTIVE` | `loginApi` (`LoginPage.tsx`) | `AuthApiService.login` |
| `POST` | `/api/v1/auth/logout` | `AuthController:L27` | Bearer Token | `ACTIVE` | `logoutApi` (`Header.tsx`) | `AuthApiService.logout` |
| `POST` | `/api/v1/auth/refresh-token` | `AuthController:L33` | Công khai / DTO | `ACTIVE` | `refreshTokenApi` (`axios-instance.ts`) | `api_client.dart` (RTR Interceptor) |
| `GET` | `/api/v1/auth/me` | `AuthController:L39` | Bearer Token | `ACTIVE` | `getProfileApi` (`ProfilePage.tsx`) | `AuthApiService.getCurrentUser` |
| `GET` | `/api/v1/auth/profile` *(Alias)*| `AuthController:L39` | Bearer Token | `ACTIVE` | *(Dùng `/auth/me`)* | *(Dùng `/auth/me`)* |
| `PUT` | `/api/v1/auth/profile` | `AuthController:L45` | Bearer Token | `ACTIVE` | `updateProfileApi` (`ProfilePage.tsx`) | *Chưa dùng* |
| `POST` | `/api/v1/auth/change-password` | `AuthController:L51` | Bearer Token | `ACTIVE` | `changePasswordApi` (`ChangePasswordPage.tsx`) | *Chưa dùng* |
| `POST` | `/api/v1/auth/forgot-password` | `AuthController:L57` | Công khai | `ACTIVE` | `forgotPasswordApi` (`ForgotPasswordPage.tsx`, `VerifyOtpPage.tsx`) | *Chưa dùng* |
| `POST` | `/api/v1/auth/reset-password` | `AuthController:L64` | Công khai | `ACTIVE` | `resetPasswordApi` (`ResetPasswordPage.tsx`) | *Chưa dùng* |
| `GET` | `/api/v1/auth/test/admin` | `AuthController:L71` | `ROLE_ADMIN` | `ACTIVE` | *Dùng trong test* | *Dùng trong test* |
| `GET` | `/api/v1/auth/test/lecturer`| `AuthController:L77` | `ROLE_LECTURER` | `ACTIVE` | *Dùng trong test* | *Dùng trong test* |
| `GET` | `/api/v1/auth/test/student` | `AuthController:L83` | `ROLE_STUDENT` | `ACTIVE` | *Dùng trong test* | *Dùng trong test* |

### 1.2. Module Quản lý Người dùng (User Management - Dành cho ADMIN)

| Phương thức | Endpoint Canonical | File Controller | Quyền yêu cầu | Trạng thái Backend | Sử dụng tại Web FE (`frontend/`) | Sử dụng tại Mobile (`mobile/`) |
| :---: | :--- | :--- | :--- | :---: | :---: | :---: |
| `POST` | `/api/v1/users` | `UserController:L32` | `ROLE_ADMIN` | `ACTIVE` | *Chưa tích hợp (GĐ 4)* | *Chưa dùng* |
| `GET` | `/api/v1/users/{id}` | `UserController:L44` | `ROLE_ADMIN` | `ACTIVE` | *Chưa tích hợp (GĐ 4)* | *Chưa dùng* |
| `PUT` | `/api/v1/users/{id}` | `UserController:L54` | `ROLE_ADMIN` | `ACTIVE` | *Chưa tích hợp (GĐ 4)* | *Chưa dùng* |
| `DELETE`| `/api/v1/users/{id}` | `UserController:L66` | `ROLE_ADMIN` | `ACTIVE` | *Chưa tích hợp (GĐ 4)* | *Chưa dùng* |
| `GET` | `/api/v1/users` | `UserController:L76` | `ROLE_ADMIN` | `ACTIVE` | *Chưa tích hợp (GĐ 4)* | *Chưa dùng* |
| `GET` | `/api/v1/users/active` | `UserController:L90` | `ROLE_ADMIN` | `ACTIVE` | *Chưa tích hợp (GĐ 4)* | *Chưa dùng* |
| `GET` | `/api/v1/users/inactive` | `UserController:L102` | `ROLE_ADMIN` | `ACTIVE` | *Chưa tích hợp (GĐ 4)* | *Chưa dùng* |

---

## 2. DANH SÁCH ENDPOINT TẠI AI MICROSERVICE (`ai-service/app.py`)

| Phương thức | Endpoint | Input Payload | Output Data | Trạng thái thực tế |
| :---: | :--- | :--- | :--- | :---: |
| `GET` | `/health` | Không | `{"status": "UP", "service": "UniCheck AI Microservice"}` | **`REAL`** |
| `POST` | `/api/v1/face/extract-embedding` | `{"image_base64": "..."}` | `{"embedding": [0.0]*128, "confidence": 0.98}` | **`MOCK`** |
| `POST` | `/api/v1/face/check-liveness` | `{"challenge": "blink"}` | `{"is_live": true, "liveness_score": 0.96}` | **`MOCK`** |

---

## 3. DANH MỤC API CÒN THIẾU CẦN XÂY DỰNG CHO CÁC GIAI ĐOẠN TIẾP THEO

Dựa trên yêu cầu của 39 màn hình Stitch và 21 module SDD, các nhóm API sau **HOÀN TOÀN CHƯA CÓ TRÊN BACKEND**:

### 3.1. Phân hệ Điểm danh Sinh trắc học & Ca học (`AttendanceSessions`)
* `POST /api/v1/attendance-sessions`: Giảng viên tạo/mở ca điểm danh mới.
* `GET /api/v1/attendance-sessions/active`: Lấy danh sách ca điểm danh đang mở trong ngày.
* `GET /api/v1/attendance-sessions/{id}/qr`: Lấy mã QR động làm mới mỗi 5 giây (kèm HMAC watermark).
* `POST /api/v1/attendance/check-in`: Gửi dữ liệu điểm danh sinh viên (ảnh khuôn mặt, tọa độ GPS, Wi-Fi BSSID, QR token).
* `GET /api/v1/attendance-sessions/{id}/live`: Giám sát danh sách sinh viên check-in trực tiếp (WebSocket / SSE / Polling).
* `PUT /api/v1/attendance/manual`: Giảng viên ghi đè điểm danh thủ công (Có mặt / Đi trễ / Vắng / Có phép).

### 3.2. Phân hệ Đào tạo & Lớp học phần (`Classes & Timetables`)
* `GET /api/v1/classes`: Danh sách lớp học phần (phân trang, lọc theo học kỳ, khoa, giảng viên).
* `GET /api/v1/classes/{id}/students`: Danh sách sinh viên đăng ký trong lớp học phần.
* `GET /api/v1/timetable/me`: Thời khóa biểu cá nhân của Sinh viên / Giảng viên đang đăng nhập.
* `GET /api/v1/courses`: Danh mục học phần và học phần tiên quyết.
* `GET /api/v1/semesters`: Danh sách học kỳ, niên khóa và tuần học.

### 3.3. Phân hệ Cơ sở vật chất & Thiết bị phòng học (`Facilities`)
* `GET /api/v1/rooms`: Danh mục phòng học, tòa nhà, sức chứa.
* `GET /api/v1/wifi-access-points`: Danh sách địa chỉ MAC/BSSID của các điểm phát Wi-Fi trường.
* `POST /api/v1/rooms/{id}/wifi`: Gán điểm truy cập Wi-Fi vào phòng học phục vụ kiểm tra vị trí.

### 3.4. Phân hệ Báo cáo & Thống kê (`Reports`)
* `GET /api/v1/reports/attendance/class/{id}`: Thống kê tỷ lệ chuyên cần theo từng lớp học phần.
* `GET /api/v1/reports/attendance/student/{id}`: Lịch sử và tỷ lệ vắng của từng sinh viên.
* `GET /api/v1/reports/attendance/export`: Xuất dữ liệu chuyên cần ra tệp Excel (`.xlsx`) hoặc PDF.
* `GET /api/v1/reports/prohibited-list`: Danh sách sinh viên vắng quá 20% bị cấm thi theo quy chế đào tạo.

### 3.5. Phân hệ Đơn từ & Khiếu nại (`Academic Requests`)
* `POST /api/v1/academic-requests`: Sinh viên tạo đơn xin nghỉ học / khiếu nại điểm danh kèm minh chứng.
* `GET /api/v1/academic-requests`: Giảng viên / Ban đào tạo xem danh sách đơn cần phê duyệt.
* `PUT /api/v1/academic-requests/{id}/approve`: Duyệt / Từ chối đơn xin nghỉ học.
