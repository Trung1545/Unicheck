# NHẬT KÝ THAY ĐỔI VÀ HIỆU CHỈNH THIẾT KẾ PHẦN MỀM
## UNICHECK SOFTWARE DESIGN DOCUMENT (SDD) CHANGELOG
**Dự án:** UniCheck — Hệ thống Điểm danh Sinh trắc học Đa nền tảng  
**Tài liệu gốc:** `UniCheck_Software_Design_Document(1).docx` (Report 4 — May 2026)  
**Tài liệu hiện tại:** `UniCheck_SDD_Final.md` / `UniCheck_SDD_Final.docx` (Version 2.1 — October 2026)  

---

## 1. TỔNG QUAN LỊCH SỬ PHIÊN BẢN (VERSION HISTORY)

| Phiên bản | Ngày hoàn thành | Người thực hiện | Tóm tắt nội dung thay đổi chính |
|:---:|:---:|:---|:---|
| **v1.0** | Tháng 05 / 2026 | Nhóm Đồ án UniCheck | Khởi tạo Báo cáo Thiết kế Phần mềm (Report 4, 119 trang): Thiết kế kiến trúc tổng thể, 5 Package Diagrams, ERD 50 bảng CSDL, và chi tiết 21 phân hệ với 161 hình vẽ (Class & Sequence Diagrams). |
| **v2.0** | Đầu tháng 10 / 2026 | Ban Kỹ thuật & Kiến trúc | Rà soát toàn bộ kho mã nguồn thực tế (React, Flutter, Spring Boot, Flask AI, PostgreSQL, Redis). Bắt đầu chuẩn hóa lại các luồng dữ liệu thực tế và phân loại trạng thái triển khai. |
| **v2.1** | Tháng 10 / 2026 | Nhóm Kiến trúc & Đảm bảo Chất lượng | **Bản chuẩn hóa toàn diện (Final Milestone):**<br>- Giữ nguyên vẹn 21 phân hệ từ Report 4, phân loại trạng thái minh bạch (`IMPLEMENTED & TESTED`, `PARTIAL`, `PLANNED DESIGN`).<br>- Cập nhật công nghệ AI thực tế: YuNet + Dual Ensemble MiniFASNet + ArcFace MobileFaceNet 512D (loại bỏ mô tả chung chung).<br>- Đồng bộ quy trình Face Enrollment: Luồng 3 bước quay đầu thời gian thực (Trực diện, Trái, Phải) qua Google ML Kit.<br>- Đồng bộ mô hình dữ liệu: Phân tách 25 thực thể JPA đang chạy và 25 bảng CSDL Flyway mở rộng.<br>- Chuẩn hóa cơ chế bảo vệ sinh trắc học: Lưu trữ vector đặc trưng dạng nhị phân 2048 bytes BYTEA, không lưu trữ ảnh khuôn mặt thô (`face_image = NULL`).<br>- Xóa bỏ các dịch vụ giả định (Cloudinary, Firebase, WebSocket, OpenRouter) chưa có trong mã nguồn.<br>- Đồng bộ hóa kết quả kiểm thử thực chứng: 281/281 Automated Tests passed. |

---

## 2. BẢNG HIỆU CHỈNH CHI TIẾT THEO TỪNG CHƯƠNG VÀ PHÂN HỆ

| Mục / Chương | Nội dung trong bản cũ (v1.0) | Nội dung hiệu chỉnh trong bản chuẩn hóa (v2.1) | Lý do kỹ thuật & Căn cứ mã nguồn |
|:---|:---|:---|:---|
| **Chương 1: Tổng quan Hệ thống** | Giới thiệu hệ thống chung chung; liệt kê nhiều công nghệ đám mây thương mại. | Cập nhật cấu hình công nghệ chuẩn xác: Java 22 / Spring Boot 3.3.4, React 18.3.1 / TypeScript 5.6.2 / Vite, Flutter 3.27 / GetX, Python 3.11 / Flask 3.1 / ONNX Runtime, PostgreSQL 15, Redis 7. | Phản ánh chính xác cấu hình trong `pom.xml`, `package.json`, `pubspec.yaml` và `requirements.txt`. |
| **Chương 2: Kiến trúc Hệ thống** | Mô tả sơ lược kiến trúc phân tán; thiếu chi tiết về giao thức nội bộ và định tuyến. | Cập nhật Component Diagram 4 khối phân tầng rõ ràng; bổ sung chi tiết **Dual-Route Architecture** (`/api/v1/*` và `/api/*`); phân tích luồng dữ liệu thời gian thực giữa Mobile, Spring Boot và AI Microservice. | Căn cứ `SecurityConfig.java`, các Controller và cấu hình Docker Compose thực tế. |
| **Chương 3: Thiết kế Gói (Package Design)** | 4 Package Diagrams trong Report 4 có một số tên package chưa đồng nhất với cấu trúc thư mục code. | Vẽ lại và cập nhật chính xác 4 Package Diagrams cho Web Frontend (`src/pages`, `src/components`, `src/services`, `src/stores`), Mobile Client (`lib/views`, `lib/controllers`, `lib/bindings`, `lib/api`), Backend (`controllers`, `services`, `repositories`, `entities`, `security`), và AI Service (`face_engine`, `face_detector`, `liveness_engine`, `face_matcher`). | Đồng bộ 100% với cấu trúc cây thư mục mã nguồn thực tế. |
| **Chương 4: Thiết kế CSDL (Database Design)** | Trình bày 50 bảng nhưng không nêu rõ bảng nào đã có entity JPA, bảng nào thuộc schema Flyway. | Phân định minh bạch: **25 bảng cốt lõi** đã ánh xạ JPA Entity và đang vận hành; **25 bảng mở rộng** đã có trong Flyway DDL nhưng chưa tạo Entity (xếp vào Planned Schema). Chi tiết hóa cấu trúc lưu trữ `BYTEA (2048 bytes)` cho vector khuôn mặt và nguyên tắc xóa ảnh thô. | Căn cứ 25 tệp Entity trong `backend/src/main/java/.../entity` và 7 tệp script Flyway `V1..V7`. |
| **Chương 5: Thiết kế Chi tiết 21 Module** | Mô tả 21 phân hệ ở trạng thái thiết kế lý thuyết, một số sơ đồ tuần tự chưa khớp với endpoint thực tế. | Kế thừa trọn vẹn toàn bộ 21 phân hệ và các sơ đồ lớp/tuần tự; đối với các phân hệ đã triển khai, cập nhật chính xác tên Controller, Service, DTO, Endpoint và trạng thái kiểm thử; đối với các phân hệ chưa triển khai, đánh dấu rõ `PLANNED DESIGN / FUTURE EXTENSION`. | Tuân thủ nguyên tắc không bỏ rơi thiết kế cũ, đồng thời phản ánh trung thực tiến độ hiện tại. |
| **Chương 6: Thiết kế Phân hệ AI FaceID** | Mô tả đơn giản việc nhận diện khuôn mặt; không có thông số kỹ thuật mô hình AI. | Chi tiết hóa toàn bộ pipeline AI: Thuật toán YuNet (Face Detection & Landmarks), Dual Ensemble MiniFASNet (Anti-spoofing Softmax 3 lớp, ngưỡng 0.70), ArcFace MobileFaceNet (512D embedding, Cosine threshold 0.68), cơ chế Fail-Closed trả về lỗi 503/400, độ trễ đo kiểm thực tế 11.53ms trên CPU. Luồng Face Enrollment 3 bước thời gian thực (Euler angles qua Google ML Kit). | Căn cứ `face_detector.py`, `liveness_engine.py`, `face_matcher.py`, `face_engine.py`, `head_pose_evaluator.dart`. |
| **Chương 7: Thiết kế Phân hệ Điểm danh** | Mô tả quy trình điểm danh chung chung; chưa nêu rõ giải pháp chống gian lận đa nhân tố. | Chi tiết hóa State Machine vòng đời phiên điểm danh (`SCHEDULED -> ACTIVE -> COMPLETED / CANCELLED`); cơ chế chống gian lận đa nhân tố: Face Liveness + Tọa độ GPS Geofencing ($R \le 50\text{m}$) + Đối chiếu WiFi BSSID mạng trường; giải pháp ngăn chặn trùng lặp bằng ràng buộc CSDL và khóa phân tán; cơ chế điều chỉnh thủ công cho giảng viên; xuất báo cáo Excel qua Apache POI. | Căn cứ `AttendanceSession.java`, `AttendanceRecord.java`, `AttendanceConfig.java`, `Yeucau_DuAn_DiemDanh_FaceID.docx`. |
| **Chương 8: Thiết kế Giao diện Người dùng** | Ảnh chụp màn hình từ các bản phác thảo Stitch cũ. | Phân tích đối chiếu giữa bản thiết kế giao diện và màn hình React/Flutter đang chạy: 18 trang Web React (12 trang kết nối API thật, Dashboard có mock thống kê), 5 màn hình Flutter chuyên biệt cho Sinh viên. | Căn cứ các thư mục `frontend/src/pages` và `mobile/lib/views`. |
| **Chương 9: Thiết kế An toàn & Bảo mật** | Đề cập đến bảo mật nhưng chưa có chi tiết kỹ thuật chuyên sâu. | Bổ sung thiết kế bảo mật toàn diện: Cơ chế Dual Token JWT với RTR (Refresh Token Rotation) chống tấn công Replay; mã hóa mật khẩu một chiều BCrypt; bảo vệ quyền riêng tư sinh trắc học theo ISO 27001 / GDPR (không lưu ảnh mặt); phòng chống SQL Injection qua JPA Prepared Statements; cơ chế Fail-Closed từ chối điểm danh khi AI suy luận không hợp lệ. | Căn cứ `SecurityConfig.java`, `JwtTokenProvider.java`, `app.py`. |
| **Chương 10: Thiết kế Triển khai & Vận hành** | Chưa có mô hình triển khai cụ thể bằng container. | Thiết kế cấu hình triển khai Docker Compose chuẩn hóa với 5 dịch vụ (`postgres`, `redis`, `backend`, `ai-service`, `frontend`); sơ đồ mạng nội bộ Docker; quản trị biến môi trường; cơ chế Health Check và thứ tự khởi chạy phụ thuộc (`depends_on`). | Căn cứ tệp `docker-compose.yml` và các `Dockerfile` trong kho lưu trữ. |
| **Chương 11: Kiểm tra & Đánh giá Thiết kế** | Chưa có chương kiểm chứng kiến trúc. | Tổng hợp ma trận truy vết yêu cầu (Traceability Matrix); đánh giá tính nhất quán kiến trúc; tổng hợp bằng chứng 281/281 automated tests; phân tích các món nợ kỹ thuật (Technical Debt) và lộ trình hoàn thiện cho các phân hệ mở rộng. | Đảm bảo tính học thuật và tiêu chuẩn nghiệm thu đồ án chuyên ngành CNTT. |

---

## 3. CÁC ĐIỀU CHỈNH QUAN TRỌNG VỀ DANH MỤC THUẬT NGỮ VÀ KHÁI NIỆM

1. **Khái niệm "Microservices" được chuẩn hóa thành "Hybrid Distributed Modular Architecture":**
   - Bản cũ gọi toàn bộ hệ thống là Microservices nhưng thực chất Backend Spring Boot là một dịch vụ nguyên khối được tổ chức module hóa (Modular Monolith), kết nối với AI Microservice độc lập qua REST HTTP. Bản v2.1 dùng thuật ngữ kiến trúc chuẩn xác này.
2. **Loại bỏ việc gán nhãn hoàn thành cho các dịch vụ bên ngoài chưa tích hợp:**
   - Các dịch vụ Cloudinary, Firebase Cloud Messaging, OpenRouter LLM, và WebSocket STOMP được chuyển đổi từ vị trí "thành phần đang chạy" sang "khung thiết kế định hướng mở rộng", giữ cho tài liệu sự trung thực tuyệt đối.
3. **Chuẩn hóa thông số kỹ thuật FaceID:**
   - Thay thế các khẳng định chung chung bằng các con số kỹ thuật thực chứng: Vector 512 chiều, Cosine threshold 0.68, Liveness threshold 0.70, YuNet threshold 0.60, kích thước lưu trữ 2048 bytes BYTEA, độ trễ 11.53ms.
