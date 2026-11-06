# UniCheck — Biên Bản Nghiệm Thu Kỹ Thuật (Acceptance Report)
## TASK-08: Real AI Face Liveness & Anti-Spoofing Engine (Pipeline Chống Giả Mạo Khuôn Mặt Thực Tế)

> **Mã công việc:** `TASK-08`  
> **Tính năng nghiệm thu:** F-20 (Face Anti-Spoofing & Liveness Detection)  
> **Phương pháp triển khai:** Real Computer Vision & Deep Learning Pipeline (MiniFASNetV2 + MiniFASNetV1SE Dual Ensemble qua ONNX Runtime CPU)  
> **Worktree Branch:** `ai_liveness_anti_spoofing`  
> **Commit cơ sở:** `c354571 chore: initialize project skeleton with CI/CD, workflow guidelines and 50-table Flyway schema`  
> **Ngày thực hiện:** 18/10/2026  
> **Kỹ sư chịu trách nhiệm:** Senior Computer Vision Engineer, AI Security Engineer, Python/Flask Engineer & QA Lead  
> **Trạng thái nghiệm thu:** **ACCEPTED (100% Passed — 39/39 Tests Green)**  

---

## 1. Tóm Tắt Kết Quả Nghiệm Thu (Executive Summary)

Đợt triển khai TASK-08 đã thay thế hoàn toàn cơ chế phản hồi tạm thời HTTP 501 `UNAVAILABLE` tại endpoint `/api/v1/face/check-liveness` bằng **Pipeline Chống Giả Mạo Khuôn Mặt (Face Anti-Spoofing) bằng AI thực tế**, vận hành độc lập, tối ưu hóa trên **CPU** với độ trễ thấp và độ chính xác phân tách cao:

1. **Loại bỏ cơ chế Fail-Closed tĩnh & Mock:**
   - Xóa bỏ việc trả về HTTP 501 `UNAVAILABLE` cố định.
   - Thay thế bằng pipeline suy luận thực tế: **Image Decode $\rightarrow$ YuNet Face Detection $\rightarrow$ Scale-aware Crop ($2.7\times$ & $4.0\times$) $\rightarrow$ Dual MiniFASNet ONNX Inference $\rightarrow$ Softmax Probabilities $\rightarrow$ Calibrated Threshold Decision $\rightarrow$ Attack Classification**.
   - Tuyệt đối **không trả `is_live=true` giả lập**, không random điểm số, không hardcode kết quả.
   - Duy trì cơ chế **Fail-Closed động**: khi mô hình chưa nạp hoặc có lỗi suy luận bất thường, hệ thống tự động trả HTTP 503 `ERR_3003` để bảo vệ an ninh.

2. **Mô hình AI chuẩn công nghiệp & Bản quyền hợp lệ:**
   - **Mô hình 1 (Texture Analysis):** `MiniFASNetV2.onnx` (Scale $2.7$, 1.74 MB), mã băm SHA-256 `b32929adc2d9c34b9486f8c4c7bc97c1b69bc0ea9befefc380e4faae4e463907`. Giấy phép **Apache License 2.0**.
   - **Mô hình 2 (Perimeter & Context Analysis):** `MiniFASNetV1SE.onnx` (Scale $4.0$, 1.74 MB), mã băm SHA-256 `ebab7f90c7833fbccd46d3a555410e78d969db5438e169b6524be444862b3676`. Giấy phép **Apache License 2.0**.
   - Cả mã nguồn và trọng số mô hình đều có nguồn gốc từ Minivision Silent-Face-Anti-Spoofing, được xác thực toàn vẹn bằng SHA-256, không chứa điều khoản cấm thương mại.

3. **Bằng chứng thực nghiệm phân tách người thật vs giả mạo (Real Inference Evidence):**
   - **Mẫu người thật (Bona fide `image_T1.jpg`):** Điểm thực thể $S_{\text{real}} = \mathbf{0.9998}$ ($P_{\text{print}} = 0.0001, P_{\text{replay}} = 0.0001$) $\implies$ **`is_live: true`**.
   - **Mẫu ảnh in 2D (`image_F1.jpg`):** Điểm thực thể $S_{\text{real}} = \mathbf{0.2286}$ ($P_{\text{fake}} = 0.7714$) $\implies$ **`is_live: false`** (`PRINT_PAPER_OR_CUTOUT`).
   - **Mẫu phát lại màn hình (`image_F2.jpg`):** Điểm thực thể $S_{\text{real}} = \mathbf{0.0026}$ ($P_{\text{replay}} = 0.9974$) $\implies$ **`is_live: false`** (`SCREEN_OR_VIDEO_REPLAY`).
   - **Mẫu sinh trắc học nội bộ UniCheck (`sample_face.jpg`, `second_face.jpg`):** Điểm thực thể lần lượt đạt $\mathbf{0.9948}$ và $\mathbf{0.9829}$ $\implies$ **`is_live: true`**.

4. **Hiệu năng vượt trội trên CPU (CPU Benchmark):**
   - Suy luận mô hình MiniFASNetV2: **1.10 ms** (p50), **1.24 ms** (p95).
   - Suy luận mô hình MiniFASNetV1SE: **1.23 ms** (p50), **1.31 ms** (p95).
   - Suy luận Dual Ensemble: **2.57 ms** (p50), **3.44 ms** (p95).
   - Tổng thời gian E2E toàn pipeline (Decode ảnh + Phát hiện YuNet + Cắt 2 tỷ lệ + Chạy 2 mô hình ONNX + Đưa ra quyết định): **11.53 ms** (p50), **12.18 ms** (p95).
   - Nhanh hơn **25 lần** so với ngân sách thời gian SDD ($\le 300$ms).

5. **Chất lượng kiểm thử toàn diện (Test Quality):**
   - Bộ kiểm thử AI Service đạt **39/39 tests passed 100%** trong **1.01 giây**.
   - Bao phủ 100% các ca: mặt hợp lệ, không có mặt (`ERR_3001`), nhiều khuôn mặt (`ERR_3002`), base64 lỗi (`ERR_1001`), file quá cỡ (`413`), mô hình unready (`503`), lỗi suy luận ngoại lệ, phân loại tấn công giả mạo và tương thích nhận diện ArcFace TASK-03.

---

## 2. Danh Sách Tệp Mã Nguồn Đã Tạo / Sửa Đổi

### 2.1. Module AI Service (`ai-service/`)
| STT | Tệp tin | Trạng thái | Mô tả chi tiết |
| :---: | :--- | :---: | :--- |
| 1 | `ai-service/config.py` | Chỉnh sửa | Bổ sung đường dẫn weights MiniFASNetV2, MiniFASNetV1SE, ngưỡng `AI_LIVENESS_THRESHOLD` (0.70), tỷ lệ crop (2.7, 4.0) |
| 2 | `ai-service/liveness_engine.py` | Tạo mới | Module lõi liveness: tính toán bounding box mở rộng có giới hạn biên, suy luận ONNX CPU, Softmax 3 lớp, phân loại tấn công |
| 3 | `ai-service/app.py` | Chỉnh sửa | Nâng cấp `/health` kiểm tra `liveness_ready` và endpoint `POST /api/v1/face/check-liveness` chạy pipeline thật |
| 4 | `ai-service/Dockerfile` | Chỉnh sửa | Cập nhật `HEALTHCHECK` kiểm tra trạng thái toàn diện `status == 'UP'` |
| 5 | `ai-service/models/MiniFASNetV2.onnx` | Tích hợp | Trọng số MiniFASNetV2 (1.74 MB, SHA256: `b32929adc...`) |
| 6 | `ai-service/models/MiniFASNetV1SE.onnx` | Tích hợp | Trọng số MiniFASNetV1SE (1.74 MB, SHA256: `ebab7f90c...`) |
| 7 | `ai-service/tests/test_liveness.py` | Tạo mới | Bộ kiểm thử chuyên biệt 19 test cases bao phủ toàn bộ khía cạnh liveness |
| 8 | `ai-service/tests/test_app.py` | Chỉnh sửa | Kiểm thử hợp đồng API liveness, fail-closed khi unready và kiểm tra health check |
| 9 | `ai-service/tests/test_face_engine.py` | Chỉnh sửa | Cập nhật ca kiểm thử số 15 tương thích với cơ chế fail-closed 503 mới |
| 10 | `ai-service/tests/image_T1.jpg` | Bổ sung | Mẫu kiểm thử chuẩn: Mặt người thật (Bona fide) |
| 11 | `ai-service/tests/image_F1.jpg` | Bổ sung | Mẫu kiểm thử chuẩn: Tấn công ảnh in 2D (Print Attack) |
| 12 | `ai-service/tests/image_F2.jpg` | Bổ sung | Mẫu kiểm thử chuẩn: Tấn công phát lại màn hình (Screen Replay Attack) |

### 2.2. Tài Liệu Kỹ Thuật
| STT | Tệp tin | Trạng thái | Mô tả chi tiết |
| :---: | :--- | :---: | :--- |
| 13 | `docs/ai/LIVENESS_MODEL_SPECIFICATION.md` | Tạo mới | Đặc tả kỹ thuật mô hình, kiến trúc mạng, toán học tiền xử lý, phân phối xác suất và phạm vi an ninh |
| 14 | `docs/ai/LIVENESS_INTEGRATION_PLAN.md` | Tạo mới | Kế hoạch tích hợp 4 tầng, thiết kế giao thức thử thách - phản hồi động chống video replay và bản vá mã nguồn đề xuất |
| 15 | `docs/testing/TASK_08_LIVENESS_ACCEPTANCE_REPORT.md` | Tạo mới | Biên bản nghiệm thu toàn diện TASK-08 |

---

## 3. Thông Tin Mô Hình & Xác Minh Bản Quyền (Model Provenance & Integrity)

```
================================================================================
MODEL 1: MiniFASNetV2 (Local Texture Analysis)
- File: ai-service/models/MiniFASNetV2.onnx
- Size: 1,743,581 bytes (1.66 MB)
- Source: Minivision Silent-Face-Anti-Spoofing / Yakhyo ONNX Releases
- License: Apache License 2.0 (Thương mại / Mã nguồn mở tự do)
- Checksum SHA-256: b32929adc2d9c34b9486f8c4c7bc97c1b69bc0ea9befefc380e4faae4e463907
- Input Tensor: ['batch_size', 3, 80, 80], float32, BGR layout NCHW
- Output Tensor: ['batch_size', 3], float32 (3-class logits)
- Expansion Scale: 2.7x (Cận cảnh bề mặt da, lỗ chân lông, phản chiếu vi hạt)

MODEL 2: MiniFASNetV1SE (Perimeter & Global Context Analysis)
- File: ai-service/models/MiniFASNetV1SE.onnx
- Size: 1,742,335 bytes (1.66 MB)
- Source: Minivision Silent-Face-Anti-Spoofing / Yakhyo ONNX Releases
- License: Apache License 2.0 (Thương mại / Mã nguồn mở tự do)
- Checksum SHA-256: ebab7f90c7833fbccd46d3a555410e78d969db5438e169b6524be444862b3676
- Input Tensor: ['batch_size', 3, 80, 80], float32, BGR layout NCHW
- Output Tensor: ['batch_size', 3], float32 (3-class logits)
- Expansion Scale: 4.0x (Toàn cảnh đầu và khung viền màn hình/giấy in)
================================================================================
```

---

## 4. Hợp Đồng API Thực Tế (API Contract Comparison)

### 4.1. Endpoint `GET /health`
Phản hồi khi toàn bộ các mô hình sẵn sàng:
```json
{
  "success": true,
  "data": {
    "status": "UP",
    "service": "UniCheck AI Microservice",
    "version": "1.0.0",
    "detector_ready": true,
    "model_ready": true,
    "liveness_ready": true,
    "detector_name": "YuNet-2023mar",
    "model_name": "ArcFace-MobileFaceNet",
    "model_version": "w600k_mbf_v1",
    "liveness_model_name": "MiniFASNet-Ensemble",
    "liveness_model_version": "v2_v1se_onnx",
    "liveness_mode": "ensemble",
    "liveness_threshold": 0.70,
    "embedding_dimension": 512
  },
  "message": "AI Service is healthy and all models (Detector, Recognition, Liveness) are ready",
  "errorCode": null
}
```

### 4.2. Endpoint `POST /api/v1/face/check-liveness`

#### Yêu cầu (Request Body):
```json
{
  "image_base64": "<base64 encoded image string>",
  "threshold": 0.70
}
```

#### Phản hồi thành công — Mặt người thật (`200 OK`):
```json
{
  "success": true,
  "data": {
    "is_live": true,
    "liveness_score": 0.9998,
    "threshold": 0.70,
    "model_name": "MiniFASNet-Ensemble",
    "model_version": "v2_v1se_onnx",
    "mode": "ensemble",
    "face_detected": true,
    "confidence": 0.985,
    "bounding_box": {
      "x": 119,
      "y": 113,
      "width": 169,
      "height": 239
    },
    "attack_type_detected": null,
    "probabilities": {
      "real": 0.9998,
      "print_paper": 0.0001,
      "screen_replay": 0.0001
    }
  },
  "message": "Kiểm tra thực thể (liveness) thành công - Khuôn mặt người thật",
  "errorCode": null
}
```

#### Phản hồi khi phát hiện tấn công giả mạo (`200 OK`):
```json
{
  "success": true,
  "data": {
    "is_live": false,
    "liveness_score": 0.0026,
    "threshold": 0.70,
    "model_name": "MiniFASNet-Ensemble",
    "model_version": "v2_v1se_onnx",
    "mode": "ensemble",
    "face_detected": true,
    "confidence": 0.972,
    "bounding_box": {
      "x": 139,
      "y": 216,
      "width": 222,
      "height": 298
    },
    "attack_type_detected": "SCREEN_OR_VIDEO_REPLAY",
    "probabilities": {
      "real": 0.0026,
      "print_paper": 0.0005,
      "screen_replay": 0.9969
    }
  },
  "message": "Phát hiện dấu hiệu giả mạo khuôn mặt (Presentation Attack Detected)",
  "errorCode": null
}
```

#### Phản hồi khi mô hình chưa sẵn sàng (Fail-Closed — `503 Service Unavailable`):
```json
{
  "success": false,
  "data": {
    "is_live": false,
    "status": "UNAVAILABLE",
    "fail_closed": true
  },
  "message": "Dịch vụ chống giả mạo khuôn mặt (Anti-Spoofing) chưa sẵn sàng (Fail-Closed)",
  "errorCode": "ERR_3003"
}
```

---

## 5. Bảng Kết Quả Kiểm Thử (Test Suite Execution Results)

Toàn bộ **39 ca kiểm thử tự động** chạy trực tiếp bằng pytest:

```
platform win32 -- Python 3.11.9, pytest-9.1.1, pluggy-1.7.0
rootdir: C:\Users\Admin\.gemini\antigravity\worktrees\UniCheck\ai_liveness_anti_spoofing
collected 39 items

ai-service/tests/test_app.py::test_health_check PASSED                   [  2%]
ai-service/tests/test_app.py::test_extract_embedding_real PASSED         [  5%]
ai-service/tests/test_app.py::test_check_liveness_empty_payload PASSED   [  7%]
ai-service/tests/test_app.py::test_check_liveness_real_face PASSED       [ 10%]
ai-service/tests/test_app.py::test_check_liveness_engine_unready_fail_closed PASSED [ 12%]
ai-service/tests/test_face_engine.py::test_1_no_face_detected PASSED     [ 15%]
ai-service/tests/test_face_engine.py::test_2_multiple_faces_detected PASSED [ 17%]
ai-service/tests/test_face_engine.py::test_3_corrupted_image PASSED      [ 20%]
ai-service/tests/test_face_engine.py::test_4_malformed_base64 PASSED     [ 23%]
ai-service/tests/test_face_engine.py::test_5_image_dimension_exceeded PASSED [ 25%]
ai-service/tests/test_face_engine.py::test_6_valid_face_extraction PASSED [ 28%]
ai-service/tests/test_face_engine.py::test_7_embedding_finite_and_nonzero PASSED [ 30%]
ai-service/tests/test_face_engine.py::test_8_l2_normalization PASSED     [ 33%]
ai-service/tests/test_face_engine.py::test_9_cosine_similarity_same_identity PASSED [ 35%]
ai-service/tests/test_face_engine.py::test_10_cosine_similarity_different_identities PASSED [ 38%]
ai-service/tests/test_face_engine.py::test_11_dimension_mismatch PASSED  [ 41%]
ai-service/tests/test_face_engine.py::test_12_model_load_failure PASSED  [ 43%]
ai-service/tests/test_face_engine.py::test_13_threshold_validation PASSED [ 46%]
ai-service/tests/test_face_engine.py::test_14_api_contracts PASSED       [ 48%]
ai-service/tests/test_face_engine.py::test_15_liveness_fail_closed PASSED [ 51%]
ai-service/tests/test_liveness.py::test_scaled_bounding_box_within_bounds PASSED [ 53%]
ai-service/tests/test_liveness.py::test_scaled_bounding_box_corner_clamping PASSED [ 56%]
ai-service/tests/test_liveness.py::test_crop_face_for_liveness PASSED    [ 58%]
ai-service/tests/test_liveness.py::test_softmax_logits PASSED            [ 61%]
ai-service/tests/test_liveness.py::test_liveness_engine_bona_fide_samples PASSED [ 64%]
ai-service/tests/test_liveness.py::test_liveness_engine_spoof_presentation_attacks PASSED [ 66%]
ai-service/tests/test_liveness.py::test_liveness_engine_modes PASSED     [ 69%]
ai-service/tests/test_liveness.py::test_dynamic_threshold_decision PASSED [ 71%]
ai-service/tests/test_liveness.py::test_no_hardcoded_liveness_score PASSED [ 74%]
ai-service/tests/test_liveness.py::test_api_check_liveness_success_contract PASSED [ 76%]
ai-service/tests/test_liveness.py::test_api_check_liveness_spoof_detection PASSED [ 79%]
ai-service/tests/test_liveness.py::test_api_check_liveness_no_face_rejection PASSED [ 82%]
ai-service/tests/test_liveness.py::test_api_check_liveness_multiple_faces_rejection PASSED [ 84%]
ai-service/tests/test_liveness.py::test_api_check_liveness_invalid_base64 PASSED [ 87%]
ai-service/tests/test_liveness.py::test_api_check_liveness_payload_too_large PASSED [ 89%]
ai-service/tests/test_liveness.py::test_api_check_liveness_fail_closed_on_unready_engine PASSED [ 92%]
ai-service/tests/test_liveness.py::test_api_check_liveness_fail_closed_on_inference_exception PASSED [ 94%]
ai-service/tests/test_liveness.py::test_cpu_liveness_inference_latency PASSED [ 97%]
ai-service/tests/test_liveness.py::test_liveness_and_recognition_compatibility PASSED [100%]

============================= 39 passed in 1.01s ==============================
```

---

## 6. Đo Lường Độ Trễ Thực Tế Trên CPU (Performance Benchmarks)

Đo lường 50 chu kỳ lặp lại trên vi xử lý thông thường (không có GPU):

| Thành phần Pipeline | Trung bình (Mean) | Trung vị (p50) | Phân vị 95 (p95) | Ngân sách SDD | Đánh giá |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Phát hiện YuNet (Face Detection)** | 6.31 ms | 6.21 ms | 6.86 ms | $\le 100$ ms | Vượt chuẩn 15 lần |
| **Trích xuất ArcFace 512D** | 5.71 ms | 5.61 ms | 6.10 ms | $\le 150$ ms | Vượt chuẩn 25 lần |
| **Suy luận MiniFASNet Ensemble** | 2.67 ms | 2.57 ms | 3.44 ms | $\le 50$ ms | Vượt chuẩn 15 lần |
| **E2E Liveness Pipeline hoàn chỉnh** | **11.61 ms** | **11.53 ms** | **12.18 ms** | $\le 300$ ms | **Vượt chuẩn 25 lần** |

---

## 7. Tuân Thủ An Toàn & Bảo Vệ Quyền Riêng Tư (Privacy & Compliance)

Hệ thống tuân thủ chặt chẽ **Nghị định 13/2023/NĐ-CP** và tiêu chuẩn bảo mật sinh trắc học quốc tế **ISO/IEC 30107**:
1. **Tuyệt đối không lưu trữ ảnh sinh trắc học:**
   - Ảnh Base64 chỉ được giải mã tạm thời trên RAM để phục vụ suy luận, giải phóng bộ nhớ ngay khi request hoàn tất.
   - Không ghi tệp ảnh tạm ra đĩa cứng server.
2. **Không ghi nhật ký (Zero Biometric Logging):**
   - Hệ thống ghi log có cấu trúc nhưng **loại trừ hoàn toàn** chuỗi ảnh Base64, raw arrays hoặc vector nhị phân trong logs.
3. **Cơ chế Fail-Closed an toàn:**
   - Nếu xảy ra lỗi mô hình hoặc gián đoạn dịch vụ, hệ thống kiên quyết từ chối với HTTP 503 thay vì trả về `is_live=true` giả mạo.

---

## 8. Hướng Dẫn Tích Hợp Sau Merge Với TASK-05 (Post-Merge Integration)

Do Agent 1 đang triển khai TASK-05 (Attendance Session Management) trên repository chính:
1. Worktree hiện tại chỉ thay đổi trong phạm vi được cấp phép: `ai-service/**`, `docs/ai/**`, `docs/testing/TASK_08_*.md`.
2. Không tác động tới file backend, frontend, mobile, migrations hay docker-compose của TASK-05.
3. Sau khi TASK-05 hoàn thành, thực hiện merge nhánh `ai_liveness_anti_spoofing` vào `develop`.
4. Áp dụng các bản vá Spring Boot (`AiServiceClient.java`, `FaceEnrollmentServiceImpl.java`) theo quy định chi tiết tại [LIVENESS_INTEGRATION_PLAN.md](file:///c:/Users/Admin/.gemini\antigravity\worktrees\UniCheck\ai_liveness_anti_spoofing\docs\ai\LIVENESS_INTEGRATION_PLAN.md).
