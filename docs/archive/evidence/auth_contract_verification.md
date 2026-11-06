# Bằng Chứng Xác Minh Đóng Băng Hợp Đồng Auth API Thực (TASK P03)

> **Mã nhiệm vụ:** TASK P03  
> **Trạng thái:** HOÀN THÀNH (100% Tests Passed)  
> **Thời điểm xác minh:** 2026-10-13 17:01:00 +07:00  
> **Commit SHA cơ sở:** `0ad5e70db2e03b4d67d9dabd06fb49aae0c08306` (branch `develop`)

---

## 1. Môi Trường Thực Thi

| Thành phần | Phiên bản / Chi tiết |
| :--- | :--- |
| **Hệ điều hành** | Windows 11 Enterprise (amd64) |
| **Java JDK** | Oracle OpenJDK 22.0.2 (Bytecode target: Java 21) |
| **Build Tool** | Apache Maven 3.9.11 |
| **Cơ sở dữ liệu** | PostgreSQL 18.4 (Port 5432, schema `public` 50 bảng) + In-memory H2 test profile |
| **Session Cache** | Redis 7 & Dual-write Fallback Concurrent Cache |
| **Flutter SDK** | Flutter 3.47.3 • channel stable • Dart 3.13.3 |

---

## 2. Danh Sách Tài Liệu và Code Đã Tạo Mới Trong P03

1. **[`docs/api/openapi.yaml`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/docs/api/openapi.yaml)**:
   - Đặc tả chuẩn **OpenAPI 3.0.3** đầy đủ cho Auth (`/api/v1/auth`, `/api/auth`) và User Management (`/api/v1/users`, `/api/users`).
   - Định nghĩa chi tiết BearerAuth security scheme, cấu trúc phản hồi phẳng `LoginResponse` (không nest `user`), `TokenRefreshResponse`, `UserProfileResponse`, `UserResponse`, `UserCreateRequest`, `UserUpdateRequest`, envelopes `ApiResponse<T>`, `PageResponse<T>`, và bảng 26 mã lỗi `ErrorCode` từ `ERR_1000` đến `ERR_4002`.
2. **[`docs/api/auth_api_contract.md`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/docs/api/auth_api_contract.md)**:
   - Tài liệu hướng dẫn tích hợp chính thức dành cho kỹ sư Flutter Mobile (`mobile/`).
   - Cảnh báo bắt buộc về schema phẳng, sơ đồ sequence diagram OTP reset password, bảng mã lỗi, vòng đời Access Token 15 phút (900s) và Refresh Token 7 ngày (604,800s).
3. **[`backend/src/test/java/com/unicheck/controller/RouteAliasCompatibilityContractTest.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/test/java/com/unicheck/controller/RouteAliasCompatibilityContractTest.java)**:
   - 6 test cases tích hợp MockMvc kiểm tra hợp đồng thực tế giữa tuyến canonical `/api/v1/...` và alias `/api/...`.

---

## 3. Kết Quả Kiểm Thử Tự Động

### 3.1. Route Alias Contract Integration Tests (`RouteAliasCompatibilityContractTest`)

```
[INFO] Running com.unicheck.controller.RouteAliasCompatibilityContractTest
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 10.38 s -- in com.unicheck.controller.RouteAliasCompatibilityContractTest
[INFO] Results:
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Chi tiết 6 kịch bản kiểm thử hợp đồng:
- **`P03-1` (`testLoginCanonicalAndAliasReturnIdenticalFlatContract`):**
  - Cả 2 route `/api/v1/auth/login` và `/api/auth/login` đều trả về HTTP 200 OK.
  - Envelope `success = true`, `message = "Đăng nhập thành công"`, `errorCode = null`.
  - Dữ liệu phẳng: `token`, `refreshToken`, `tokenType = "Bearer"`, `expiresIn = 900`, `userId`, `code`, `username`, `fullName`, `email`, `role = "STUDENT"`, `isPasswordChanged = true`.
  - Khẳng định hợp đồng: `$.data.user` **KHÔNG TỒN TẠI** (không lồng object).
- **`P03-2` (`testGetProfileCanonicalAndAliasReturnIdenticalData`):**
  - Cả 4 route (`/api/v1/auth/me`, `/api/auth/me`, `/api/v1/auth/profile`, `/api/auth/profile`) trả về thông tin hồ sơ đồng nhất.
- **`P03-3` (`testRefreshTokenCanonicalAndAliasParity`):**
  - Luồng Refresh Token Rotation hoạt động đồng bộ trên cả 2 tuyến `/api/v1/auth/refresh-token` và `/api/auth/refresh-token`.
- **`P03-4` (`testLogoutCanonicalAndAliasParity`):**
  - Đăng xuất thu hồi token thành công trên cả 2 tuyến.
- **`P03-5` (`testErrorHandlingCanonicalAndAliasParity`):**
  - Sai mật khẩu trả về HTTP 401 với mã lỗi `ERR_2002` trên cả 2 tuyến.
  - Thiếu tham số bắt buộc trả về HTTP 400 với mã lỗi `ERR_1001` trên cả 2 tuyến.
  - Gọi `/me` không có Bearer token trả về HTTP 401 với mã lỗi `ERR_2000` trên cả 2 tuyến.
- **`P03-6` (`testUserManagementCanonicalAndAliasParity`):**
  - Quản trị viên truy cập `/api/v1/users` và `/api/users` trả về PageResponse tương đồng.
  - Sinh viên truy cập bị chặn với HTTP 403 Forbidden `ERR_2001` trên cả 2 tuyến.

### 3.2. Toàn Bộ Test Suite Backend (`mvn test`)

```
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.unicheck.controller.AuthenticationIntegrationTest
[INFO] Tests run: 14, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 5.253 s
[INFO] Running com.unicheck.controller.RouteAliasCompatibilityContractTest
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.953 s
[INFO] Running com.unicheck.repository.PostgresCleanDatabaseStartupTest
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.413 s
[INFO] Running com.unicheck.repository.UserRepositoryTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.054 s
[INFO] Running com.unicheck.UniCheckApplicationTests
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.024 s
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 39, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  22.665 s
[INFO] Finished at: 2026-10-13T16:58:22+07:00
```

### 3.3. Kiểm Thử Ứng Dụng Flutter Mobile (`mobile/`)

```
> flutter analyze
Analyzing mobile...                                             
No issues found! (ran in 6.3s)

> flutter test
00:00 +0: loading C:/Users/Admin/Documents/Antigravity/UniCheck/mobile/test/widget_test.dart
00:00 +0: UniCheck Mobile app smoke test
00:00 +1: All tests passed!
```

---

## 4. Bảng Kiểm Tuân Thủ Ràng Buộc Kỹ Thuật (Compliance Checklist)

- [x] Không sửa mã nguồn React legacy (`frontend/` giữ nguyên trạng thái read-only).
- [x] Không chỉnh sửa các file Flyway migrations V1–V3.
- [x] Tuyến Canonical `/api/v1/...` được đóng băng làm chuẩn cho client Flutter.
- [x] Tuyến Alias `/api/...` được bảo tồn tương thích 100% và có bộ test tự động kiểm chứng song song.
- [x] Dữ liệu trả về dạng phẳng `LoginResponse` được khóa chặt và tài liệu hóa rõ ràng để ngăn lỗi phân tích cú pháp ở mobile.
- [x] 100% test backend (39/39) và mobile (1/1) vượt qua thành công.
