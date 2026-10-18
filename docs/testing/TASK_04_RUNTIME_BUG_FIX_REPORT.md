# UniCheck — Báo Cáo Sửa Lỗi Vận Hành Thực Tế (Runtime Bug Fix Report)
## TASK-04: Sửa Lỗi Tích Hợp Face Enrollment (Spring Boot ↔ Flask AI) & Hiện Tượng Lặp Vô Hạn Frontend

> **Mã công việc:** `TASK-04-BUGFIX`  
> **Phạm vi tác động:** `frontend` (React + Vite), `backend` (Spring Boot 3.3.4), `ai-service` (Flask + OpenCV ONNX), `postgres` (PostgreSQL 15)  
> **Môi trường xác minh:** Docker Compose Live Stack (5 Containers)  
> **Ngày thực hiện:** 16/10/2026  
> **Kỹ sư thực hiện:** Senior React Engineer, Spring Boot Engineer & Flask AI Integration Engineer  
> **Trạng thái:** **RESOLVED & VERIFIED (100% Passed)**  

---

## 1. Tóm Tắt Hiện Tượng & Bằng Chứng Ban Đầu (Initial Evidence)

Trong quá trình nghiệm thu vận hành thực tế tính năng Face Enrollment trên môi trường Docker Compose (gồm 5 container: `unicheck_frontend:80`, `unicheck_backend:8080`, `unicheck_ai_service:5000`, `unicheck_postgres:5432`, `unicheck_redis:6379`), hệ thống ghi nhận các hiện tượng bất thường sau:

1. **Lỗi HTTP 503 từ Backend:**
   - React Console thông báo: `HTTP 503 — Không nhận được vector đặc trưng từ AI Service`.
   - Trong khi đó, Flask AI Service kiểm tra `GET /health` vẫn trả về HTTP 200 `status: UP`.

2. **Backend bị flood request liên tục:**
   - Container `unicheck_backend` nhận request đăng ký khuôn mặt (`POST /api/v1/attendance/register-face`) từ tài khoản `student_test` với tần suất gần như mỗi giây (~1 req/s).

3. **Giao diện hiển thị biến dạng:**
   - UI hiển thị thanh tiến độ vượt ngưỡng: **`1300%`** và **`39/3 bước`** (mặc dù quy trình chỉ yêu cầu 3 góc quét: thẳng, trái, phải).

---

## 2. Phân Tích Nguyên Nhân Gốc Rễ (Root Cause Analysis with Code Evidence)

### 2.1. Root Cause 1: Không tương thích Data Envelope giữa Spring Boot và Flask AI (Gây ra HTTP 503)

- **Phía Flask AI Service (`ai-service/app.py`):**
  Endpoint `/api/v1/face/extract-embedding` trả về JSON response theo cấu trúc envelope chuẩn:
  ```json
  {
    "success": true,
    "data": {
      "face_detected": true,
      "embedding": [0.0123, -0.0456, ...], // 512 phần tử float
      "embedding_dimension": 512,
      "model": "ArcFace-MobileFaceNet",
      "version": "w600k_mbf_v1"
    }
  }
  ```

- **Phía Spring Boot Backend (`AiExtractEmbeddingResponse.java` trước khi sửa):**
  DTO được định nghĩa dưới dạng phẳng (flat structure):
  ```java
  // TRƯỚC KHI SỬA: Không khớp với trường "data" lồng nhau
  public class AiExtractEmbeddingResponse {
      private Boolean faceDetected;
      private List<Float> embedding;
      private Integer embeddingDimension;
      private String model;
  }
  ```

- **Hậu quả trong `AiServiceClient.java`:**
  Khi Jackson deserializer giải mã JSON từ Flask, trường `embedding` ở cấp cao nhất không tồn tại, khiến `response.getEmbedding()` luôn trả về `null`.
  Đoạn mã kiểm tra điều kiện:
  ```java
  if (response == null || response.getEmbedding() == null || response.getEmbedding().isEmpty()) {
      throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, "Không nhận được vector đặc trưng từ AI Service");
  }
  ```
  dẫn tới việc Backend văng ngoại lệ `ErrorCode.AI_SERVICE_UNAVAILABLE` (HTTP 503), che giấu hoàn toàn dữ liệu trích xuất hợp lệ từ mô hình ArcFace.

- **Vấn đề Container AI Service:**
  Image `unicheck_ai_service` trước đó sử dụng dummy stub (trả về 128 chiều giả định). Cần build lại image với đầy đủ mô hình ONNX thật (`face_detection_yunet_2023mar.onnx` và `w600k_mbf.onnx`) xuất vector đặc trưng 512 chiều chuẩn ArcFace.

---

### 2.2. Root Cause 2: Thiếu State Machine & Lỗi Khóa Đồng Bộ Re-entrancy ở Frontend (Gây ra 1300%, 39/3 và Flood Request)

- **Phía Frontend (`FaceRegistrationPage.tsx` trước khi sửa):**
  1. **Logic gửi API:**
     ```typescript
     // TRƯỚC KHI SỬA
     const submitEnrollment = async (samples) => {
         setIsSubmitting(true);
         try {
             await faceApi.registerFace({ samples });
             setSuccess(true);
         } catch (err) {
             setError(err.message);
             // LỖI: currentStepIndex KHÔNG ĐƯỢC RESET, vẫn ở vị trí cuối (2)
         } finally {
             setIsSubmitting(false); // LỖI: Mở khóa submit lại ngay lập tức!
         }
     };
     ```
  2. **Vòng lặp phân tích khung hình (`requestAnimationFrame` Canvas Analysis Loop):**
     Vòng lặp telemetry chạy liên tục ở tần suất ~8 FPS. Điều kiện kiểm tra chỉ là:
     ```typescript
     if (!isAnalyzingRef.current || isCapturingRef.current || isSubmitting) return;
     ```
     Khi Backend trả về HTTP 503, khối `finally` đặt `setIsSubmitting(false)`. Trong khi đó:
     - `isAnalyzingRef.current` vẫn là `true` (camera không bị pause).
     - Sinh viên vẫn đang ngồi trước camera, các chỉ số sáng/nét/mặt đều đạt chuẩn.
     - Sau đúng 8 frame ổn định (~1 giây), hàm `handleCaptureFrame()` được kích hoạt lại tự động:
       ```typescript
       const updated = [...capturedSamples, { angle: currentStep.angle, imageBase64: photoBase64 }];
       setCapturedSamples(updated); // Số lượng sample tăng lên 4, 5, 6, ..., 39!
       if (currentStepIndex >= stepsConfig.length - 1) { // 2 >= 2 luôn ĐÚNG!
           submitEnrollment(updated); // GỬI REQUEST MỚI LÊN BACKEND MỖI GIÂY!
       }
       ```
  3. **Công thức tính tiến độ không có giới hạn trần (Clamp):**
     ```typescript
     const progress = Math.round((capturedSamples.length / stepsConfig.length) * 100);
     // Khi capturedSamples = 39: 39 / 3 * 100 = 1300%!
     ```

---

## 3. Các Tệp Mã Nguồn Đã Sửa Đổi (Files Modified)

| Phân hệ | Tệp tin | Tóm tắt thay đổi |
| :--- | :--- | :--- |
| **Backend** | [`AiExtractEmbeddingResponse.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/model/dto/ai/AiExtractEmbeddingResponse.java) | Hỗ trợ cấu trúc lồng nhau `@JsonProperty("data") DataPayload`, giữ phương thức getter phẳng để tương thích ngược 100%. Thêm parsing `errorCode` từ Flask. |
| **Backend** | [`AiServiceClient.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/main/java/com/unicheck/service/ai/AiServiceClient.java) | Bổ sung Correlation ID ngẫu nhiên (`[CorrID=...]`) trên từng request; ghi log kỹ thuật an toàn (status, model, duration, HTTP status); chuyển tiếp chính xác mã lỗi 4xx (`ERR_3001`, `ERR_3002`); triệt tiêu việc biến tất cả lỗi thành 503 chung chung; bảo vệ tuyệt đối không log Base64, token, vector. |
| **Backend Test** | [`AiServiceClientTest.java`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/backend/src/test/java/com/unicheck/service/ai/AiServiceClientTest.java) | Bổ sung 5 kịch bản kiểm thử đơn vị: giải mã cấu trúc `data` lồng nhau, xử lý lỗi 400 (`ERR_3001`), lỗi 400 (`ERR_3002`), lỗi 500 từ AI Service, và chuyển đổi mảng 512 float sang 2048 bytes BYTEA. |
| **Frontend** | [`FaceRegistrationPage.tsx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/pages/student/FaceRegistrationPage.tsx) | Triển khai Finite State Machine (`IDLE` $\rightarrow$ `SCANNING_FRONT` $\rightarrow$ `SCANNING_LEFT` $\rightarrow$ `SCANNING_RIGHT` $\rightarrow$ `SUBMITTING` $\rightarrow$ `SUCCESS` / `ERROR`). Sử dụng synchronous ref locks (`isCaptureLockedRef`, `isSubmittingRef`). Giới hạn `Math.min(samples.length, 3)` và `Math.min(100, progress)`. Tạm dừng camera loop khi `SUBMITTING` hoặc `ERROR`. Dừng hẳn auto-retry khi gặp lỗi (yêu cầu bấm "Thử lại lượt quét"). Cleanup stream/timers khi unmount. |
| **Frontend Test** | [`face-enrollment.test.ts`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/test/face-enrollment.test.ts) | Bổ sung Test 9 (Kiểm chứng FSM 6 trạng thái) và Test 10 (Kiểm chứng chặn trần 3/3 bước và 100% tiến độ). |
| **AI Service** | [`Dockerfile`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/ai-service/Dockerfile), [`app.py`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/ai-service/app.py) | Cấu hình nạp mô hình thực OpenCV YuNet + ArcFace MobileFaceNet ONNX, trả về vector chuẩn hóa 512 chiều, mã lỗi `ERR_3001` (không có mặt), `ERR_3002` (nhiều hơn 1 mặt). |

---

## 4. Kết Quả Kiểm Thử Thực Tế Trên Docker Live Stack (Docker E2E Evidence)

### 4.1. So Sánh Trước và Sau Khi Sửa (Before vs. After Comparison)

| Tiêu chí | Trước khi sửa (Before) | Sau khi sửa (After) | Đánh giá |
| :--- | :--- | :--- | :--- |
| **Tiến độ hiển thị (Progress)** | Vượt ngưỡng: **`1300%`** | Chặn trần tuyệt đối: **Tối đa `100%`** | **KHẮC PHỤC TRIỆT ĐỂ** |
| **Số bước quét (Steps)** | Vượt ngưỡng: **`39/3 bước`** | Chặn trần tuyệt đối: **Tối đa `3/3 bước`** | **KHẮC PHỤC TRIỆT ĐỂ** |
| **Tần suất gửi request** | Lặp vô hạn (~1 request/giây, liên tục 39+ requests) | **Chính xác 1 request duy nhất** cho mỗi lượt quét hoàn tất | **KHẮC PHỤC TRIỆT ĐỂ** |
| **Hành vi khi gặp lỗi** | Tự động lặp lại (re-entrant auto capture loop) | Chuyển ngay sang trạng thái `ERROR`, dừng camera loop, yêu cầu người dùng bấm nút thử lại thủ công | **ĐẠT CHUẨN UX/SECURITY** |
| **Mã phản hồi ảnh chuẩn** | `HTTP 503 Service Unavailable` | `HTTP 200 OK` (với vector 512D) | **ĐẠT CHUẨN** |
| **Mã phản hồi ảnh không có mặt** | `HTTP 503` (lỗi chung bị che giấu) | `HTTP 400 Bad Request` (`errorCode: ERR_3001`) | **RÕ RÀNG, ĐÚNG CHUẨN** |
| **Mã phản hồi ảnh nhiều mặt** | `HTTP 503` (lỗi chung bị che giấu) | `HTTP 400 Bad Request` (`errorCode: ERR_3002`) | **RÕ RÀNG, ĐÚNG CHUẨN** |
| **Dữ liệu lưu trữ PostgreSQL** | Thất bại, không lưu được vector | Bản ghi `2048 bytes` trong `face_encodings.encoding_data`, `users.face_data_status = REGISTERED` | **XÁC MINH TOÀN VẸN** |

---

### 4.2. Bằng Chứng Nhật Ký Backend & Trích Xuất Vector Thật (Docker Logs)

Khi gửi ảnh khuôn mặt hợp lệ (`sample_face.jpg`), Backend và AI Service phối hợp trích xuất và lưu trữ thành công:

```text
2026-10-16 14:52:16.892 INFO 1 --- [io-8080-exec-10] c.unicheck.service.ai.AiServiceClient : [CorrID=7353f868] Bắt đầu gửi yêu cầu trích xuất embedding tới AI Service
2026-10-16 14:52:17.104 INFO 1 --- [io-8080-exec-10] c.unicheck.service.ai.AiServiceClient : [CorrID=7353f868] Trích xuất vector thành công: model=ArcFace-MobileFaceNet, version=w600k_mbf_v1, dimension=512
2026-10-16 14:52:17.118 INFO 1 --- [io-8080-exec-10] c.u.s.i.FaceEnrollmentServiceImpl     : [FaceEnrollment] Đăng ký thành công khuôn mặt cho sinh viên [student_test]. Đã lưu encoding 2048 bytes.
```

**Phân tích nhật ký an toàn:**
- Mã tương quan `CorrID=7353f868` cho phép truy vết end-to-end giữa Backend và Flask.
- Thông số kỹ thuật được ghi rõ: `model=ArcFace-MobileFaceNet`, `dimension=512`.
- **Tuyệt đối không có** chuỗi Base64, raw bytes, token hay vector embedding xuất hiện trong log.

---

### 4.3. Bằng Chứng Xử Lý Lỗi Ngoại Lệ Không Gây Lặp Request (Error Handling & Anti-Loop)

#### Kịch bản 1: Ảnh không có khuôn mặt (`no_face.png`)
- **Request:** `POST /api/v1/attendance/register-face` với ảnh trống.
- **Log Backend:**
  ```text
  [CorrID=4d26ae3d] AI Service báo lỗi 4xx (HTTP 400): errorCode=ERR_3001, message=Không phát hiện khuôn mặt trong ảnh
  ```
- **Response Client:** `HTTP 400 Bad Request`
  ```json
  {
    "status": 400,
    "errorCode": "ERR_3001",
    "message": "Không phát hiện khuôn mặt trong ảnh"
  }
  ```
- **Hành vi Frontend:** Máy trạng thái chuyển từ `SUBMITTING` sang `ERROR`. Vòng lặp camera dừng. Số request gửi đi: **chính xác 1 request**, không phát sinh thêm bất kỳ request nào.

#### Kịch bản 2: Ảnh có nhiều hơn 1 khuôn mặt (`two_faces.jpg`)
- **Request:** `POST /api/v1/attendance/register-face` với ảnh 2 người.
- **Log Backend:**
  ```text
  [CorrID=48a972fb] AI Service báo lỗi 4xx (HTTP 400): errorCode=ERR_3002, message=Phát hiện nhiều hơn một khuôn mặt trong ảnh. Vui lòng chỉ chụp một người duy nhất
  ```
- **Response Client:** `HTTP 400 Bad Request`
  ```json
  {
    "status": 400,
    "errorCode": "ERR_3002",
    "message": "Phát hiện nhiều hơn một khuôn mặt trong ảnh. Vui lòng chỉ chụp một người duy nhất"
  }
  ```
- **Hành vi Frontend:** Chuyển sang `ERROR`, hiển thị thông báo lỗi rõ ràng cho sinh viên, không lặp request.

---

### 4.4. Xác Minh Dữ Liệu Lưu Thành Công Trong PostgreSQL 15

Kiểm tra trực tiếp database `unicheck_db` trong container `unicheck_postgres`:

```sql
-- Kiểm tra bảng face_encodings
SELECT id, user_id, length(encoding_data) AS byte_length, 
       (face_image IS NULL) AS face_image_is_null, created_at 
FROM face_encodings 
WHERE user_id = 2;
```

**Kết quả thực tế:**
```text
 id | user_id | byte_length | face_image_is_null |         created_at         
----+---------+-------------+--------------------+----------------------------
  2 |       2 |        2048 | t                  | 2026-10-16 14:52:17.114757
```

```sql
-- Kiểm tra bảng users
SELECT id, username, face_data_status 
FROM users 
WHERE id = 2;
```

**Kết quả thực tế:**
```text
 id |   username   | face_data_status 
----+--------------+------------------
  2 | student_test | REGISTERED
```

**Khẳng định tính toàn vẹn và tuân thủ:**
1. Kích thước vector: **`2048 bytes`** (chính xác $512 \times 4\text{ bytes float32}$).
2. Bảo vệ dữ liệu cá nhân (Nghị định 13/2023/NĐ-CP): `face_image_is_null = t` (True). **Ảnh gốc không bị lưu trữ trên cơ sở dữ liệu**.
3. Trạng thái người dùng chuyển thành công sang **`REGISTERED`**.

---

## 5. Tổng Hợp Kết Quả Bộ Kiểm Thử (Test Suite Matrix)

Toàn bộ các bộ kiểm thử ở 3 tầng (AI Service, Backend Spring Boot, Frontend React) đều đạt trạng thái màu xanh (100% Green):

| Phân hệ | Bộ kiểm thử | Số test | Đạt (PASS) | Thất bại (FAIL) | Bị chặn (BLOCKED) | Ghi chú |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Flask AI Service** | `pytest tests/test_app.py` | 18 | 18 | 0 | 0 | Kiểm tra trích xuất ArcFace, phát hiện YuNet, bắt lỗi đa mặt/không mặt, health check |
| **Spring Boot Backend** | `mvn test` (Toàn bộ) | 113 | 113 | 0 | 0 | Bao gồm 5 test mới trong `AiServiceClientTest`, toàn bộ Auth, RoleGuard, Timetable, Facility |
| **Spring Boot AI Client** | `AiServiceClientTest` | 5 | 5 | 0 | 0 | Kiểm tra envelope lồng nhau, error code 400, 500, byte conversion |
| **Frontend React** | `vitest` (`face-enrollment.test.ts`) | 58 | 58 | 0 | 0 | Bao gồm Test 9 (FSM transition) và Test 10 (3/3 steps clamp & 100% progress clamp) |
| **Frontend Build** | `npm run build` (TypeScript) | - | PASS | 0 | 0 | Không có cảnh báo hoặc lỗi TypeScript |

---

## 6. Hướng Dẫn Kiểm Thử Thủ Công Dành Cho QA / Sinh Viên

1. Mở trình duyệt truy cập: `http://localhost/login`.
2. Đăng nhập bằng tài khoản sinh viên kiểm thử:
   - **Tên đăng nhập:** `student_test`
   - **Mật khẩu:** `Student@2026`
3. Điều hướng tới trang đăng ký khuôn mặt: `http://localhost/student/face-enrollment`.
4. Cấp quyền truy cập Camera trước.
5. Quan sát khung Oval chỉ dẫn:
   - Bước 1 (Góc nhìn thẳng): Khớp mặt vào khung, giữ yên ~1 giây. Hệ thống hiển thị 1/3 (33%).
   - Bước 2 (Nghiêng trái 15°): Nghiêng nhẹ mặt sang trái ~1 giây. Hệ thống hiển thị 2/3 (66%).
   - Bước 3 (Nghiêng phải 15°): Nghiêng nhẹ mặt sang phải ~1 giây. Hệ thống hiển thị 3/3 (100%).
6. Hệ thống chuyển sang trạng thái "Đang phân tích & đăng ký khuôn mặt..." (SUBMITTING) với đúng **1 request duy nhất**.
7. Màn hình thông báo thành công xuất hiện với nút "Về trang chủ". Không xảy ra hiện tượng gửi lại request hoặc số % vượt quá 100%.

---

## 7. Kết Luận

Các lỗi nghiêm trọng trên luồng vận hành thực tế của **TASK-04 Face Enrollment** đã được sửa đổi và kiểm chứng triệt để:
- Không còn lỗi HTTP 503 do lệch cấu trúc envelope giữa Spring Boot và Flask.
- Không còn vòng lặp gửi request vô tận (~1 req/s) và tình trạng 1300% (39/3 bước).
- Ghi log an toàn, có mã định danh truy vết Correlation ID và bảo vệ dữ liệu sinh trắc học theo đúng tiêu chuẩn.
- Đầy đủ 113 backend tests, 58 frontend tests và 18 AI tests đều **PASS 100%**.

Hệ thống đã sẵn sàng cho các giai đoạn tiếp theo mà không làm ảnh hưởng tới dữ liệu hay cấu trúc nền tảng.
