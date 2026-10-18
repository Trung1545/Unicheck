# PHÂN TÍCH ĐỘ LỆCH KIẾN TRÚC VÀ RỦI RO KỸ THUẬT (ARCHITECTURE GAPS ANALYSIS)
**Mã tài liệu:** AUDIT-ARCH-GAPS-2026  
**Ngày kiểm toán:** 15/10/2026  

---

## 1. ĐỘ LỆCH KIẾN TRÚC CLIENT: REACT WEB VS FLUTTER MULTI-PLATFORM

### 1.1. Hiện trạng xung đột tài liệu và định hướng
Trong lịch sử phát triển của repository tồn tại 2 trường phái kiến trúc mâu thuẫn:
1. **Trường phái Flutter Multi-platform (tại `docs/evidence/flutter_web_auth_verification.md`):**
   * Đặt giả định Flutter là *"Frontend duy nhất đang phát triển"* và biên dịch sang cả Web Desktop (`flutter build web`).
   * Coi thư mục `frontend/` là React cũ (legacy).
2. **Trường phái React Web + Stitch (trong yêu cầu thực tế người dùng và SDD Capstone):**
   * Yêu cầu dứt khoát: **Web Portal chạy React 18, Vite 5, Tailwind CSS 3, TypeScript 5.6**, tích hợp hệ thống 39 màn hình đồ sộ từ **Google Stitch (Academic Precision)**.
   * `mobile/` giữ vai trò là Ứng dụng Di động chuyên biệt cho Giảng viên & Sinh viên.

### 1.2. Phân tích tác động kỹ thuật (Impact Analysis)
* **Khả năng hiển thị và mật độ thông tin học thuật:**
  * Các màn hình quản trị như Sổ điểm học phần (`ef5d3e2ef1f14d349f4f732efcee4e55`), Báo cáo thống kê chuyên cần (`c9523d6727af4088a7135067d379c570`), Quản lý lớp học phần (`495a21f075ca479698f5f5075cee8a41`) có độ phân giải gốc 2560px – 3904px, chứa hàng chục cột dữ liệu, bộ lọc ma trận và thanh công cụ phức tạp.
  * Việc render giao diện bảng biểu phức tạp này trên Flutter Web (dùng CanvasKit / HTML renderer) gây ra tình trạng giật khung hình (jank), khó tối ưu SEO/Accessibility, không copy được văn bản tự nhiên như DOM thật và dung lượng tải ban đầu lớn (> 20MB WebAssembly/CanvasKit).
  * Trong khi đó, **React 18 + Tailwind CSS** render trực tiếp DOM gốc, đạt tốc độ chuyển trang dưới 0.1s và tương thích 100% với mã HTML/CSS xuất từ Google Stitch.
* **Quyết định kiến trúc chuẩn hóa (Architectural Decision):**
  * **Cổng Web Quản trị Học viện & Giảng đường (`frontend/`):** React 18 SPA phục vụ Quản trị viên, Phòng Đào tạo, Trưởng khoa và Giảng viên dùng trên máy tính để bàn/laptop.
  * **Ứng dụng Di động Điểm danh (`mobile/`):** Flutter Native App (Android/iOS) phục vụ Sinh viên quét khuôn mặt, quét mã QR và xác thực Wi-Fi khi có mặt trực tiếp tại lớp học.

---

## 2. KHOẢNG CÁCH DỮ LIỆU: CSDL FLYWAY (50 BẢNG) VS JPA ENTITIES (10 ENTITIES)

### 2.1. Thực trạng dữ liệu
* CSDL đã được thiết kế rất chi tiết thông qua 3 script Flyway:
  * `V1__init_academic_catalog.sql` (16 bảng): Ngành, chuyên ngành, học phần, học kỳ, loại tiết, phòng học, Wi-Fi AP, cấu hình điểm danh.
  * `V2__init_users_and_profiles.sql` (9 bảng): Người dùng, hồ sơ sinh viên, hồ sơ giảng viên, quyền hạn, device token, session, log, face encoding.
  * `V3__init_classes_attendance_and_operations.sql` (25 bảng): Lớp học phần, phân công giảng dạy, đăng ký, thời khóa biểu, điểm số, ca điểm danh, điểm danh sinh viên, bài tập, chat, thông báo, bảng tin, đơn từ, cảnh báo.
* **Độ lệch nghiêm trọng:** Backend Spring Boot mới chỉ triển khai JPA Entity cho 10 bảng của script `V2` và `system_logs`. 40 bảng còn lại **hoàn toàn chưa có thực thể Java**.
* **Hậu quả:** Mặc dù CSDL có sẵn cấu trúc hoàn chỉnh, Backend chưa thể viết Repository hay Service cho Điểm danh, Lớp học phần, Học kỳ hay Phòng học.

---

## 3. KHOẢNG CÁCH NĂNG LỰC TRÍ TUỆ NHÂN TẠO (AI MICROSERVICE GAP)

### 3.1. Hiện trạng `ai-service/app.py`
Mã nguồn hiện tại chỉ gồm 58 dòng Python sử dụng Flask với các endpoint giả lập:
```python
# Trích xuất đặc trưng giả lập
@app.route('/api/v1/face/extract-embedding', methods=['POST'])
def extract_embedding():
    return jsonify({
        "success": True,
        "data": {
            "embedding": [0.0] * 128,  # Trả về 128 số 0
            "confidence": 0.98
        }
    })

# Kiểm tra Liveness giả lập
@app.route('/api/v1/face/check-liveness', methods=['POST'])
def check_liveness():
    return jsonify({
        "success": True,
        "data": {
            "is_live": True,           # Luôn trả về hợp lệ
            "liveness_score": 0.96
        }
    })
```

### 3.2. Yêu cầu kỹ thuật cần đạt theo đặc tả
1. **Face Detection Pipeline:** Phải tích hợp OpenCV Haar Cascade / RetinaFace / MediaPipe FaceMesh để nhận diện tọa độ khuôn mặt (Bounding Box), loại bỏ ảnh chụp không có người hoặc có từ 2 khuôn mặt trở lên (Mã lỗi `ERR_3001`, `ERR_3002`).
2. **Face Embedding Model:** Phải tích hợp mô hình học sâu (FaceNet Inception-ResNet-v1 512 chiều hoặc MobileFaceNet/InsightFace 128 chiều) đã huấn luyện tiền kỳ.
3. **Face Matching & Thresholding:** Triển khai tính toán Cosine Similarity giữa vector khuôn mặt lúc điểm danh và vector đã đăng ký trong bảng `face_encodings` (Ngưỡng khuyến nghị: `similarity >= 0.75` tương đương `confidence >= 95%`).
4. **Anti-Spoofing / Liveness Check:** Kiểm tra chớp mắt (Eye Aspect Ratio - EAR), chuyển động nghiêng đầu hoặc mạng nơ-ron phân biệt ảnh chụp màn hình/ảnh in giấy (Mã lỗi `ERR_3003`).

---

## 4. KHOẢNG CÁCH PHẦN CỨNG & PLUGIN TRÊN MOBILE (`mobile/`)

Tệp [`mobile/pubspec.yaml`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/mobile/pubspec.yaml) hiện chỉ có các dependency cơ bản: `get`, `dio`, `flutter_secure_storage`, `camera`, `intl`.
Để đạt được các chức năng sinh trắc học và vị trí theo yêu cầu, Mobile thiếu các thư viện cốt lõi:
1. **Nhận diện khuôn mặt thời gian thực trên thiết bị:** Thiếu `google_mlkit_face_detection` (cần thiết để định vị khuôn mặt nằm gọn trong khung oval trước khi chụp ảnh gửi lên backend).
2. **Quét mã QR động xoay vòng:** Thiếu `mobile_scanner` (cần thiết cho sinh viên quét mã QR hiển thị trên máy chiếu giảng viên).
3. **Kiểm tra Wi-Fi BSSID phòng học:** Thiếu `network_info_plus` (cần thiết để lấy địa chỉ MAC của Access Point phục vụ chống gian lận vị trí `ERR_3008`).
4. **Kiểm tra GPS Geofencing:** Thiếu `geolocator` (cần thiết để so sánh khoảng cách giữa sinh viên và phòng học quy định).

---

## 5. RỦI RO BẢO MẬT & CẤU HÌNH HẠ TẦNG

1. **Hardcoded Fallback JWT Secret:**
   * Trong `docker-compose.yml:L65`:
     `SECURITY_JWT_SECRET: ${JWT_SECRET:-4c9a58b29f7e1b3d5c7a9e0f2b4d6e8a0c2e4f6a8b0d2e4f6a8b0d2e4f6a8b0d}`
   * Rủi ro: Nếu triển khai lên server mà quên cấu hình biến môi trường, khóa ký JWT này sẽ bị lộ công khai trên repository GitHub.
2. **Phụ thuộc Redis cho Rate Limiting & Blacklist Token:**
   * Backend hiện có cơ chế fallback in-memory khi Redis offline. Tuy nhiên, trong môi trường multi-instance cân bằng tải (load balancer), in-memory cache không đồng bộ giữa các node, dẫn đến rủi ro token bị thu hồi trên node A nhưng vẫn dùng được trên node B.
3. **Docker Daemon Offline:**
   * Docker Desktop Linux Engine hiện đang tắt trên máy phát triển, khiến các dịch vụ CSDL PostgreSQL 15 và Redis 7 chưa thể khởi động tự động qua compose.
