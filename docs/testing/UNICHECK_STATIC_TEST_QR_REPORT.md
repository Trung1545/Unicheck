# BÁO CÁO TRIỂN KHAI VÀ KIỂM THỬ: STATIC TEST QR CHO ANDROID EMULATOR

> **Dự án**: Hệ thống Điểm danh Thông minh Sinh trắc học UniCheck  
> **Tính năng**: Static Test QR Code (Phục vụ Kiểm thử Điểm danh trên Android Emulator)  
> **Phiên bản tài liệu**: 1.0.0  
> **Ngày lập báo cáo**: 08/11/2026  
> **Đối tượng áp dụng**: Lớp thử nghiệm `UNICHECK-E2E-01` | Môn học `IT301` | Học kỳ `FALL2026`  

---

## 1. DANH SÁCH FILE ĐÃ THAY ĐỔI VÀ TẠO MỚI

Hệ thống được thiết kế theo nguyên tắc **Zero-Pollution Production**: Giữ nguyên 100% logic của Dynamic QR phục vụ Production, chỉ bổ sung Static Test QR qua module chuyên biệt và kiểm soát nghiêm ngặt bằng cơ chế cấu hình đa lớp.

### 1.1. Backend (Spring Boot 3.3.4 + Java 22)

| STT | File Đường Dẫn | Trạng Thái | Mô Tả Chức Năng |
| :--- | :--- | :--- | :--- |
| 1 | `backend/src/main/resources/application.yml` | Modified | Khai báo cấu hình `unicheck.testing.static-qr.enabled: false` (mặc định tắt trên toàn bộ hệ thống). |
| 2 | `backend/src/main/resources/application-test.yml` | Modified | Kích hoạt `unicheck.testing.static-qr.enabled: true` và `allowed-class-name: UNICHECK-E2E-01` cho profile test. |
| 3 | `backend/src/main/java/com/unicheck/exception/ErrorCode.java` | Modified | Bổ sung mã lỗi `STATIC_QR_NOT_ALLOWED` (`ERR_3025`). |
| 4 | `backend/src/main/java/com/unicheck/model/dto/QrTokenResponse.java` | Modified | Bổ sung thuộc tính `mode` (`DYNAMIC_QR` hoặc `STATIC_TEST_QR`). |
| 5 | `backend/src/main/java/com/unicheck/model/dto/StaticQrStatusResponse.java` | **Created** | DTO phản hồi tính khả dụng của Static QR cho phiên điểm danh (`allowed`, `reason`, `className`, `sessionId`, `sessionStatus`). |
| 6 | `backend/src/main/java/com/unicheck/service/StaticTestQrService.java` | **Created** | Interface định nghĩa nghiệp vụ phát hành, xác thực, thu hồi và quản lý vòng đời Static Test QR. |
| 7 | `backend/src/main/java/com/unicheck/service/impl/StaticTestQrServiceImpl.java` | **Created** | Hiện thực nghiệp vụ: Kiểm tra profile/cờ bật/RBAC/lớp học, sinh token ngẫu nhiên bảo mật bằng `SecureRandom`, băm SHA-256 lưu trữ bộ nhớ đệm, xác thực token không rò rỉ plaintext. |
| 8 | `backend/src/main/java/com/unicheck/controller/DynamicQrController.java` | Modified | Bổ sung các REST endpoint `/sessions/{id}/static-qr/status`, `/sessions/{id}/static-qr`, `/sessions/{id}/static-qr/regenerate`, `/sessions/{id}/static-qr/revoke`; định tuyến `/qr/validate` tự động nhận dạng Static Test QR. |
| 9 | `backend/src/main/java/com/unicheck/service/impl/DynamicQrServiceImpl.java` | Modified | Trả về `mode: "DYNAMIC_QR"`, tích hợp thu hồi Static QR cache khi phiên đóng. |
| 10 | `backend/src/main/java/com/unicheck/service/impl/AttendanceSessionServiceImpl.java` | Modified | Gọi xác thực `qrToken` (hỗ trợ cả Static và Dynamic) khi sinh viên gửi yêu cầu `checkInStudent`; thu hồi Static QR khi đóng phiên (`closeSession`). |
| 11 | `backend/src/test/java/com/unicheck/controller/StaticTestQrIntegrationTest.java` | **Created** | 18 test case tích hợp (MockMvc): RBAC, chặn sinh viên, giới hạn lớp, xác thực SHA-256, thu hồi, gia hạn, đóng phiên, E2E check-in đầy đủ 5 tiêu chí. |
| 12 | `backend/src/test/java/com/unicheck/service/StaticTestQrServiceUnitTest.java` | **Created** | 2 unit test cô lập chứng minh chặn hoàn toàn trên môi trường Production (`prod`/`production`) và khi cờ cấu hình bị tắt. |

### 1.2. Frontend (React 18 + Vite + TypeScript)

| STT | File Đường Dẫn | Trạng Thái | Mô Tả Chức Năng |
| :--- | :--- | :--- | :--- |
| 1 | `frontend/src/types/attendance.ts` | Modified | Định nghĩa kiểu `StaticQrStatusResponse`, mở rộng `QrTokenResponse` thêm trường `mode`. |
| 2 | `frontend/src/api/attendance.api.ts` | Modified | Bổ sung API client: `getStaticQrStatusApi`, `getStaticQrTokenApi`, `regenerateStaticQrTokenApi`, `revokeStaticQrTokenApi`, tham số `mode` cho `getSessionQrTokenApi`. |
| 3 | `frontend/src/pages/lecturer/SessionQrCodePage.tsx` | Modified | Tự động kiểm tra quyền Static QR khi tải phiên; hiển thị thanh chuyển đổi chế độ `[QR Động]` và `[QR Test Cố Định]`; giao diện Test Mode với nhãn cảnh báo `TEST MODE`, đồng hồ đếm ngược, nút Sao chép, Thu hồi và Cấp lại. Cam kết tuyệt đối không lưu token vào `localStorage`. |
| 4 | `frontend/src/test/dynamic-qr.test.ts` | Modified | Bổ sung 3 test case kiểm thử hợp đồng Static Test QR, tính bất biến không xoay vòng, và Zero-LocalStorage policy. |

### 1.3. Mobile (Flutter 3.x + GetX)

| STT | File Đường Dẫn | Trạng Thái | Mô Tả Chức Năng |
| :--- | :--- | :--- | :--- |
| 1 | `mobile/lib/core/constants/api_constants.dart` | Modified | Khai báo endpoint `validateQr = '/attendance/qr/validate'`. |
| 2 | `mobile/lib/feature/attendance/models/qr_payload_model.dart` | Modified | Bổ sung parser nhận dạng định dạng `STQR:<sessionId>:<hexToken>`, `STQR-<sessionId>-<hexToken>`, và giải mã payload JWT Dynamic QR. |
| 3 | `mobile/lib/feature/attendance/services/attendance_api_service.dart` | Modified | Bổ sung hàm gọi API `validateQrToken({qrToken, sessionId})` tới Spring Boot. |
| 4 | `mobile/lib/feature/attendance/controllers/attendance_controller.dart` | Modified | Tích hợp xác thực mã QR đối soát trực tiếp với Backend trong phương thức `runEligibilityChecks`; truyền đúng `qrToken` vào yêu cầu điểm danh `submitAttendanceCheckin`. |
| 5 | `mobile/lib/feature/attendance/views/qr_scanner_view.dart` | Modified | Tích hợp hộp thoại "Nhập / Dán mã QR Test" chuyên dụng trong Debug Build (`kDebugMode`) giúp kiểm thử trên Android Emulator không cần camera thực mà vẫn bảo đảm Backend xác thực token thật. |
| 6 | `mobile/test/attendance_flow_test.dart` | Modified | Cập nhật mock service và bổ sung bộ test phân tích định dạng Static Test QR, JWT Token, và chuỗi rác không hợp lệ. |

---

## 2. CẤU HÌNH MÔI TRƯỜNG TEST

Cấu hình được quản lý qua Spring Boot Profiles và biến môi trường:

### 2.1. Cấu hình Mặc định (`application.yml` - Production Safe)
```yaml
unicheck:
  testing:
    static-qr:
      enabled: false                      # Mặc định tắt trên toàn hệ thống
      allowed-class-name: UNICHECK-E2E-01 # Chỉ ràng buộc duy nhất lớp kiểm thử
      ttl-minutes: 30                     # Giới hạn thời gian hiệu lực tối đa
```

### 2.2. Cấu hình Test (`application-test.yml`)
```yaml
unicheck:
  testing:
    static-qr:
      enabled: true                       # Bật trong môi trường test
      allowed-class-name: UNICHECK-E2E-01
      ttl-minutes: 30
```

---

## 3. VÒNG ĐỜI VÀ BẢO MẬT CỦA STATIC TEST QR (STATIC QR LIFECYCLE)

```
                       +--------------------------------------------------+
                       |           Giảng viên / Admin mở phiên            |
                       |                 SESSION: OPEN                    |
                       +--------------------------------------------------+
                                                 |
                                                 v
                       +--------------------------------------------------+
                       |      Kiểm tra Điều kiện An toàn Đa tầng:         |
                       |  1. Active Profile in (test, e2e, dev, local)   |
                       |  2. Active Profile NOT contains (prod)           |
                       |  3. unicheck.testing.static-qr.enabled == true   |
                       |  4. Caller == ASSIGNED LECTURER or ADMIN         |
                       |  5. ClassName == UNICHECK-E2E-01                 |
                       +--------------------------------------------------+
                                                 |
                                                 v
                       +--------------------------------------------------+
                       |      Sinh Token bằng CSPRNG (SecureRandom):      |
                       |        Raw: STQR:<sessionId>:<hex_64_chars>      |
                       |        (256-bit Entropy ngẫu nhiên cao)          |
                       +--------------------------------------------------+
                                                 |
                                                 v
                       +--------------------------------------------------+
                       |           Chỉ lưu SHA-256 Hash vào Cache:        |
                       |       Key: unicheck:qr:session:<id>:static-test  |
                       |       Value: SHA-256(Raw Token) | TTL: 30 mins   |
                       |       (KHÔNG BAO GIỜ lưu Plaintext Token)        |
                       +--------------------------------------------------+
                                                 |
                         +-----------------------+-----------------------+
                         |                                               |
                         v                                               v
          +-------------------------------+               +-------------------------------+
          |       Sinh viên Check-In      |               |  Sự kiện Hủy / Đóng phiên:    |
          |  1. Emulator quét/dán token   |               |  1. Hết hạn TTL (30 phút)     |
          |  2. Backend băm SHA-256       |               |  2. Giảng viên ấn [Thu hồi]   |
          |  3. Khớp Hash trong Cache     |               |  3. Giảng viên ấn [Cấp lại]   |
          |  4. Kiểm tra Session OPEN     |               |  4. Đóng phiên điểm danh      |
          |  5. Đối soát Wi-Fi, Enrollment|               +-------------------------------+
          |  6. Đối soát Face ArcFace     |                               |
          |  ==> Ghi nhận PRESENT         |                               v
          +-------------------------------+               +-------------------------------+
                                                          |  Xóa Hash khỏi Cache Bộ nhớ   |
                                                          |  Mã QR lập tức VÔ HIỆU HÓA    |
                                                          +-------------------------------+
```

---

## 4. DANH MỤC API PHÁT HÀNH VÀ XÁC THỰC

### 4.1. Tra cứu khả dụng Static Test QR
- **Endpoint**: `GET /api/v1/attendance/sessions/{sessionId}/static-qr/status`
- **Quyền hạn**: `LECTURER`, `ADMIN`
- **Mẫu phản hồi cho phép**:
```json
{
  "code": 200,
  "message": "Tra cứu trạng thái Static Test QR thành công",
  "data": {
    "allowed": true,
    "className": "UNICHECK-E2E-01",
    "sessionId": 101,
    "sessionStatus": "OPEN",
    "reason": "Chế độ Static Test QR khả dụng cho lớp UNICHECK-E2E-01"
  }
}
```
- **Mẫu phản hồi khi bị chặn (ví dụ lớp khác)**:
```json
{
  "code": 200,
  "message": "Tra cứu trạng thái Static Test QR thành công",
  "data": {
    "allowed": false,
    "className": "SE101-PROD",
    "sessionId": 102,
    "sessionStatus": "OPEN",
    "reason": "Static Test QR chỉ áp dụng cho lớp thử nghiệm UNICHECK-E2E-01"
  }
}
```

### 4.2. Phát hành / Lấy mã Static Test QR hiện hành
- **Endpoint**: `GET /api/v1/attendance/sessions/{sessionId}/static-qr` (hoặc `GET /api/v1/attendance/sessions/{sessionId}/qr?mode=STATIC_TEST_QR`)
- **Quyền hạn**: `LECTURER` phụ trách hoặc `ADMIN` (Sinh viên gọi sẽ nhận ngay `403 FORBIDDEN`).
- **Mẫu phản hồi**:
```json
{
  "code": 200,
  "message": "Lấy mã QR Test cố định thành công",
  "data": {
    "token": "STQR:101:e5a8f9c1d2e3b4a5f60718293a4b5c6d7e8f90a1b2c3d4e5f6a7b8c9d0e1f2a3",
    "issuedAt": "2026-11-08T22:00:00Z",
    "expiresAt": "2026-11-08T22:30:00Z",
    "rotationIntervalSeconds": 1800,
    "status": "OPEN",
    "mode": "STATIC_TEST_QR"
  }
}
```

### 4.3. Cấp lại / Làm mới Static Test QR
- **Endpoint**: `POST /api/v1/attendance/sessions/{sessionId}/static-qr/regenerate`
- **Quyền hạn**: `LECTURER` phụ trách hoặc `ADMIN`.
- **Hành vi**: Xóa mã băm cũ, cấp mã ngẫu nhiên mới với chu kỳ TTL 30 phút mới. Token cũ bị vô hiệu ngay lập tức.

### 4.4. Thu hồi Static Test QR
- **Endpoint**: `POST /api/v1/attendance/sessions/{sessionId}/static-qr/revoke`
- **Quyền hạn**: `LECTURER` phụ trách hoặc `ADMIN`.
- **Hành vi**: Xóa mã băm trong Cache. Mọi yêu cầu điểm danh sử dụng token này sau đó đều bị từ chối với lỗi `ERR_3020`.

### 4.5. Xác thực mã QR
- **Endpoint**: `POST /api/v1/attendance/qr/validate`
- **Quyền hạn**: Người dùng đã đăng nhập (`STUDENT`, `LECTURER`, `ADMIN`).
- **Payload**:
```json
{
  "qrToken": "STQR:101:e5a8f9c1d2e3b4a5f60718293a4b5c6d7e8f90a1b2c3d4e5f6a7b8c9d0e1f2a3",
  "sessionId": 101
}
```
- **Mẫu phản hồi hợp lệ**:
```json
{
  "code": 200,
  "message": "Xác thực mã QR thành công",
  "data": {
    "valid": true,
    "sessionId": 101,
    "className": "UNICHECK-E2E-01",
    "roomName": "A4-501",
    "expiresAt": "2026-11-08T22:30:00Z",
    "message": "Static Test QR hợp lệ"
  }
}
```

---

## 5. GIAO DIỆN LECTURER WEB (`SessionQrCodePage.tsx`)

1. **Thanh chuyển đổi chế độ thông minh**:
   - Chỉ xuất hiện khi Backend phản hồi `status.allowed === true`.
   - Giảng viên có thể chuyển đổi linh hoạt giữa:
     - `[ Chế độ QR Động ]` (Mặc định chuẩn Production - xoay vòng mỗi 10s).
     - `[ Chế độ QR Test Cố Định ]` (Dành riêng cho Emulator - đứng yên, TTL 30 phút).
2. **Cảnh báo trực quan TEST MODE**:
   - Khung viền cam nổi bật kèm nhãn cảnh báo:  
     `⚠️ CHẾ ĐỘ QR TEST CỐ ĐỊNH (DEVELOPMENT / TEST ONLY) - Dành riêng cho kiểm thử trên Android Emulator. Không tự động thay đổi.`
3. **Bộ công cụ hỗ trợ Tester**:
   - **Đồng hồ đếm ngược thời hạn**: Hiển thị chính xác thời gian còn lại của token test (ví dụ `29:45`).
   - **Nút Sao chép Token Test**: Cho phép một click copy chuỗi `STQR:...` để dán nhanh vào Android Emulator trên Windows.
   - **Nút Cấp lại QR Test**: Sinh token ngẫu nhiên mới tức thì khi cần kiểm thử luồng cấp mới.
   - **Nút Thu hồi**: Vô hiệu hóa token ngay lập tức để kiểm thử trường hợp Negative Test.
4. **Cam kết Zero-LocalStorage**:
   - Tuyệt đối không lưu token vào `localStorage` hay `sessionStorage`. Toàn bộ trạng thái chỉ lưu trong React Component State (`useState`).

---

## 6. FLUTTER ANDROID EMULATOR TEST FLOW

Nhằm giải quyết triệt để vấn đề Android Emulator chạy trên Windows không thể chiếu camera quét màn hình máy chủ:
1. **Kiểm tra và hỗ trợ quét camera thông thường**: Khi chạy trên thiết bị thật, camera vẫn quét và nhận diện chuỗi `STQR:...` hoặc Dynamic JWT bình thường.
2. **Hộp thoại Dán mã QR Test trong Debug Build**:
   - Được bảo vệ bởi điều kiện biên dịch `if (kDebugMode)`.
   - Nút `Dán mã QR Test (Debug Emulator)` hiển thị trên màn hình quét QR và cả khi camera không khả dụng (Emulator không có webcam).
   - Khi ấn, mở hộp thoại cho phép tester dán chuỗi `STQR:<sessionId>:<hex>` vừa copy từ giao diện Giảng viên.
3. **Bảo đảm chuẩn mực An ninh nghiêm ngặt**:
   - **Không tự sinh/lấy token**: Ứng dụng di động của sinh viên không có API lấy token. Token bắt buộc phải được giảng viên cấp trên Web.
   - **Bảo toàn 100% đối soát**: Sau khi dán token, ứng dụng tiếp tục chạy đủ chu trình đối soát:
     - Đối soát Wi-Fi BSSID/SSID trạm phát phòng học.
     - Đối soát khung giờ ca học.
     - Đối soát danh sách ghi danh chính thức.
     - Đối soát khuôn mặt Face-ID và Liveness.
   - **Backend là cơ quan thẩm quyền tối cao**: Khi gửi yêu cầu điểm danh, Backend băm token và so khớp với cache, không cho phép client tự xác thực giả mạo.
   - **Không lưu trữ dài hạn**: Token chỉ được lưu tạm thời trong bộ nhớ RAM (`AttendanceController.qrPayload`) trong phiên check-in hiện tại, không ghi vào SQLite, SharedPreferences hay SecureStorage.

---

## 7. BẢNG TỔNG HỢP KẾT QUẢ KIỂM THỬ (TEST RESULTS)

| STT | Phân Loại | Tên Test Case | Kỳ Vọng | Kết Quả |
| :---: | :--- | :--- | :--- | :---: |
| 1 | Lifecycle | `testLecturerCanGetStaticTestQr` | Giảng viên lấy thành công token `STQR:...` cho phiên test | **PASS** |
| 2 | Lifecycle | `testStaticQrIsIdempotentWithinTtl` | Gọi nhiều lần trong cùng phiên trả về cùng một mã tĩnh | **PASS** |
| 3 | Lifecycle | `testLecturerCanRegenerateStaticQr` | Giảng viên cấp lại QR tạo ra token mới, token cũ bị vô hiệu | **PASS** |
| 4 | Lifecycle | `testLecturerCanRevokeStaticQr` | Giảng viên thu hồi QR khiến token không còn hợp lệ | **PASS** |
| 5 | Lifecycle | `testClosingSessionInvalidatesStaticQr` | Đóng phiên điểm danh lập tức hủy toàn bộ hiệu lực QR | **PASS** |
| 6 | Security RBAC | `testStudentCannotRequestStaticQr` | Tài khoản Sinh viên gọi API cấp Static QR bị chặn với `403 FORBIDDEN` | **PASS** |
| 7 | Security Scope | `testNonE2eClassCannotUseStaticQr` | Lớp khác ngoài `UNICHECK-E2E-01` bị từ chối với `ERR_3025` | **PASS** |
| 8 | Security Scope | `testProductionProfileBlocksStaticQrIssuance` | Khi profile chứa `prod`/`production`, chặn hoàn toàn phát hành Static QR | **PASS** |
| 9 | Security Scope | `testStaticQrDisabledByDefaultThrowsException` | Khi cờ `enabled: false`, gọi Static QR ném `STATIC_QR_NOT_ALLOWED` | **PASS** |
| 10 | Security Data | `testTokenStorageIsHashedOnly` | Kiểm tra Cache/DB không lưu plaintext, chỉ lưu SHA-256 | **PASS** |
| 11 | Validation | `testValidateStaticQrSuccess` | Sinh viên gọi `/qr/validate` với token đúng nhận phản hồi `valid: true` | **PASS** |
| 12 | Negative | `testValidateTamperedTokenFails` | Sửa 1 ký tự trong token bị từ chối với `ERR_3020` | **PASS** |
| 13 | Negative | `testValidateSessionMismatchFails` | Dùng token của phiên này cho phiên khác bị từ chối với `ERR_3020` | **PASS** |
| 14 | Negative | `testValidateRevokedTokenFails` | Dùng token đã bị thu hồi bị từ chối với `ERR_3020` | **PASS** |
| 15 | Negative | `testValidateClosedSessionFails` | Dùng token khi phiên đã CLOSED bị từ chối với `ERR_3002` | **PASS** |
| 16 | Check-In E2E | `testStudentCanCheckInWithValidStaticQr` | Sinh viên gửi đủ 5 tiêu chí (QR Static + Wi-Fi + Face) điểm danh thành công `PRESENT` | **PASS** |
| 17 | Check-In E2E | `testStudentCheckInWithWrongWifiRejected` | Dùng QR Static nhưng sai Wi-Fi BSSID bị từ chối với `ERR_3008` (Không bỏ qua Wi-Fi) | **PASS** |
| 18 | Check-In E2E | `testStudentCheckInWithoutEnrollmentRejected` | Dùng QR Static nhưng sinh viên chưa đăng ký lớp bị từ chối với `ERR_3004` | **PASS** |
| 19 | Dynamic Regress | `DynamicQrIntegrationTest` (20 tests) | 20 test case kiểm thử Dynamic QR gốc duy trì tỷ lệ vượt qua 100% | **PASS** |
| 20 | Frontend | `dynamic-qr.test.ts` (Tests 16, 17, 18) | Kiểm thử UI Toggle, Test Mode Contract, và Zero-LocalStorage trên Web | **PASS** |
| 21 | Frontend Build | `npm run build` (Vite + TypeScript) | Biên dịch toàn bộ Frontend thành công không có lỗi type | **PASS** |
| 22 | Mobile Unit | `QrPayloadModel.parse` (Static STQR) | Mobile bóc tách đúng `sessionId` và `token` từ chuỗi `STQR:...` | **PASS** |
| 23 | Mobile Unit | `QrPayloadModel.parse` (Dynamic JWT) | Mobile bóc tách đúng `sessionId` từ JWT Token xoay vòng | **PASS** |
| 24 | Mobile Unit | `QrPayloadModel.parse` (Garbage token) | Mobile phát hiện và từ chối chuỗi rác `isValid == false` | **PASS** |
| 25 | Mobile Regress | `flutter test` (92 tests) | 92 test case toàn diện ứng dụng Flutter vượt qua 100% | **PASS** |

> **Tổng kết**: **25/25 Nhóm Test Case ĐẠT (PASS)** | **0 FAIL** | **0 NOT VERIFIED**.

---

## 8. HƯỚNG DẪN TẮT TEST MODE TRÊN MÔI TRƯỜNG VẬN HÀNH

Để bảo đảm an toàn tuyệt đối khi triển khai lên máy chủ thật hoặc Staging/Production:

1. **Cách 1: Không kích hoạt profile test**:
   - Khi chạy Backend, sử dụng profile chuẩn:
     ```bash
     java -jar backend.jar --spring.profiles.active=prod
     ```
   - Trong `StaticTestQrServiceImpl.java`, hệ thống kiểm tra: Nếu `activeProfiles` chứa `prod` hoặc `production`, Static QR bị vô hiệu hóa cưỡng bức ngay cấp độ hạt nhân, bất chấp mọi biến môi trường khác.

2. **Cách 2: Đặt biến cấu hình tường minh**:
   - Trong `application.yml` (hoặc biến môi trường hệ thống):
     ```yaml
     unicheck:
       testing:
         static-qr:
           enabled: false
     ```
   - Hoặc biến môi trường:
     ```bash
     export UNICHECK_TESTING_STATIC_QR_ENABLED=false
     ```

---

## 9. BẰNG CHỨNG PRODUCTION HOÀN TOÀN KHÔNG SỬ DỤNG ĐƯỢC STATIC QR

Cơ chế phòng vệ chiều sâu (Defense-in-Depth) ngăn chặn Static QR trên Production gồm 4 tầng độc lập:

1. **Tầng 1 - Profile & Environment Guard**:
   ```java
   private void validateEnvironment() {
       boolean isProd = Arrays.stream(environment.getActiveProfiles())
               .anyMatch(p -> p.equalsIgnoreCase("prod") || p.equalsIgnoreCase("production"));
       if (isProd) {
           log.error("SECURITY ALERT: Static Test QR attempted on production profile");
           throw new AppException(ErrorCode.STATIC_QR_NOT_ALLOWED, "Chế độ Static Test QR bị vô hiệu hóa trên môi trường Production");
       }
       if (!staticQrEnabled) {
           throw new AppException(ErrorCode.STATIC_QR_NOT_ALLOWED, "Chế độ Static Test QR hiện đang bị tắt trong hệ thống");
       }
   }
   ```
2. **Tầng 2 - Whitelist Mã Lớp Cứng**:
   Ngay cả khi bật trong môi trường test, hệ thống chỉ chấp nhận duy nhất mã lớp `UNICHECK-E2E-01`. Mọi lớp học thật khác sẽ nhận lỗi `ERR_3025`.
3. **Tầng 3 - Frontend Hide Guard**:
   Lecturer Web gọi endpoint `/sessions/{id}/static-qr/status`. Khi backend phản hồi `allowed: false`, giao diện Web hoàn toàn ẩn lựa chọn `QR Test Cố Định`, không có nút bấm nào hiển thị cho người dùng.
4. **Tầng 4 - Unit Test Xác Minh Trực Tiếp**:
   Test case `StaticTestQrServiceUnitTest.testProductionProfileBlocksStaticQrIssuance` mô phỏng môi trường Production thực tế và xác nhận ngoại lệ bảo mật được kích hoạt khi có bất kỳ yêu cầu nào cố gắng phát hành Static QR.

---

## 10. HƯỚNG DẪN TỪNG BƯỚC ĐỂ TỰ KIỂM THỬ TRÊN MÁY TÍNH (STEP-BY-STEP E2E TEST GUIDE)

### Bước 1: Khởi động Backend với Profile Test
Mở PowerShell tại thư mục `backend`:
```powershell
mvn spring-boot:run -Dspring-boot.run.profiles=test
```
*(Backend sẽ lắng nghe tại cổng `http://localhost:8080`, nạp cơ sở dữ liệu mẫu và bật cờ `static-qr.enabled: true`)*

### Bước 2: Khởi động Lecturer Web
Mở PowerShell tại thư mục `frontend`:
```powershell
npm run dev
```
Truy cập trình duyệt: `http://localhost:5173`

### Bước 3: Giảng viên mở phiên điểm danh và chọn Static Test QR
1. Đăng nhập bằng tài khoản Giảng viên:
   - **Tên đăng nhập**: `gv_sonnt`
   - **Mật khẩu**: `Password@123`
2. Truy cập mục **Lịch giảng dạy** hoặc **Lớp học phần phụ trách** -> Chọn lớp **`UNICHECK-E2E-01`**.
3. Chọn ca học hiện tại và bấm **Bắt đầu phiên điểm danh**.
4. Trên màn hình trình chiếu QR (`SessionQrCodePage`):
   - Quan sát thấy thanh gạt chế độ: Chọn tab **`[ QR Test Cố Định ]`**.
   - Màn hình hiển thị nhãn cảnh báo vàng cam: `TEST MODE (DEVELOPMENT / TEST ONLY)`.
   - Mã QR đứng yên, không bị xoay vòng mỗi 10 giây.
   - Nhấn nút **`Sao chép Token Test`** (Token có dạng `STQR:<sessionId>:<hexToken>`).

### Bước 4: Khởi động Flutter trên Android Emulator
Mở PowerShell tại thư mục `mobile`:
```powershell
flutter run -d emulator-5554
```
*(Hoặc thiết bị Android Emulator đang chạy trên Windows)*

### Bước 5: Sinh viên thực hiện điểm danh bằng Token Test
1. Đăng nhập tài khoản Sinh viên:
   - **Tên đăng nhập**: `sv_he180002`
   - **Mật khẩu**: `Password@123`
2. Nhấn nút **Bắt đầu điểm danh** tại Dashboard hoặc chọn môn **IT301** (Lớp `UNICHECK-E2E-01`).
3. Ứng dụng chuyển sang màn hình **Quét mã QR**:
   - Nhấn nút **`Dán mã QR Test (Debug Emulator)`**.
   - Dán chuỗi `STQR:...` vừa sao chép từ Web Giảng viên vào ô nhập liệu.
   - Bấm **`Xác nhận QR`**.
4. Ứng dụng chuyển tiếp sang màn hình **Đối soát 5 tiêu chí** (`AttendanceEligibilityView`):
   - Tiêu chí 1: Mã QR phòng học -> **ĐẠT (PASS)** (Hiển thị ghi chú: *"Mã QR đã được máy chủ xác thực bảo mật"*).
   - Tiêu chí 2: Wi-Fi giảng đường -> **ĐẠT (PASS)**.
   - Tiêu chí 3: Khung giờ ca học -> **ĐẠT (PASS)**.
   - Tiêu chí 4: Trạng thái ghi danh -> **ĐẠT (PASS)**.
   - Tiêu chí 5: Face-ID hồ sơ -> **ĐẠT (PASS)**.
5. Tiến hành quét khuôn mặt Face-ID và Liveness.
6. Ứng dụng gửi yêu cầu check-in lên máy chủ Spring Boot.
7. Màn hình hiển thị chứng nhận điểm danh thành công với trạng thái **`PRESENT`** và mã biên nhận học vụ.
8. Trên màn hình Giảng viên (`SessionQrCodePage`), danh sách sinh viên tự động cập nhật sinh viên **Trần Bảo Long (`sv_he180002`)** đã có mặt!
