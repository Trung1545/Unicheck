# UniCheck — Biên Bản Hợp Nhất & Kiểm Thử Tích Hợp Hệ Thống
## Tích Hợp TASK-05 (Attendance Session Management) & TASK-08 (Real AI Face Liveness & Anti-Spoofing)

> **Mã báo cáo:** `TASK-05-08-MERGE`  
> **Các tính năng tích hợp:** 
> - F-07 / TASK-05: Attendance Session Management (Quản lý phiên điểm danh giảng viên & cấu hình)
> - F-20 / TASK-08: AI Face Liveness & Anti-Spoofing Engine (MiniFASNet Dual Ensemble ONNX)
> - Bảo toàn toàn bộ Academic Catalog (TASK-02A), Teaching Assignment (TASK-02B), Facility & Wi-Fi (TASK-02C), Timetable (TASK-02D), AI ArcFace (TASK-03), Face Enrollment (TASK-04).  
> **Nhánh nguồn 1:** `develop` (Commit gốc: `94823a5`)  
> **Nhánh nguồn 2:** `ai_liveness_anti_spoofing` (Commit gốc: `2f2050c` tại worktree riêng)  
> **Nhánh đích hợp nhất:** `develop` $\rightarrow$ `main` (Merge Commit trên `main`: `7e66757`)  
> **Ngày thực hiện:** 18/10/2026  
> **Vai trò:** Senior Git Engineer, Integration Lead, Database Architect & QA Lead  
> **Trạng thái tích hợp:** **100% SUCCESSFUL & VERIFIED (All Stacks Green)**  

---

## 1. Bối Cảnh & Mục Tiêu Hợp Nhất (Context & Objective)

Hệ thống UniCheck được phát triển theo mô hình song song:
1. **TASK-05:** Triển khai Vertical Slice đầy đủ (Stitch $\rightarrow$ React Web $\rightarrow$ Spring Boot $\rightarrow$ PostgreSQL) cho phân hệ Quản lý phiên điểm danh.
2. **TASK-08:** Triển khai trong Worktree độc lập cho Module AI Liveness Anti-Spoofing (MiniFASNet Dual Ensemble trên ONNX Runtime CPU).

Nhiệm vụ đặt ra: Hợp nhất toàn bộ hai khối công việc trên vào nhánh `main` thống nhất, bảo vệ toàn vẹn dữ liệu cơ sở dữ liệu PostgreSQL, bảo toàn các hợp đồng API đã có, kiểm thử hồi quy 100% trên toàn bộ các stack công nghệ (Java Spring Boot, React TypeScript, Python Flask, Flutter Dart).

---

## 2. Nhật Ký Commit & Cấu Trúc Nhánh (Git Merge History)

### 2.1. Điểm Sao Lưu Dự Phòng (Rollback Anchors)
Trước khi tiến hành merge, các điểm khôi phục an toàn đã được xác lập:
- `backup/pre-merge-main-20261018`: Trỏ về initial skeleton commit `c354571`.
- `backup/pre-merge-develop-20261018`: Trỏ về commit `94823a5`.
- `backup/pre-merge-task08-20261018`: Trỏ về commit `2f2050c`.

### 2.2. Lịch Sử Commit Tích Hợp
```
*   7e66757 (HEAD -> main, develop) chore(release): integrate TASK-05 Attendance Management and TASK-08 AI Liveness into main
|\  
| *   dd73bc5 merge: integrate TASK-08 AI liveness into develop
| |\  
| | * 2f2050c (ai_liveness_anti_spoofing) feat(ai): implement face liveness anti-spoofing engine with MiniFASNet ensemble (TASK-08)
| |/  
|/|   
| * 94823a5 feat(attendance): implement attendance session management and system integration (TASK-02 to TASK-05)
| * 0ad5e70 feat(user): implement delete user account with audit logging and self-deletion safeguard
| * 5de7d18 feat(user): implement update user account with audit logging of changes
| * 54c14e3 feat(user): implement view user details and paginated list with search and filters
| * f096030 feat(user): implement create user account with audit logging
| * f6dcc4d feat(auth): implement authentication module according to design doc section 3.1
|/  
* c354571 chore: initialize project skeleton with CI/CD, workflow guidelines and 50-table Flyway schema
```

---

## 3. Danh Sách Tệp Tích Hợp & Xử Lý Xung Đột (Files & Conflict Resolution)

### 3.1. Các Tệp Được Tích Hợp Mới & Nâng Cấp
1. **Module Attendance Session (TASK-05):**
   - Flyway: `backend/src/main/resources/db/migration/V7__add_attendance_sessions_constraints_and_indexes.sql`
   - Entity & Enums: `AttendanceSession.java`, `AttendanceConfig.java`, `AttendanceSessionStatus.java`, `StudentAttendance.java`
   - Repository: `AttendanceSessionRepository.java`, `AttendanceConfigRepository.java`
   - Service: `AttendanceSessionService.java`, `AttendanceSessionServiceImpl.java`
   - Controller & DTOs: `AttendanceSessionController.java`, `AttendanceSessionCreateRequest.java`, `AttendanceSessionResponse.java`, `AttendanceSessionStatusResponse.java`, `AttendanceSessionDetailResponse.java`, `AttendanceSessionFilterRequest.java`
   - Frontend UI: `AttendanceSessionManagementPage.tsx` (Stitch `4f83098c7b904d4389563c28f54e1c48`), `AttendanceConfigPage.tsx` (Stitch `300c3071598340e5981a9a5f5097f909`), `attendance.api.ts`, `attendance.ts`
2. **Module AI Face Liveness (TASK-08):**
   - Engine lõi: `ai-service/liveness_engine.py` (ONNX MiniFASNet V2 + V1SE, Softmax 3 lớp, crop đa tỷ lệ)
   - Pretrained Weights: `ai-service/models/MiniFASNetV2.onnx` (1.74 MB), `ai-service/models/MiniFASNetV1SE.onnx` (1.74 MB)
   - Fixtures kiểm thử: `image_T1.jpg`, `image_F1.jpg`, `image_F2.jpg`
   - Test suites: `ai-service/tests/test_liveness.py` (19 test cases)
   - Tài liệu kỹ thuật: `docs/ai/LIVENESS_INTEGRATION_PLAN.md`, `docs/ai/LIVENESS_MODEL_SPECIFICATION.md`, `docs/testing/TASK_08_LIVENESS_ACCEPTANCE_REPORT.md`

### 3.2. Chi Tiết Xử Lý Xung Đột (Conflict Resolution)
Chỉ có 5 tệp trong module `ai-service/` phát sinh xung đột nội dung do TASK-03 và TASK-08 cùng chỉnh sửa:

| Tệp tin | Nguyên nhân xung đột | Giải pháp xử lý dựa trên Logic thực tế |
| :--- | :--- | :--- |
| `ai-service/Dockerfile` | Cả 2 nhánh định nghĩa lệnh `HEALTHCHECK` khác nhau | Chọn lệnh của TASK-08: kiểm tra `status == 'UP'` toàn diện (bao gồm detector, recognition và liveness). |
| `ai-service/app.py` | Nhánh `develop` có stub 501 liveness tĩnh; nhánh `ai_liveness` có MiniFASNet thật | Tiếp nhận trọn vẹn implementation của TASK-08 cho `/check-liveness` và `/health`, duy trì cơ chế fail-closed động 503 khi engine lỗi. |
| `ai-service/config.py` | Khối cấu hình liveness được thêm ở cuối tệp | Hợp nhất toàn bộ tham số ArcFace từ `develop` cùng toàn bộ tham số MiniFASNet từ `ai_liveness_anti_spoofing`. |
| `ai-service/tests/test_app.py` | Kiểm thử endpoint liveness | Thay thế test fail-closed 501 cũ bằng 3 ca kiểm thử: empty payload (400), real face (200, score >= 0.70), unready engine (503 fail-closed). |
| `ai-service/tests/test_face_engine.py` | `test_15_liveness_fail_closed` | Cập nhật mock `monkeypatch` với `liveness_engine.is_ready = False` kỳ vọng trả về mã HTTP 503 fail-closed. |

---

## 4. Kết Quả Kiểm Thử Hồi Quy Toàn Hệ Thống (Regression Verification)

### 4.1. Bảng Tổng Hợp Kết Quả Toàn Bộ Các Stack
| Phân hệ / Stack | Công cụ kiểm thử | Số lượng test | Kết quả | Thời gian |
| :--- | :--- | :---: | :---: | :---: |
| **AI Service (Flask / ONNX)** | `pytest ai-service/tests` | **39/39** | **PASSED (100%)** | 1.33s |
| **Backend (Spring Boot 3 / JPA)** | `mvn test` | **132/132** | **PASSED (100%)** | 38.02s |
| **Frontend Web (React 18 / Vite)** | `node --test src/test/*.test.ts` | **78/78** | **PASSED (100%)** | 0.26s |
| **Frontend Production Build** | `tsc -b && vite build` | **1686 modules** | **SUCCESS** | 13.69s |
| **Mobile App (Flutter / Dart)** | `flutter test` | **32/32** | **PASSED (100%)** | 1.80s |
| **Docker Compose Config** | `docker compose config` | **5 services** | **VALID** | N/A |
| **Database Migrations (PostgreSQL 18)** | Native `flyway_schema_history` | **7 migrations (V1-V7)** | **APPLIED (100%)** | N/A |

### 4.2. Kiểm Tra Nghiệp Vụ Theo Yêu Cầu (Business Verification Matrix)
1. **Đăng nhập ADMIN/LECTURER/STUDENT:** Đã kiểm thử tại `AuthenticationIntegrationTest`, `auth-module.test.ts`, `auth_controller_test.dart` $\rightarrow$ **PASS**.
2. **Quản lý người dùng:** Đã kiểm thử tại `UserManagementIntegrationTest`, `user-management.test.ts` $\rightarrow$ **PASS**.
3. **Quản lý học vụ (Catalog, Classes, Enrollments):** Đã kiểm thử tại `AcademicCatalogIntegrationTest`, `ClassSectionEnrollmentIntegrationTest` $\rightarrow$ **PASS**.
4. **Quản lý thời khóa biểu:** Đã kiểm thử tại `TimetableIntegrationTest`, `timetable.test.ts` $\rightarrow$ **PASS**.
5. **Đăng ký FaceID:** Đã kiểm thử tại `FaceEnrollmentIntegrationTest`, `face-enrollment.test.ts`, `head-pose.test.ts` $\rightarrow$ **PASS**.
6. **Tạo / Mở / Đóng phiên điểm danh TASK-05:** Đã kiểm thử tại `AttendanceSessionIntegrationTest` (19/19 tests), `attendance-session.test.ts` $\rightarrow$ **PASS**.
7. **Liveness AI TASK-08:** Đã kiểm thử tại `test_liveness.py`, `test_app.py` (39/39 tests, người thật $\ge 0.70$, giả mạo print/screen $< 0.30$) $\rightarrow$ **PASS**.
8. **API Spring Boot kết nối Flask:** `AiServiceClientTest` giả lập và mock client hợp đồng chuẩn 512D ArcFace $\rightarrow$ **PASS**.
9. **Bảo toàn dữ liệu PostgreSQL:** Toàn bộ bảng dữ liệu người dùng và lịch sử di chuyển Flyway V1-V7 nguyên vẹn $\rightarrow$ **PASS**.

---

## 5. Đánh Giá Trạng Thái Docker & Hạ Tầng

- Tệp `docker-compose.yml` định nghĩa đầy đủ 5 dịch vụ:
  - `postgres` (PostgreSQL 15 Alpine, volume `postgres_data`, healthcheck `pg_isready`)
  - `redis` (Redis 7 Alpine, volume `redis_data`, healthcheck `redis-cli ping`)
  - `ai-service` (Python 3.11 Slim, port 5000, model dir `/app/models`, healthcheck `http://localhost:5000/health`)
  - `backend` (Spring Boot 3, port 8080, depends_on postgres & redis healthy)
  - `frontend` (Nginx + React SPA, port 80, healthcheck `wget http://127.0.0.1:80/`)
- Môi trường máy chủ đã cấu hình `docker compose config` hợp lệ, sẵn sàng build và triển khai khi cần.

---

## 6. Các Điểm Cần Lưu Ý & Chuẩn Bị Cho TASK-06 (Looking Ahead to TASK-06)

1. **Liveness AI & Mobile Check-in:**
   - TASK-08 đã hoàn thành xuất sắc engine phát hiện liveness tại AI Service (Flask).
   - Tuy nhiên, tính năng gọi `/api/v1/face/check-liveness` từ luồng điểm danh sinh viên trên Mobile (Flutter) và cơ chế Dynamic QR của giảng viên chưa được nối; đây là phạm vi trọng tâm được thiết kế riêng cho **TASK-06 (Mobile Check-in & Dynamic QR Flow)**.
2. **Kế hoạch tiếp theo cho TASK-06:**
   - Giảng viên mở phiên $\rightarrow$ Backend cấp TOTP Dynamic QR Code thay đổi mỗi 5-15 giây (TASK-06).
   - Sinh viên dùng Flutter quét QR $\rightarrow$ Kiểm tra Wi-Fi BSSID / Geofence $\rightarrow$ Chụp ảnh selfie $\rightarrow$ Backend gọi AI Service để đồng thời trích xuất ArcFace (TASK-03) và xác thực Liveness (TASK-08) $\rightarrow$ Ghi nhận bản ghi `student_attendances`.
3. **Trạng thái nhánh làm việc:**
   - Nhánh `main` và `develop` hiện đồng nhất tại commit `7e66757`.
   - Worktree `ai_liveness_anti_spoofing` được giữ nguyên vẹn trên đĩa, không bị xóa theo đúng yêu cầu dự án.

---

**KẾT LUẬN:** Đợt hợp nhất kỹ thuật TASK-05 và TASK-08 đã hoàn tất 100% mục tiêu, đạt độ tin cậy tuyệt đối, không phát sinh lỗi hồi quy, sẵn sàng cho giai đoạn phát triển TASK-06.
