# Quy trình Làm Việc Nhóm Dự Án UniCheck

Tài liệu này quy định tiêu chuẩn phát triển phần mềm, phân nhánh Git, quy ước commit message và quy trình review cho các thành viên trong nhóm dự án tốt nghiệp **UniCheck**.

---

## 1. Chiến lược phân nhánh Git (Branching Strategy)

Dự án áp dụng mô hình biến thể Git Flow tinh gọn:

### 1.1. Các nhánh chính (Primary Branches)
- **`main`**: Nhánh chính chứa mã nguồn phiên bản sản phẩm ổn định nhất (Production-ready). Chỉ nhận merge từ nhánh `develop` thông qua Pull Request có kiểm thử toàn diện.
- **`develop`**: Nhánh tích hợp chính (Integration / Staging). Toàn bộ tính năng mới sau khi hoàn thành sẽ được merge vào nhánh này.

### 1.2. Nhánh tính năng và sửa lỗi (Supporting Branches)
Mọi thành viên **tuyệt đối không commit trực tiếp** lên nhánh `main` hoặc `develop`. Mỗi đầu việc phải tạo một nhánh riêng từ `develop`:

| Loại nhánh | Định dạng đặt tên | Ví dụ thực tế |
| :--- | :--- | :--- |
| **Tính năng mới** | `feature/<module>-<mô-tả-ngắn>` | `feature/auth-jwt-login`, `feature/attendance-face-scan`, `feature/schedule-timetable-view` |
| **Sửa lỗi thường** | `bugfix/<module>-<mô-tả-ngắn>` | `bugfix/mobile-camera-permission`, `bugfix/backend-flyway-v2` |
| **Sửa lỗi khẩn cấp** | `hotfix/<mô-tả-ngắn>` | `hotfix/jwt-expiration-timezone` |

---

## 2. Quy ước Commit Message (Conventional Commits)

Commit message bắt buộc tuân theo định dạng chuẩn:
```
<type>(<scope>): <mô tả ngắn bằng tiếng Việt hoặc tiếng Anh>
```

### 2.1. Các loại Type hợp lệ:
- **`feat`**: Thêm một tính năng mới cho người dùng hoặc API.
- **`fix`**: Sửa một lỗi (bug) trong mã nguồn.
- **`docs`**: Thay đổi hoặc bổ sung tài liệu kỹ thuật, README.
- **`style`**: Định dạng code, dấu cách, chấm phẩy (không ảnh hưởng logic thực thi).
- **`refactor`**: Tái cấu trúc code (không sửa bug cũng không thêm tính năng).
- **`test`**: Bổ sung hoặc cập nhật unit test, integration test.
- **`chore`**: Cấu hình build tool, CI/CD, cập nhật dependencies.

### 2.2. Scope quy định theo module:
- `backend`: Java Spring Boot backend
- `web`: React frontend
- `mobile`: Flutter mobile app
- `ai`: Python AI microservice
- `db`: Flyway database migrations
- `ci`: GitHub Actions pipeline

### 2.3. Ví dụ commit chuẩn:
```bash
git commit -m "feat(backend): implement jwt login and user authentication service"
git commit -m "feat(ai): integrate opencv liveness eye-blink detection"
git commit -m "fix(mobile): resolve front camera orientation issue on android"
git commit -m "test(backend): add integration test for face check-in api"
git commit -m "chore(ci): configure github actions path filters"
```

---

## 3. Quy trình Tạo Pull Request & Code Review

1. **Chuẩn bị trước khi mở PR**:
   - Chạy kiểm tra build và test cục bộ (backend: `mvn clean test`, web: `npm run build`, mobile: `flutter analyze`, ai: `pytest`).
   - Đảm bảo mã nguồn bám sát tài liệu thiết kế trong thư mục `docs/`.
   - Đối chiếu quy ước sinh trắc học: *Chỉ lưu trữ face embedding vector, tuyệt đối không lưu ảnh khuôn mặt thô trong database*.
2. **Mở Pull Request**:
   - Target branch: luôn chọn `develop` (trừ khi hotfix vào `main`).
   - Điền đầy đủ thông tin theo mẫu template có sẵn (`.github/pull_request_template.md`).
   - Bắt buộc đính kèm ảnh chụp màn hình hoặc video nếu có thay đổi về giao diện Web/Mobile.
3. **Quy định Merge**:
   - Toàn bộ pipeline kiểm tra tự động của GitHub Actions phải **Pass (Xanh)**.
   - Cần ít nhất **1 thành viên khác (hoặc Lead Engineer)** review và phê duyệt (Approve).
