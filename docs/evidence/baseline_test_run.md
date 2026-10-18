# UNICHECK - BASELINE TEST EXECUTION EVIDENCE (TASK P00)
**Thời điểm thực thi**: 2026-10-13  
**Commit SHA**: `0ad5e70db2e03b4d67d9dabd06fb49aae0c08306`  
**Nhánh Git**: `develop`  
**Working tree status**: Clean

---

## 1. MÔI TRƯỜNG THỰC THI (ENVIRONMENT SPECIFICATIONS)

- **Hệ điều hành**: Microsoft Windows 11 Enterprise [Version 10.0.26300.9550], amd64
- **Java Runtime**: Oracle JDK 22.0.2 (build 22.0.2+9-70), Java(TM) SE Runtime Environment
- **Maven**: Apache Maven 3.9.11 (3e54c93a704957b63ee3494413a2b544fd3d825b)
- **Flutter Framework**: Flutter 3.47.3 on channel stable, Dart 3.13.3, DevTools 2.60.0
- **Android SDK**: Android SDK 37.0.0, build-tools 37.0.0
- **Docker**: Docker Compose v2 (Schema version syntax validated)
- **Python / Pytest**: Không có trên host PATH; môi trường thực thi được đóng gói bên trong Dockerfile của `ai-service`

---

## 2. NHẬT KÝ LỆNH VÀ KẾT QUẢ KIỂM THỬ THỰC TẾ

### 2.1. Backend Test Suite (Maven)
- **Thư mục chạy**: `C:\Users\Admin\Documents\Antigravity\UniCheck\backend`
- **Lệnh**: `mvn test`
- **Kết quả**: **PASS (30/30 tests)**
- **Thời gian**: 19.113s
- **Chi tiết test suites**:
  - `UniCheckApplicationTests`: 1 test run, 0 failures, 0 errors, 0 skipped.
  - `PostgresCleanDatabaseStartupTest`: 1 test run, 0 failures, 0 errors, 0 skipped.
  - `UserRepositoryTest`: 2 tests run, 0 failures, 0 errors, 0 skipped.
  - `AuthenticationIntegrationTest`: 14 tests run, 0 failures, 0 errors, 0 skipped (Login, Logout, Refresh, Profile, Change Password, Forgot Password OTP).
  - `UserManagementIntegrationTest`: 12 tests run, 0 failures, 0 errors, 0 skipped (Create, View, Update, Delete, Audit Logging, Pagination, Role & Status Filtering).

```
[INFO] Results:
[INFO] 
[INFO] Tests run: 30, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  19.113 s
```

---

### 2.2. Mobile App Static Analysis (Flutter)
- **Thư mục chạy**: `C:\Users\Admin\Documents\Antigravity\UniCheck\mobile`
- **Lệnh**: `flutter analyze`
- **Kết quả**: **PASS (0 errors, 0 warnings)**
- **Thời gian**: 11.6s

```
Analyzing mobile...                                             
No issues found! (ran in 11.6s)
```

---

### 2.3. Mobile App Smoke Test (Flutter)
- **Thư mục chạy**: `C:\Users\Admin\Documents\Antigravity\UniCheck\mobile`
- **Lệnh**: `flutter test`
- **Kết quả**: **PASS (1/1 tests)**

```
00:00 +0: loading C:/Users/Admin/Documents/Antigravity/UniCheck/mobile/test/widget_test.dart
00:00 +0: UniCheck Mobile app smoke test
00:00 +1: All tests passed!
```

---

### 2.4. Docker Compose Cấu hình
- **Thư mục chạy**: `C:\Users\Admin\Documents\Antigravity\UniCheck`
- **Lệnh**: `docker compose config`
- **Kết quả**: **PASS**
- **Dịch vụ được định nghĩa**:
  - `postgres`: image `postgres:15-alpine`, port 5432, volume `postgres_data`
  - `redis`: image `redis:7-alpine`, port 6379, volume `redis_data`
  - `backend`: Dockerfile context `backend`, port 8080, depends_on postgres & redis (healthy)
  - `ai-service`: Dockerfile context `ai-service`, port 5000

---

### 2.5. AI Microservice Test (Pytest)
- **Lệnh**: `pytest`
- **Kết quả**: **NOT RUN**
- **Lý do**: Máy host Windows không có môi trường Python/pytest toàn cục. Bộ kiểm thử được cấu hình chạy trong container Docker `unicheck_ai_service`.

---

## 3. CHECKLIST TỔNG HỢP KIỂM CHỨNG BASELINE

| Tiêu chí | Trạng thái | Ghi chú |
| :--- | :---: | :--- |
| Không sửa đổi bất kỳ file nguồn logic nào | **PASS** | `git status` sạch, chỉ thêm 2 file tài liệu trong `docs/` |
| Bảng kiểm kê 50 bảng CSDL Flyway | **PASS** | Đã xác minh từng dòng trong V1, V2, V3 |
| Kiểm kê 10 JPA Entities & Repositories | **PASS** | Đã đối chiếu 1-1 với miền User & Security |
| Xác nhận trạng thái Mock của AI Service | **PASS** | Vector 128 số 0 và liveness boolean 96% |
| Xác nhận trạng thái Mock của Mobile Check-in | **PASS** | Snackbar fake 99.2% trong `face_checkin_view.dart` |
| Kết quả kiểm thử tự động thực tế | **PASS** | 30 test Java pass, 1 test Flutter pass, analyze pass |
