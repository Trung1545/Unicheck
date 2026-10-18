# UniCheck — Tiêu Chuẩn Hoàn Thành (Definition of Done - DoD)

> **Mã tài liệu:** IMPL-DOD-2026  
> **Phiên bản:** 1.0.0  
> **Áp dụng cho:** Toàn bộ các module Web (React), Mobile (Flutter), Backend (Spring Boot), AI Service (Flask) và Hạ tầng (Docker/PostgreSQL/Redis).  
> **Tuyên ngôn cốt lõi:** *"Một tính năng chưa được viết kiểm thử tự động hoặc chưa chạy thực tế thành công thì được coi là CHƯA HOÀN THÀNH. Không có ngoại lệ."*

---

## 1. Tiêu Chuẩn Đánh Giá Trạng Thái Tính Năng (Status Criteria)

Mỗi chức năng trong UniCheck chỉ được phép gán nhãn trạng thái khi thỏa mãn đầy đủ các điều kiện khắt khe sau:

| Nhãn Trạng Thái | Điều Kiện Bắt Buộc Để Đạt Trạng Thái |
| :--- | :--- |
| **`DONE`** | 1. Đầy đủ mã nguồn ở cả Client và Server (nếu tính năng hai chiều).<br/>2. Đã kết nối với Database hoặc AI Service thật.<br/>3. **Có bằng chứng kiểm thử tự động (Unit / Integration Tests) chạy thành công (Exit 0).**<br/>4. Giao diện khớp 100% với màn hình Stitch thiết kế.<br/>5. Không chứa log nhạy cảm hoặc secret hardcoded. |
| **`BACKEND_ONLY`** | 1. Entity, Repository, Service và Controller đã hoàn thiện và chạy test passed.<br/>2. Giao diện phía Frontend hoặc Mobile chưa được xây dựng hoặc chưa gọi API này. |
| **`UI_ONLY`** | 1. Đã có Component giao diện theo Stitch hoặc Flutter widget.<br/>2. Dữ liệu bên trong hoàn toàn là dữ liệu giả (hardcoded mock state), chưa gọi API thật. |
| **`MOCK_ONLY`** | 1. Hệ thống có trả về dữ liệu qua HTTP API nhưng là dữ liệu giả lập (ví dụ: AI vector `[0.0]*128`, liveness `0.96` cố định). |
| **`PARTIAL`** | 1. Đã có một số thành phần nền móng (ví dụ: đã có bảng DB và Entity JPA nhưng chưa có Controller/Service). |
| **`BLOCKED`** | 1. Không thể tiếp tục do thiếu thư viện phần cứng, thiếu môi trường hoặc bị chặn bởi lỗi của tầng phụ thuộc. |
| **`NOT_STARTED`** | 1. Chưa có bất kỳ dòng code logic nào được viết cho tính năng này. |

---

## 2. Tiêu Chuẩn Nghiệm Thu Từng Tầng Kỹ Thuật

### 2.1. Tầng Giao Diện Web React & Google Stitch
1. **Chuẩn Nhận Diện Thương Hiệu:** Tuân thủ bộ màu **Academic Precision** (Royal Blue `#1D4ED8`, Emerald `#10B981`, Slate `#0F172A`, Background Gray `#F8FAFC`).
2. **Tái Sử Dụng Thành Phần Chuẩn:** Bắt buộc tái sử dụng các Atomic Component trong [`frontend/src/common-ui/`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/common-ui) (`Button`, `Table`, `StatCard`, `Badge`, `Modal`, `Pagination`, `Input`, `Select`). Không viết style tùy tiện phá vỡ cấu trúc chung.
3. **Responsive Design:** Giao diện co giãn chuẩn xác theo tỷ lệ màn hình Desktop và Laptop, không bị vỡ layout ở độ phân giải tối thiểu 1280px.
4. **Xử Lý Trạng Thái Toàn Diện:** Mỗi màn hình bắt buộc phải có đầy đủ 4 trạng thái:
   - *Loading State:* Hiển thị Skeleton hoặc Spinner mượt mà.
   - *Success / Data State:* Dữ liệu hiển thị chuẩn bảng học thuật.
   - *Empty State:* Hình minh họa và thông điệp hướng dẫn rõ ràng khi chưa có dữ liệu.
   - *Error State:* Banner cảnh báo thân thiện tiếng Việt kèm nút thử lại (Retry).
5. **Type Safety & Build:** `npm run build` biên dịch thành công với **0 lỗi TypeScript**.

---

### 2.2. Tầng Backend API Spring Boot
1. **Hợp Đồng Dữ Liệu Đồng Nhất:** Mọi phản hồi API bắt buộc bọc trong cấu trúc chuẩn `ApiResponse<T>`:
   ```json
   {
     "success": true,
     "data": { ... },
     "message": "Thông báo thân thiện tiếng Việt",
     "errorCode": null
   }
   ```
2. **Bảo Mật & Phân Quyền:**
   - 100% endpoint nghiệp vụ được bảo vệ bởi Spring Security và phân quyền `@PreAuthorize("hasRole('ADMIN')")` hoặc tương đương.
   - Không được phép rò rỉ stack trace Java ra ngoài client khi gặp exception (bắt buộc qua `GlobalExceptionHandler`).
   - Token hết hạn hoặc không hợp lệ phải trả về đúng mã lỗi `ERR_1002` hoặc `ERR_1004` (HTTP 401).
3. **Không Ghi Secret Vào Log:** Tuyệt đối không log mật khẩu, mã OTP gốc (phải mask dạng `[******]`), token JWT (phải hash SHA-256) hoặc vector sinh trắc học vào file log hoặc console.
4. **Kiểm Thử Bắt Buộc:** Mỗi Controller mới phải có ít nhất 1 Integration Test (MockMvc) kiểm tra luồng thành công (200/201) và luồng từ chối quyền (401/403). `mvn test` phải đạt **100% Pass**.

---

### 2.3. Tầng Cơ Sở Dữ Liệu PostgreSQL & Flyway
1. **Tuân Thủ Migration:** Không chỉnh sửa các migration V1, V2, V3 đã áp dụng vào production. Mọi thay đổi schema mới bắt buộc tạo migration mới (`V4__...sql`).
2. **Toàn Vẹn Dữ Liệu:** Đảm bảo khóa ngoại `ON DELETE CASCADE` hoặc `ON DELETE SET NULL` hợp lý; mọi cột tra cứu thường xuyên (`code`, `username`, `email`, `status`, `class_name`) phải có Index.
3. **Transaction Boundary:** Các thao tác ghi nhiều bảng (ví dụ: tạo lớp học kèm phân công giảng viên, ghi nhận điểm danh kèm cập nhật số lượng) phải có `@Transactional`.

---

### 2.4. Tầng Trí Tuệ Nhân Tạo (AI Service)
1. **Không Sử Dụng Vector Giả Lập:** Khi đưa vào vận hành điểm danh, AI Microservice bắt buộc trích xuất vector 512-dim thực từ mô hình deep learning.
2. **Cấu Hình Động Ngưỡng (Threshold):** Ngưỡng Cosine Similarity và Liveness Score không được hardcode mà phải đọc từ biến môi trường hoặc bảng cấu hình `attendance_configs`.
3. **Xử Lý Lỗi Rõ Ràng:** Trả về mã lỗi chuẩn khi ảnh không đạt tiêu chuẩn (`ERR_3001: FACE_NOT_DETECTED`, `ERR_3002: MULTIPLE_FACES_DETECTED`, `ERR_3003: FACE_LIVENESS_FAILED`).

---

### 2.5. Tầng Ứng Dụng Di Động (Flutter Mobile)
1. **Phân Quyền Thiết Bị An Toàn:** Xin quyền Camera và Vị trí (GPS) trước khi truy cập; hiển thị màn hình hướng dẫn thân thiện nếu người dùng từ chối quyền.
2. **Xử Lý Sự Cố Kết Nối:** Bắt lỗi mất kết nối mạng và hiển thị thông báo offline; tự động làm mới token qua Interceptor khi nhận mã 401.
3. **Code Analysis:** `flutter analyze` đạt **0 issues** và `flutter test` pass toàn bộ.

---

## 3. Quy Trình Kiểm Duyệt (Sign-off Checklist Cho Từng Task)

Trước khi đóng một Task trong Hàng đợi công việc, Technical Lead phải kiểm tra 6 tiêu chí:
- [ ] 1. Mã nguồn tuân thủ kiến trúc phân tầng (Controller -> Service -> Repository / Store -> Component).
- [ ] 2. Đã chạy build cục bộ thành công không có lỗi biên dịch.
- [ ] 3. Kiểm thử tự động liên quan đã được viết và pass.
- [ ] 4. Giao diện đối chiếu khớp với bản thiết kế Stitch tương ứng.
- [ ] 5. Đã kiểm tra tính an toàn thông tin (không rò rỉ secret, không vi phạm CORS).
- [ ] 6. Cập nhật trạng thái chính xác vào `FEATURE_MATRIX.md`.
