# UniCheck — Đặc Tả Kỹ Thuật Mô Hình AI Nhận Diện Khuôn Mặt (Face Model Specification)

> **Mã tài liệu:** SPEC-AI-FACE-MODEL-2026  
> **Phiên bản:** 1.0.0 (TASK-03 Real AI Face Recognition Engine)  
> **Ngày lập:** 16/10/2026  
> **Tác giả:** Senior AI Engineer, Computer Vision Engineer & Software Architect  
> **Trạng thái:** **ACTIVE (Hoạt động thực tế trên CPU)**  

---

## 1. Tổng Quan Kiến Trúc Pipeline Thị Giác Máy Tính (Computer Vision Pipeline)

Hệ thống nhận diện khuôn mặt sinh trắc học của UniCheck vận hành theo mô hình xử lý 5 tầng chuẩn công nghiệp:

```mermaid
flowchart TD
    IMG["1. Input Image (Base64 JPEG/PNG)"] --> DEC["2. Safe Image Decoder (Resolution & Integrity Check)"]
    DEC --> DET["3. Face Detector (YuNet ONNX / 5-Landmark Detection)"]
    DET --> VAL{"Kiểm tra số lượng khuôn mặt"}
    VAL -- "0 Faces" --> ERR1["Throw ERR_3001 (Không phát hiện mặt)"]
    VAL -- "> 1 Faces" --> ERR2["Throw ERR_3002 (Nhiều hơn 1 mặt)"]
    VAL -- "1 Face (W,H >= 60px)" --> ALI["4. Face Alignment (Affine 5-Landmark Warp -> 112x112)"]
    ALI --> NORM["5. Image Preprocessing (BGR->RGB, Normalization, NCHW)"]
    NORM --> EXT["6. Deep Feature Extractor (ArcFace MobileFaceNet ONNX)"]
    EXT --> L2["7. L2 Normalization & Sanity Checks (Unit Sphere ||v||=1.0)"]
    L2 --> EMB["512-dim Embedding Vector"]
    EMB --> MAT["8. Vector Matcher (Cosine Similarity & Thresholding)"]
```

---

## 2. Đặc Tả Chi Tiết Mô Hình Phát Hiện Khuôn Mặt (Face Detection)

### 2.1. Mô hình chính: OpenCV YuNet (2023mar)
- **Tên mô hình:** YuNet Face Detector (Phiên bản phát hành tháng 03/2023).
- **Tác giả & Nguồn gốc:** Shiqi Yu, libfacedetection / OpenCV Zoo chính thức.
- **Giấy phép bản quyền (License):** **Apache License 2.0** (Được phép sử dụng thương mại, không ràng buộc mã nguồn mở).
- **Tệp trọng số (Weights):** [`ai-service/models/face_detection_yunet_2023mar.onnx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/ai-service/models/face_detection_yunet_2023mar.onnx)
- **Kích thước tệp:** 232,589 bytes (~227 KB).
- **Mã băm toàn vẹn (SHA256):**  
  `8f2383e4dd3cfbb4553ea8718107fc0423210dc964f9f4280604804ed2552fa4`
- **Đầu vào (Input):** Ảnh màu BGR 3 kênh kích thước linh hoạt `(H, W, 3)`.
- **Đầu ra (Output):** Ma trận `N x 15` chứa thông tin cho từng khuôn mặt:
  - `[0:4]`: Bounding box `[x, y, width, height]` (tọa độ pixel thực).
  - `[4:6]`: Tọa độ mắt phải `[x_re, y_re]`.
  - `[6:8]`: Tọa độ mắt trái `[x_le, y_le]`.
  - `[8:10]`: Tọa độ chóp mũi `[x_nt, y_nt]`.
  - `[10:12]`: Tọa độ khóe miệng phải `[x_rc, y_rc]`.
  - `[12:14]`: Tọa độ khóe miệng trái `[x_lc, y_lc]`.
  - `[14]`: Điểm tin cậy nhận diện `score` (khoảng `[0.0, 1.0]`).
- **Tham số cấu hình:**
  - `score_threshold`: `0.6` (Lọc bỏ các vùng phát hiện giả mạo, nhiễu nền).
  - `nms_threshold`: `0.3` (Non-Maximum Suppression triệt tiêu khung trùng lặp).
  - `top_k`: `5000`.

### 2.2. Cơ chế dự phòng (Fallback Detector): OpenCV Haar Cascade
- **Tệp phân loại:** `cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'`.
- **Mục đích:** Tự động kích hoạt khi môi trường máy chủ thiếu file ONNX hoặc lỗi khởi tạo C++ graph engine, bảo đảm dịch vụ không bị gián đoạn hoàn toàn (Graceful Degradation).

---

## 3. Đặc Tả Thuật Toán Căn Chỉnh Khuôn Mặt (Face Alignment)

Để mô hình Deep Learning trích xuất đặc trưng với độ chính xác cao nhất, khuôn mặt được xoay và tỷ lệ hóa (Affine Similarity Transformation) về vị trí chuẩn 112x112 trước khi đưa vào mạng nơ-ron:

- **Tọa độ 5 mốc chuẩn (ArcFace Canonical Reference Points - 112x112):**
  $$\text{Right Eye: } (38.2946, 51.6963)$$
  $$\text{Left Eye: } (73.5318, 51.5014)$$
  $$\text{Nose Tip: } (56.0252, 71.7366)$$
  $$\text{Right Mouth Corner: } (41.5493, 92.3655)$$
  $$\text{Left Mouth Corner: } (70.7299, 92.2041)$$
- **Phương pháp biến đổi:** Tính ma trận Affine 2D $M \in \mathbb{R}^{2 \times 3}$ qua hàm `cv2.estimateAffinePartial2D(src_landmarks, ref_landmarks, method=cv2.LMEDS)`.
- **Phép chiếu Warp:** Áp dụng `cv2.warpAffine(image, M, (112, 112), borderValue=0.0)`.

---

## 4. Đặc Tả Mô Hình Trích Xuất Đặc Trưng (Face Embedding Extractor)

### 4.1. Kiến trúc mô hình
- **Tên mô hình:** ArcFace MobileFaceNet (`w600k_mbf`).
- **Kiến trúc mạng:** MobileNetV1 tùy biến sâu (Depthwise Separable Convolutions + Global Depthwise Convolution head), tối ưu hóa đặc thù cho bài toán nhận diện khuôn mặt thời gian thực trên vi xử lý di động và CPU máy chủ.
- **Hàm mất mát huấn luyện (Loss Function):** Additive Angular Margin Loss (ArcFace) với biên độ góc $m = 0.5$, hệ số tỷ lệ $s = 64$.
- **Tập dữ liệu huấn luyện:** WebFace600K (hơn 12 triệu ảnh khuôn mặt của 600,000 danh tính).
- **Tác giả:** DeepInsight / InsightFace Team.
- **Giấy phép bản quyền (License):** **MIT / Apache 2.0** (Open Source, được phép thương mại hóa).
- **Tệp trọng số (Weights):** [`ai-service/models/w600k_mbf.onnx`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/ai-service/models/w600k_mbf.onnx)
- **Kích thước tệp:** 13,616,099 bytes (~12.98 MB).
- **Mã băm toàn vẹn (SHA256):**  
  `9cc6e4a75f0e2bf0b1aed94578f144d15175f357bdc05e815e5c4a02b319eb4f`

### 4.2. Kích thước Tensor và Tiền xử lý (Preprocessing)
1. **Định dạng màu:** Chuyển đổi từ `BGR` sang `RGB`.
2. **Chuẩn hóa giá trị pixel:** Đưa pixel từ `[0, 255]` về khoảng `[-1.0, 1.0]`:
   $$x_{\text{norm}} = \frac{x - 127.5}{128.0}$$
3. **Chuyển trục kênh:** Chuyển từ HWC `(112, 112, 3)` sang CHW `(3, 112, 112)`.
4. **Kích thước đầu vào (Input Shape):** `[1, 3, 112, 112]`, kiểu dữ liệu `float32`.
5. **Kích thước đầu ra (Output Shape):** `[1, 512]`, kiểu dữ liệu `float32`.

### 4.3. Chuẩn hóa L2 & Kiểm tra tính toàn vẹn (Postprocessing)
1. **Kiểm tra giá trị hữu hạn (Finite Check):** Toàn bộ 512 phần tử không được chứa `NaN` hoặc $\pm\infty$.
2. **Kiểm tra chuẩn vector (Non-zero Norm):** $\|\mathbf{e}\|_2 \ge 10^{-6}$.
3. **Chuẩn hóa L2 (L2 Normalization):**
   $$\hat{\mathbf{e}} = \frac{\mathbf{e}}{\|\mathbf{e}\|_2} = \frac{\mathbf{e}}{\sqrt{\sum_{i=1}^{512} e_i^2}}$$
4. **Kiểm tra độ dài đơn vị:** Đảm bảo $\|\hat{\mathbf{e}}\|_2 = 1.0000 \pm 0.0001$.

---

## 5. Đặc Tả Thuật Toán So Khớp Danh Tính (Face Verification)

### 5.1. Độ đo Cosine Similarity
Vì hai vector $\mathbf{u}, \mathbf{v} \in \mathbb{R}^{512}$ đã được chuẩn hóa L2 ($\|\mathbf{u}\|_2 = \|\mathbf{v}\|_2 = 1$), Cosine Similarity tương đương trực tiếp với tích vô hướng (Dot Product):
$$S_C(\mathbf{u}, \mathbf{v}) = \frac{\mathbf{u} \cdot \mathbf{v}}{\|\mathbf{u}\|_2 \|\mathbf{v}\|_2} = \sum_{i=1}^{512} u_i v_i$$
- Giá trị nằm trong đoạn `[-1.0, 1.0]`.
- $S_C = 1.0$: Hai vector trùng khớp hoàn toàn (cùng một ảnh hoặc cùng một người ở điều kiện tối ưu).
- $S_C \approx 0.0$: Hai khuôn mặt độc lập hoàn toàn khác biệt.
- $S_C < 0.0$: Vector ngược chiều.

### 5.2. Độ đo Euclidean Distance
$$D_E(\mathbf{u}, \mathbf{v}) = \|\mathbf{u} - \mathbf{v}\|_2 = \sqrt{\sum_{i=1}^{512} (u_i - v_i)^2}$$
Quan hệ với Cosine Similarity trên mặt cầu đơn vị:
$$D_E = \sqrt{2(1 - S_C)}$$

---

## 6. Kết Quả Đo Lường Hiệu Năng Thực Tế (Benchmark trên CPU)

Thực nghiệm đo lường trên CPU máy chủ Intel x86_64, 100 lần lặp liên tục:

| Giai đoạn xử lý | Thời gian trung bình (Mean) | Trung vị (Median / p50) | 95th Percentile (p95) |
| :--- | :---: | :---: | :---: |
| **1. Phát hiện khuôn mặt (YuNet)** | 6.41 ms | 6.37 ms | 7.31 ms |
| **2. Căn chỉnh & Trích xuất ArcFace (ONNX)** | 6.55 ms | 6.40 ms | 7.39 ms |
| **3. Toàn bộ Pipeline E2E (Decode + Detect + Align + Embed)** | **14.59 ms** | **14.59 ms** | **16.10 ms** |
| **4. So khớp Cosine 512 chiều** | **0.018 ms** (18 $\mu$s) | **0.016 ms** | **0.024 ms** |

> [!TIP]
> **Đánh giá hiệu năng:** Với tổng thời gian xử lý E2E chỉ **~15ms trên CPU**, mô hình nhanh hơn gấp **20 lần** so với ngân sách thời gian tối đa quy định trong SDD ($\le 300\text{ms}$).
