# NHẬT KÝ THAY ĐỔI TÀI LIỆU ĐẶC TẢ & THIẾT KẾ UNICHECK
## (Document ChangeLog & Specification Reconciliation Log)

> **Mã tài liệu:** `CHANGELOG-UNICHECK-2026`  
> **Căn cứ đối chiếu:** So sánh tài liệu cung cấp ban đầu (`UniCheck_DacTa_YeuCau_ThietKe_BanMoi_2026.docx` / SDD v1.x) với Bản Đặc tả và Thiết kế cập nhật chuẩn hóa (`UniCheck_SRS_SDD_Final.docx` / `.md`).  
> **Thời điểm cập nhật:** 20/10/2026  
> **Chịu trách nhiệm:** Software Architect & Technical Documentation Specialist  

---

## 1. TỔNG QUAN CÁC THAY ĐỔI CỐT LÕI (CORE RECONCILIATIONS)

Tài liệu đặc tả mới (v2.1) được biên soạn lại toàn diện nhằm phản ánh **chính xác 100% hiện trạng mã nguồn thực tế**, loại bỏ mọi nhận định suy diễn, phân định rạch ròi giữa các tính năng đã kiểm thử tự động, các tính năng bán phần (partial) và các tính năng mở rộng trong tương lai.

```
+------------------------------------------------------------------------------------------------+
| CÁC NGUYÊN TẮC ĐIỀU CHỈNH CHÍNH TRONG PHIÊN BẢN 2.1:                                          |
| 1. Không nhận vơ các chức năng tương lai (Bài tập, Sổ điểm, Chatbot AI) là đã hoàn thành.      |
| 2. Minh định Mobile Check-in hiện là UI Placeholder; luồng sinh viên nộp ảnh thuộc TASK-06.  |
| 3. Cập nhật AI Service: Loại bỏ mô tả mock; đưa MiniFASNet Liveness thực tế từ TASK-08 vào.   |
| 4. Khẳng định kiến trúc công nghệ: Web xây bằng React 18 (Desktop), Mobile bằng Flutter (App). |
| 5. Đối chiếu trung thực 10 tiêu chí kỹ thuật của đề bài giảng viên.                            |
+------------------------------------------------------------------------------------------------+
```

---

## 2. BẢNG CHI TIẾT CÁC MỤC ĐÃ ĐIỀU CHỈNH THEO TỪNG CHƯƠNG

| Chương / Mục | Nội dung trong tài liệu ban đầu | Nội dung sau khi kiểm toán & điều chỉnh | Căn cứ mã nguồn thực tế & Lý do kỹ thuật |
| :--- | :--- | :--- | :--- |
| **Chương 1: Tổng quan hệ thống** | Tuyên bố hệ thống đa nền tảng Flutter toàn diện từ Web đến Mobile. | Xác định rõ ranh giới công nghệ: **Web Frontend dùng React 18 + TypeScript + Vite + Tailwind CSS** (Cổng Quản trị & Giảng viên); **Mobile dùng Flutter 3.47 + Dart** (Chuyên biệt cho Sinh viên). | Mã nguồn phân chia độc lập `frontend/` (React SPA) và `mobile/` (Flutter). Không có bản build Flutter Web được vận hành chính thức cho người dùng. |
| **Chương 1: Giới hạn hệ thống** | Chưa nêu rõ giới hạn các phân hệ ngoài điểm danh. | Bổ sung danh mục giới hạn: Các phân hệ Quản lý đào tạo nâng cao (Ngành/Chuyên ngành), Đơn từ học vụ, Bài tập, Sổ điểm, Chat nội bộ và Chatbot AI nằm ngoài phạm vi nghiệm thu đợt này. | CSDL có schema Flyway V1-V3 nhưng mã nguồn Java hoàn toàn chưa có JPA Entity và Service xử lý. |
| **Chương 3: Yêu cầu chức năng** | Liệt kê 21 nhóm chức năng như thể hệ thống đã sẵn sàng toàn bộ. | Chuẩn hóa danh mục chức năng theo Feature ID (F-01 đến F-31). Phân loại chính xác 18 chức năng DONE, 5 PARTIAL, 1 MOCK, 7 NOT IMPLEMENTED. | Bảng đối chiếu `UniCheck_Requirement_Traceability.md` dựa trên 281 ca kiểm thử tự động đã thực thi. |
| **Chương 3: Luồng Sinh trắc học** | Đăng ký FaceID được mô tả chung chung như chụp ảnh selfie gửi lên server. | Đặc tả chi tiết luồng **Realtime Guided Scanning**: Khung Oval chỉ dẫn, đo 4 chỉ số chất lượng, kiểm tra góc quay đầu 3 bước (Frontal, Left 15°, Right 15°) bằng Google ML Kit / WebRTC. | `face_enrollment_view.dart`, `HeadPoseEvaluator.dart`, `FaceRegistrationPage.tsx`, `FaceEnrollmentController.java`. |
| **Chương 3 & 5: Điểm danh khuôn mặt** | Coi như sinh viên đã có thể quét mặt điểm danh hoàn chỉnh trên Mobile. | **Đính chính trạng thái:** Màn hình `face_checkin_view.dart` hiện tại là UI Placeholder. Backend chưa có endpoint `POST /attendance/check-in` cho sinh viên. Nghiệp vụ này thuộc trọng tâm **TASK-06**. | Mã nguồn `face_checkin_view.dart:L113` hiển thị thông báo "Tính năng đang được đồng bộ"; `AttendanceSessionServiceImpl.java` chưa có logic nộp ảnh probe. |
| **Chương 6: Kiến trúc hệ thống** | Sơ đồ kiến trúc khái quát, thiếu chi tiết về AI Service và kết nối. | Vẽ lại sơ đồ kiến trúc 5 tầng: Client (React + Flutter) $\rightarrow$ Nginx Proxy $\rightarrow$ Spring Boot Core $\rightarrow$ Flask AI Service $\rightarrow$ PostgreSQL & Redis Cache. Bổ sung giao thức kết nối chi tiết. | `system_architecture.mmd`, `docker-compose.yml`, `AiServiceClient.java`. |
| **Chương 7: Thiết kế CSDL (ERD)** | Trích xuất toàn bộ 50 bảng của SDD gốc mà không phân biệt mức độ triển khai. | **Tách biệt rõ ràng:** Vẽ ERD chi tiết cho **25 thực thể JPA thực tế** đang vận hành nghiệp vụ; liệt kê 25 bảng schema Flyway còn lại vào danh mục quy hoạch tương lai. | Kiểm tra thư mục `backend/src/main/java/com/unicheck/model/entity` có chính xác 25 lớp Java Entity. |
| **Chương 7: Quy trình lưu trữ FaceID** | Mô tả lưu trữ khuôn mặt không nêu định dạng kỹ thuật. | Bổ sung đặc tả kỹ thuật lưu trữ: Trích xuất vector 512 số thực float32 $\rightarrow$ Đóng gói thành nhị phân **2048 bytes** Little Endian $\rightarrow$ Lưu vào cột `BYTEA` của PostgreSQL. Cột `face_image` được gán `NULL` (tuân thủ ISO 27001). | `FaceEnrollmentServiceImpl.java:L142-L168`. |
| **Chương 8: Thiết kế chi tiết** | Liveness Detection được mô tả là Stub / Fail-Closed tạm thời. | **Cập nhật đột phá từ TASK-08:** Tích hợp pipeline Deep Learning thực tế gồm **YuNet Face Detector + Dual MiniFASNet ONNX (V2 Scale 2.7x + V1SE Scale 4.0x)**, Softmax 3 lớp, ngưỡng $S_{\text{real}} \ge 0.70$. | `ai-service/liveness_engine.py`, `TASK_08_LIVENESS_ACCEPTANCE_REPORT.md`, `test_liveness.py` (19 tests pass). |
| **Chương 9: Thiết kế UI/UX** | Liệt kê danh sách màn hình không có mã ánh xạ Stitch. | Ánh xạ chi tiết **39 màn hình Google Stitch** (Project ID: `3214444012266330806`), phân định 12 màn hình đã code React, 1 màn hình Flutter, và 26 màn hình chưa triển khai. | `docs/audit/VERIFIED_STITCH_MAPPING.md`. |
| **Chương 10: Kiểm thử (QA)** | Bảng test case chung chung không có số liệu thực thi. | Bổ sung biên bản thực thi **281 ca kiểm thử tự động thực tế**: 132 tests Backend (Maven), 78 tests Frontend (Node Test), 32 tests Mobile (Flutter Test), 39 tests AI Service (Pytest). | Toàn bộ log thực thi kiểm thử được dẫn chứng với ngày giờ, mã commit và số test case. |
| **Chương 11: Triển khai & Vận hành** | Liệt kê các dịch vụ bên ngoài (Cloudinary, Firebase, WebSocket) như thể đã chạy. | **Loại bỏ các dịch vụ không có trong mã nguồn:** Làm rõ Cloudinary, Firebase, WebSocket, OpenRouter không được triển khai trong phiên bản này. Hướng dẫn chi tiết chạy Docker Compose 5 container. | Phân tích tệp `.env.example`, `docker-compose.yml`, kiểm tra mã nguồn không thấy import các SDK này. |
| **Chương 12: Nghiệm thu 10 Tiêu chí** | Tự tuyên bố đáp ứng hoặc đáp ứng tương đương các tiêu chí đề bài. | **Đánh giá trung thực và phân loại minh bạch:**<br>• Đáp ứng: 4 tiêu chí (Kiến trúc 3 khối, Đa dạng tính năng, Cấu hình động, Design Patterns).<br>• Đáp ứng một phần: 3 tiêu chí (UI/UX Responsive, Bất đồng bộ/Hiệu năng, Hệ thống Kiểm thử).<br>• Chưa đáp ứng: 2 tiêu chí (Đa nền tảng 7 môi trường, Client Flutter cho Web).<br>• Chưa kiểm chứng: 1 tiêu chí (Tương thích iOS 10.0+ trên thiết bị thật). | Căn cứ trực tiếp theo 10 tiêu chuẩn sản phẩm do giảng viên ban hành. |

---

## 3. CÁC HẠNG MỤC LOẠI BỎ KHỎI TÀI LIỆU (DEPRECATED & PRUNED ITEMS)

1. **Loại bỏ 10 mã Google Stitch Screen hư cấu:**
   - Các mã ID không có thực trên máy chủ Stitch: `060370631d8745588efc3fa00cb31238`, `c5fbb20c328f416ba4ea4904bf03a0ef`, `4c5db70c9dd942f6aa1cc738a1f81d11`, `6bc265c71bba4fe7946927da8e15d8f6`, `0ff325e0192e44d59178ad3a6fc4d334`, `b2c58a5da7994917992797e87df3323a`, `173367f0f6664d6dbef20a232777b720`, `75f63d043f654b9d885a5be7f6f595df`, `9b42247fb42646b998cf7784013ffeb8`, `1f531aa938c8452394cb58dd88800539`.
2. **Loại bỏ tuyên bố hoàn thành đối với các module chưa viết mã:**
   - Phân hệ Bài tập & Nộp bài (`assignments`, `assignment_submissions`).
   - Phân hệ Sổ điểm & Bảng điểm sinh viên (`student_grades`, `grade_components`).
   - Phân hệ Nhóm chat lớp học và Tin nhắn trao đổi (`chat_groups`, `chat_messages`).
   - Phân hệ Trợ lý ảo Chatbot AI (`ai_chat_sessions`, `ai_chat_messages`).
   - Phân hệ Đơn xin nghỉ phép và Khiếu nại học vụ (`academic_requests`, `schedule_requests`).
3. **Loại bỏ thông tin cấu hình nhạy cảm:**
   - Triệt tiêu hoàn toàn việc đưa chuỗi JWT secret, mật khẩu cơ sở dữ liệu thật vào tài liệu. Mọi cấu hình đều được hướng dẫn thông qua tệp `.env.example`.
