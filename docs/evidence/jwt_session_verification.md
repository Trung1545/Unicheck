# UNICHECK - JWT SECURITY & SESSION MANAGEMENT VERIFICATION (TASK P02)
**Thời điểm thực thi**: 2026-10-13  
**Môi trường**: Windows 11 Enterprise, Java 22 / JDK 21 compatible, Spring Boot 3.3.4  
**Phạm vi**: `backend/src/main/java/.../security`, `AuthServiceImpl.java`, `EmailServiceImpl.java`, `AuthenticationIntegrationTest.java`

---

## 1. MỤC TIÊU VÀ KẾT QUẢ ĐẠT ĐƯỢC

| Mục tiêu bảo mật | Hiện trạng trước P02 | Sau khi thực hiện P02 | Kết quả kiểm thử |
| :--- | :--- | :--- | :---: |
| **1. Phân biệt Access vs Refresh** | Refresh Token gọi `/me` được duyệt | `JwtAuthenticationFilter` chặn `type != access`, trả về **401 Unauthorized** | **PASS** (`P02-1`) |
| **2. Refresh Token Rotation** | Trả lại nguyên refresh token cũ | Xoay vòng: cấp cặp mới `(A2, R2)`, hủy `R1` | **PASS** (`P02-2`) |
| **3. Refresh Reuse Detection** | Không phát hiện dùng lại token cũ | Bắt reuse: gửi lại `R1` lần 2 lập tức bị từ chối **401 Unauthorized (`ERR_2010`)** | **PASS** (`P02-2`) |
| **4. Cô lập đa thiết bị (Multi-Device)** | Đăng xuất 1 thiết bị xóa sạch phiên | Logout Thiết bị 1 chỉ hủy session 1; Thiết bị 2 vẫn hoạt động bình thường | **PASS** (`P02-3`) |
| **5. Bảo mật Log (Sensitive Data)** | In raw JWT và raw OTP ra log | - Token băm SHA-256 trong Redis key (`sha256_...`)<br>- OTP được che giấu thành `[******]` | **PASS** (Đã xác minh trong log) |
| **6. Fail-Safe In-Memory Cache** | Khi Redis lỗi, token revoked bị lọt | Dual-write: Ghi song song vào in-memory cache, không cho phép token revoked lọt qua | **PASS** |

---

## 2. KẾT QUẢ TEST SUITE BACKEND THỰC TẾ

- **Lệnh thực thi**: `mvn test` trong thư mục `backend/`
- **Thời gian chạy**: 18.070 s
- **Tổng số tests**: **33 tests** (30 test cũ + 3 test mới của P02)
- **Kết quả**: **BUILD SUCCESS** (0 failures, 0 errors, 0 skipped)

```
[INFO] Results:
[INFO] 
[INFO] Tests run: 33, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  18.070 s
```

### Chi tiết các test mới của P02:
1. `P02-1: Refresh Token gửi trong Authorization Bearer bị từ chối truy cập /me (401 Unauthorized)`:
   - Access token gọi `/me` -> `200 OK`.
   - Refresh token gọi `/me` -> `401 Unauthorized` (`errorCode: ERR_2000`).
2. `P02-2: Xoay vòng Refresh Token (Rotation) và Chặn tái sử dụng token cũ (Reuse Detection)`:
   - Gửi `initialRefreshToken` -> Nhận `(newAccessToken, rotatedRefreshToken)`.
   - Gửi lại `initialRefreshToken` lần 2 -> `401 Unauthorized` (`errorCode: ERR_2010`).
   - Gửi `rotatedRefreshToken` -> Thành công cấp tiếp cặp mới.
3. `P02-3: Đa thiết bị (Multi-Device) – Logout trên Thiết bị 1 không làm mất phiên Thiết bị 2`:
   - Đăng nhập Thiết bị 1 (Mobile) và Thiết bị 2 (Web) cùng lúc.
   - Logout Thiết bị 1 -> Thiết bị 1 bị từ chối (401).
   - Thiết bị 2 gọi `/me` -> Tiếp tục thành công (`200 OK`).

---

## 3. CHECKLIST TIÊU CHÍ PASS CỦA NHIỆM VỤ P02

- [x] **PASS**: Refresh JWT gọi `/me` trả về 401 Unauthorized.
- [x] **PASS**: Access token hợp lệ vẫn hoạt động bình thường.
- [x] **PASS**: Logout và Refresh reuse bị từ chối (401).
- [x] **PASS**: Không làm gián đoạn các phiên đăng nhập của thiết bị khác khi logout một thiết bị.
- [x] **PASS**: Che giấu toàn bộ thông tin nhạy cảm (JWT băm SHA-256, OTP masked `[******]`).
- [x] **PASS**: Tất cả test suites cũ và mới (33/33 tests) đều đạt PASS 100%.
- [x] **PASS**: `flutter analyze` và `flutter test` tiếp tục đạt 100% không lỗi.
