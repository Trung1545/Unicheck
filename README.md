# UniCheck - Hệ Thống Điểm Danh Tự Giác Bằng Nhận Diện Khuôn Mặt

> **Đồ án tốt nghiệp**: Ứng dụng công nghệ thị giác máy tính và nhận diện khuôn mặt tự động (Facial Recognition & Liveness Detection) kết hợp xác thực vị trí (Wi-Fi/QR) phục vụ điểm danh thông minh trong môi trường đại học.

---

## 🏗️ Kiến Trúc Hệ Thống (Architecture Stack)

- **Backend**: Java 21 / 22, Spring Boot 3 (REST API, WebSocket STOMP, Spring Security, JWT).
- **Cơ sở dữ liệu**: PostgreSQL 15 (Quản lý schema 50 bảng bằng **Flyway Migration**, `ddl-auto=validate`).
- **Bộ nhớ đệm (Cache)**: Redis 7.
- **AI Service Microservice**: Python 3.11, Flask, OpenCV (Trích xuất vector khuôn mặt 128 chiều, kiểm tra thực thể Liveness chống giả mạo).
- **Web Frontend**: React 18, Vite, TypeScript, Tailwind CSS, Zustand, Axios.
- **Mobile App**: Flutter, Dart, GetX, Camera.
- **Lưu trữ & Thông báo**: Cloudinary (lưu avatar/tài liệu; *tuyệt đối không lưu ảnh khuôn mặt gốc*), Firebase Cloud Messaging (FCM).
- **Hạ tầng**: Docker Compose.

---

## 🚀 Hướng Dẫn Khởi Chạy Dự Án Trong 5 Bước

### 📋 Yêu cầu tiên quyết (Prerequisites)
- [Docker Desktop](https://www.docker.com/) (đang chạy)
- [Node.js](https://nodejs.org/) (phiên bản 20 trở lên)
- [Java JDK 21+](https://www.oracle.com/java/technologies/downloads/) & [Maven](https://maven.apache.org/) (nếu chạy backend ngoài Docker)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+)

---

### **Bước 1: Thiết lập biến môi trường**
Sao chép file cấu hình mẫu `.env.example` thành `.env` tại thư mục gốc:

```bash
cp .env.example .env
```
*(Chỉnh sửa các tham số nếu cần, mặc định hệ thống đã điền sẵn cấu hình chuẩn cho môi trường dev).*

---

### **Bước 2: Khởi động Backend, Database & AI Service bằng Docker Compose**
Từ thư mục gốc dự án, khởi chạy đồng bộ toàn bộ cụm hạ tầng:

```bash
docker compose up -d --build
```
> Lệnh này sẽ khởi động:
> - **PostgreSQL** (`localhost:5432`)
> - **Redis** (`localhost:6379`)
> - **AI Service** (`http://localhost:5000`)
> - **Spring Boot Backend** (`http://localhost:8080`)

---

### **Bước 3: Kiểm tra trạng thái hoạt động & CSDL**
Đảm bảo các dịch vụ đã sẵn sàng và Flyway đã tự động migrate 50 bảng:

```bash
# Kiểm tra trạng thái các container
docker compose ps

# Kiểm tra sức khỏe của Backend API
curl http://localhost:8080/actuator/health

# Kiểm tra AI Microservice
curl http://localhost:5000/health
```

---

### **Bước 4: Khởi chạy Web Frontend (React + Vite)**
Mở terminal mới, điều hướng vào thư mục `frontend` và chạy:

```bash
cd frontend
npm install
npm run dev
```
👉 Truy cập ứng dụng Web Quản trị tại: **`http://localhost:5173`**

---

### **Bước 5: Khởi chạy Mobile App (Flutter)**
Mở terminal mới, điều hướng vào thư mục `mobile`, kết nối thiết bị/máy ảo và chạy:

```bash
cd mobile
flutter pub get
flutter run
```
👉 Ứng dụng di động sinh viên sẽ mở lên với giao diện quét nhận diện khuôn mặt và điểm danh.

---

## 🔒 Quy Ước Bảo Mật Dữ Liệu Sinh Trắc Học (Biometric Privacy)

- Hệ thống tuân thủ nghiêm ngặt nguyên tắc bảo mật sinh trắc học quốc tế: **Tuyệt đối không lưu trữ ảnh khuôn mặt gốc của sinh viên trong cơ sở dữ liệu**.
- Ảnh chụp từ camera chỉ được truyền tạm thời vào AI Service để kiểm tra liveness và trích xuất vector đặc trưng số học (128-dimensional embedding).
- CSDL chỉ lưu trữ mảng vector số trong bảng `face_encodings` để phục vụ tính toán khoảng cách cosine khi điểm danh.

---

## 👥 Quy Trình Làm Việc Nhóm & Đóng Góp (Git Workflow)

1. **Mô hình nhánh**:
   - `main`: Phiên bản sản phẩm ổn định nhất (Production-ready).
   - `develop`: Nhánh tích hợp tính năng (Integration/Staging).
   - Nhánh tính năng: `feature/<module>-<mô tả>` (ví dụ: `feature/auth-jwt-login`).
2. **Quy ước Commit**: Chuẩn Conventional Commits `feat(backend): ...`, `fix(web): ...`.
3. **Mẫu Pull Request**: Xem chi tiết tại [CONTRIBUTING.md](CONTRIBUTING.md) và [.github/pull_request_template.md](.github/pull_request_template.md).
4. **CI/CD Tự Động**: GitHub Actions tự động kiểm tra build & test riêng biệt theo từng thư mục thay đổi (`dorny/paths-filter`).
