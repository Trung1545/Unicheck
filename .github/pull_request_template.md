## 📌 1. Mục đích Pull Request (PR Purpose)
<!-- Tóm tắt ngắn gọn mục đích của PR: sửa lỗi gì, thêm tính năng nào, hoặc refactor thành phần nào -->
- [ ] Thêm tính năng mới (New feature)
- [ ] Sửa lỗi (Bug fix)
- [ ] Tối ưu / Tái cấu trúc mã nguồn (Refactoring / Optimization)
- [ ] Cập nhật tài liệu / Cấu hình CI/CD (Docs / Chore)

**Mô tả chi tiết:**
> *Ghi rõ tính năng hoặc vấn đề mà PR này giải quyết (liên kết với Issue/Task nếu có).*

---

## 🎯 2. Phạm vi ảnh hưởng (Impact Scope)
- [ ] **Backend (Spring Boot)**
- [ ] **Web Frontend (React + Vite)**
- [ ] **Mobile App (Flutter + GetX)**
- [ ] **AI Service (Python Flask)**
- [ ] **Cơ sở dữ liệu (Flyway Migration)**

---

## 🧪 3. Hướng dẫn kiểm thử (Testing Instructions)
<!-- Liệt kê từng bước để người review có thể kiểm tra và tái hiện kết quả -->
1. **Bước 1**: ...
2. **Bước 2**: ...
3. **Bước 3**: ...

**Kết quả kiểm tra cục bộ:**
- [ ] Unit Test / Integration Test: `Pass`
- [ ] Lint / Static Analysis: `Pass`
- [ ] Build thành công không có lỗi hoặc cảnh báo nghiêm trọng.

---

## 🖼️ 4. Ảnh chụp hoặc Video minh họa (Screenshots / Recordings)
<!-- Bắt buộc nếu thay đổi có liên quan đến giao diện Web hoặc Mobile -->
*(Kéo thả ảnh hoặc video demo giao diện tại đây nếu có)*

| Trước thay đổi (Before) | Sau thay đổi (After) |
| :---: | :---: |
| *(Ảnh cũ nếu có)* | *(Ảnh mới)* |

---

## ✅ 5. Checklist trước khi Merge
- [ ] Nhánh tính năng được đặt đúng chuẩn: `feature/<module>-<mô tả>`
- [ ] Commit message tuân theo quy ước Conventional Commits (`feat(scope): message`)
- [ ] Đã đọc tài liệu thiết kế trong `docs/` và đảm bảo mã nguồn không lệch thiết kế
- [ ] Không hardcode secret, API key hay thông tin nhạy cảm
- [ ] Đã bổ sung Unit Test / Integration Test cho các thay đổi nghiệp vụ
- [ ] Dữ liệu sinh trắc học tuân thủ quy tắc: chỉ lưu embedding, không lưu ảnh gốc khuôn mặt
