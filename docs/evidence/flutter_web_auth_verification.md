# Bằng Chứng Xác Minh Triển Khai Flutter Web Foundation & Real Auth (TASK P04)

> **Mã nhiệm vụ:** TASK P04  
> **Trạng thái:** HOÀN THÀNH (100% Tests Passed & Web Build Succeeded)  
> **Thời điểm xác minh:** 2026-10-13 17:18:00 +07:00  
> **Phạm vi file:** Chỉ sửa đổi trong `mobile/` và tài liệu bằng chứng `docs/evidence/`

---

## 1. Môi Trường Thực Thi

| Thành phần | Phiên bản / Chi tiết |
| :--- | :--- |
| **Hệ điều hành** | Windows 11 Enterprise (amd64) |
| **Flutter SDK** | Flutter 3.47.3 • channel stable • Dart 3.13.3 |
| **Target Platforms** | Flutter Web (Chrome / Edge) & Android (SDK 37.0.0) |
| **State Management** | GetX 4.6.6 (`GetMaterialApp`, `GetxController`, `GetMiddleware`, `Bindings`) |
| **HTTP Networking** | Dio 5.7.0 (với Interceptor tự động kèm Bearer Token & Single-flight Refresh Mutex) |
| **Token Storage** | `flutter_secure_storage: ^9.2.2` (kết hợp `WebOptions` & in-memory cache) |
| **Backend API** | Spring Boot 3.3.4 (Java 21) tại `http://localhost:8080/api/v1` (Web) / `http://10.0.2.2:8080/api/v1` (Android) |

---

## 2. Các Thành Phần Kỹ Thuật Đã Triển Khai

### 2.1. Loại Bỏ Hoàn Toàn Mock & Delay 600ms
- Đã xóa bỏ toàn bộ `Future.delayed(const Duration(milliseconds: 600))` và đối tượng `UserModel` gán cứng tại dòng 16–26 của `auth_controller.dart`.
- Thay thế bằng luồng gọi mạng thực tế qua `AuthApiService.login(...)` và phân tích cú pháp dữ liệu phẳng theo chuẩn `LoginResponse` (P03 freeze).

### 2.2. Bộ Điều Hợp Lưu Trữ Token Theo Nền Tảng (`PlatformTokenStorage`)
- File: [`mobile/lib/core/storage/token_storage.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/core/storage/token_storage.dart)
- Hỗ trợ lưu trữ an toàn trên Android qua `EncryptedSharedPreferences`.
- Hỗ trợ Web qua `WebOptions(dbName: 'unicheck_vault', publicKey: 'unicheck_auth')` và đồng bộ bộ nhớ đệm in-memory phục vụ môi trường test headless.

### 2.3. Dio Client với Single-Flight Refresh Token Interceptor
- File: [`mobile/lib/core/network/api_client.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/core/network/api_client.dart)
- Tự động đính kèm `Authorization: Bearer <accessToken>` cho tất cả các request.
- Cơ chế **Single-Flight Refresh Mutex**: Khi nhận mã HTTP 401 trên request nghiệp vụ:
  - Khóa cờ `_isRefreshing`, đưa các request song song vào hàng đợi `Completer`.
  - Gửi **duy nhất 1 request** đến `/api/v1/auth/refresh-token` với `refreshToken`.
  - Thành công: Lưu token mới, cập nhật header cho toàn bộ request đang chờ và thực hiện retry.
  - Thất bại: Thu hồi token cục bộ, gọi `forceLogout()` và chuyển người dùng về `/login`.
- Không lặp vô tận khi 401 xuất hiện trên chính endpoint `/login` hoặc `/refresh-token`.

### 2.4. Khôi Phục Phiên Làm Việc Tự Động (`/me restore`)
- File: [`mobile/lib/feature/auth/controllers/auth_controller.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/auth/controllers/auth_controller.dart)
- Khi ứng dụng khởi động (`onInit`): Kiểm tra token còn lưu trong storage không. Nếu có, tự động gọi `GET /api/v1/auth/me` để lấy thông tin hồ sơ và định tuyến thẳng vào Shell tương ứng với vai trò của người dùng.

### 2.5. Phân Quyền & Route Guards (`RoleGuard` & `AuthGuard`)
- File: [`mobile/lib/core/routes/role_guard.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/core/routes/role_guard.dart)
- `AuthGuard`: Chặn truy cập nếu chưa đăng nhập, tự động chuyển về `/login`.
- `RoleGuard`: Chặn người dùng truy cập trái phép vai trò (ví dụ: Sinh viên không thể vào `/admin`, sẽ bị tự động điều hướng về `/student`).

### 2.6. Responsive Shell Cho ADMIN, LECTURER, STUDENT
- File: [`mobile/lib/feature/shell/views/responsive_shell.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/shell/views/responsive_shell.dart)
- Tương thích đa kích thước: Tối ưu cho Mobile (< 800px) và Desktop Web (>= 800px, giới hạn max-width 1200px).
- Hiển thị thông tin người dùng, huy hiệu Role (ADMIN: Đỏ, LECTURER: Cam, STUDENT: Xanh ngọc) và nút Đăng xuất server-side.
- 3 Shell chuyên biệt:
  - [`AdminShellView`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/shell/views/admin_shell_view.dart): Quản lý người dùng, Giám sát ca điểm danh, Audit log.
  - [`LecturerShellView`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/shell/views/lecturer_shell_view.dart): Lịch giảng dạy, Kích hoạt ca điểm danh, Báo cáo điểm danh.
  - [`StudentShellView`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/shell/views/student_shell_view.dart): Điểm danh khuôn mặt sinh trắc học (`FaceCheckinView`), Lịch học, Lịch sử điểm danh.

### 2.8. Loại Bỏ Mock Success Điểm Danh & Khắc Phục Tràn Khung Shell
- File: [`mobile/lib/feature/attendance/views/face_checkin_view.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/attendance/views/face_checkin_view.dart)
  - Đã loại bỏ hoàn toàn mock snackbar hardcode: `"Độ khớp khuôn mặt: 99.2% - Liveness: Hợp lệ"` tại dòng 111–117.
  - Thay thế bằng thông báo trung thực: `"Tính năng camera sinh trắc học đang được đồng bộ với AI Service"`.
- Files: [`admin_shell_view.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/shell/views/admin_shell_view.dart), [`lecturer_shell_view.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/shell/views/lecturer_shell_view.dart), [`student_shell_view.dart`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/lib/feature/shell/views/student_shell_view.dart)
  - Tinh chỉnh điểm ngắt GridView responsive (`>= 1024px`: 3 cột, `>= 640px`: 2 cột, `< 640px`: 1 cột) và padding thẻ chức năng, khắc phục triệt để lỗi tràn pixel (RenderFlex overflow) trên màn hình 800px.

---

## 3. Kết Quả Kiểm Thử Toàn Diện

### 3.1. Phân Tích Cú Pháp Mã Nguồn Flutter
```
> flutter analyze
Analyzing mobile...                                             
No issues found! (ran in 2.0s)
```

### 3.2. Bộ Kiểm Thử Tự Động Flutter (24/24 Tests PASS)
```
> flutter test
00:00 +0: loading test/api_client_test.dart
00:00 +1: ApiClient Error Extraction parses custom message from backend response
00:00 +2: ApiClient maps standard HTTP status codes
00:00 +3: ApiClient maps connection timeouts
00:00 +4: ApiClient Request interceptor injects Bearer token into Authorization header
00:00 +5: ApiClient 401 on login endpoint does not trigger token refresh or auth failure
00:00 +6: AuthController Login validation: empty username/password returns false
00:00 +7: AuthController Login failure: network/credential error sets errorMessage
00:00 +8: AuthController Login success: stores tokens, sets user model, marks isAuthenticated true
00:00 +9: AuthController Logout: clears storage, purges state, triggers server logout
00:00 +10: AuthController Restore session: populates user when valid token exists
00:00 +11: AuthController Restore session failure: clears stale token when /me fails
00:00 +12: Route Guards AuthGuard redirects to /login when unauthenticated
00:00 +13: Route Guards AuthGuard allows access when authenticated
00:00 +14: Route Guards RoleGuard allows access when role matches
00:00 +15: Route Guards RoleGuard redirects student away from admin route to /student
00:00 +16: Route Guards RoleGuard redirects lecturer away from admin route to /lecturer
00:00 +17: TokenStorage Initial state: hasAccessToken returns false and tokens are null
00:00 +18: TokenStorage saveTokens persists both access and refresh tokens
00:00 +19: TokenStorage clearTokens purges both tokens
00:00 +20: WidgetTest UniCheck Mobile app smoke test: renders login screen and inputs
00:01 +21: WidgetTest Login validation: empty submission shows error banner
00:01 +22: WidgetTest (401 Bad Credentials): displays error banner on failed login
00:02 +23: WidgetTest (401 Expired Session): forceLogout displays expired session banner
00:02 +24: WidgetTest (403 / Role Mismatch): verifies role guard blocks unauthorized access
00:02 +24: All tests passed!
```

### 3.3. Biên Dịch Thực Tế Flutter Web Bundle
```
> flutter build web
Compiling lib\main.dart for the Web...                             36.8s
√ Built build\web
```

### 3.4. Kiểm Thử Backend Hồi Quy (Zero Regression)
```
> mvn test
[INFO] Tests run: 39, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

---

## 4. Bảng Kiểm Tuân Thủ Kỹ Thuật (Compliance Checklist)

- [x] Giữ nguyên kiến trúc GetX của ứng dụng Flutter hiện có.
- [x] Đã xóa bỏ hoàn toàn delay 600ms và user hardcode; thay bằng Dio gọi API thật.
- [x] Parse chính xác cấu trúc `LoginResponse` dạng phẳng đã đóng băng ở P03.
- [x] Token Storage Adapter hỗ trợ đa nền tảng (Android EncryptedSharedPreferences, Web SecureVault & in-memory cache).
- [x] Cơ chế Single-flight refresh token mutex tránh race-condition khi đồng thời nhận HTTP 401.
- [x] Đăng xuất kép (thu hồi token trên máy chủ Spring Boot + xóa token cục bộ).
- [x] Route Guard phân quyền chặt chẽ theo vai trò (`ADMIN`, `LECTURER`, `STUDENT`).
- [x] Tự động khôi phục phiên qua `/me` khi mở app.
- [x] Responsive Shell cho cả 3 vai trò chạy mượt mà trên Flutter Web và Android (không tràn khung hình).
- [x] Đã gỡ bỏ toàn bộ mock success (Snackbar 99.2% trong `face_checkin_view.dart`).
- [x] Đã bổ sung đầy đủ bộ test Widget cho 401 Unauthorized, 401 Expired Session và 403 Role Guard.
- [x] Không sao chép giao diện/mã nguồn React legacy.
- [x] Tuyệt đối không hardcode mock token hoặc mock success trong mã production.
- [x] 100% test Flutter (24/24) và test Backend (39/39) vượt qua thành công.
- [x] Biên dịch Flutter Web đạt kết quả `√ Built build\web`.

