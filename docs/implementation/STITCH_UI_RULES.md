# UniCheck — Quy Tắc Thực Thi Giao Diện Chuẩn Google Stitch (Stitch UI Rules)

> **Mã tài liệu:** IMPL-STITCH-UI-RULES-2026  
> **Dự án Stitch ID:** `3214444012266330806`  
> **Bộ nhận diện chuẩn:** Academic Precision Design System  
> **Tuyên ngôn cốt lõi:** *"Google Stitch là nguồn chuẩn duy nhất về hình thức giao diện. Mọi màn hình React Web đều phải phản ánh trung thực thiết kế Stitch, không tự ý sáng tác, không thay thế bằng template chung."*

---

## 1. Bảng Mã Màu & Tokens Thiết Kế (Academic Precision Color Tokens)

Tất cả các thành phần giao diện phải sử dụng các tokens màu đồng bộ đã được cấu hình trong `tailwind.config.js`:

```css
:root {
  /* Màu chủ đạo (Primary - Royal Academic Blue) */
  --color-primary-50:  #EFF6FF;
  --color-primary-100: #DBEAFE;
  --color-primary-600: #2563EB;
  --color-primary-700: #1D4ED8; /* Màu thương hiệu cốt lõi */
  --color-primary-800: #1E40AF; /* Hover state */

  /* Màu bổ trợ thành công & sinh trắc học (Secondary - Academic Emerald) */
  --color-success-50:  #ECFDF5;
  --color-success-500: #10B981; /* Trạng thái 'Đã điểm danh' / 'Hợp lệ' */
  --color-success-700: #047857;

  /* Màu cảnh báo & điểm danh bù (Warning - Academic Amber) */
  --color-warning-50:  #FFFBEB;
  --color-warning-500: #F59E0B; /* Trạng thái 'Đi trễ' / 'Cần xác minh' */
  --color-warning-700: #B45309;

  /* Màu nguy hiểm & gian lận (Danger - Academic Rose/Red) */
  --color-danger-50:   #FEF2F2;
  --color-danger-500:  #EF4444; /* Trạng thái 'Vắng mặt' / 'Cảnh báo gian lận' */
  --color-danger-700:  #B91C1C;

  /* Nền tảng trung tính (Neutrals - Academic Slate) */
  --color-slate-50:    #F8FAFC; /* Màu nền trang chung (Page Background) */
  --color-slate-100:   #F1F5F9; /* Màu nền Sidebar / Header phụ */
  --color-slate-200:   #E2E8F0; /* Đường viền thẻ & bảng (Card & Table Border) */
  --color-slate-500:   #64748B; /* Nhãn phụ, placeholder */
  --color-slate-900:   #0F172A; /* Tiêu đề & nội dung chính (Heading & Body Text) */
}
```

---

## 2. Tiêu Chuẩn Typography & Spacing

* **Phông chữ chuẩn:** `Inter`, `Roboto`, hệ phông `sans-serif` học thuật hiện đại.
* **Cấp bậc Tiêu đề (Hierarchy):**
  - **Page Heading (H1):** `text-2xl font-bold text-slate-900 tracking-tight`.
  - **Section Title (H2):** `text-lg font-semibold text-slate-800`.
  - **Card Title / Subtitle:** `text-sm font-medium text-slate-600`.
  - **Table Cell / Body Text:** `text-sm text-slate-700`.
  - **Meta / Timestamp / Badge Text:** `text-xs font-medium`.
* **Đường viền & Đổ bóng (Border & Shadow):**
  - Border bán kính: `rounded-lg` (8px) hoặc `rounded-xl` (12px) cho Cards và Modals.
  - Border width: `border border-slate-200`.
  - Shadow: Nhẹ nhàng, tinh tế dạng `shadow-sm`, hạn chế dùng shadow quá đậm.

---

## 3. Thư Viện Thành Phần Tái Sử Dụng Bắt Buộc (`common-ui/`)

Khi dựng 33 màn hình Stitch còn lại, bắt buộc sử dụng các thành phần đã được chuẩn hóa tại [`frontend/src/common-ui/`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/common-ui):

| Thành Phần | Tệp Nguồn | Vai Trò & Hướng Dẫn Sử Dụng |
| :--- | :--- | :--- |
| **`Button`** | [Button.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/common-ui/Button.tsx) | Hỗ trợ 4 variants: `primary`, `secondary`, `danger`, `outline`. Luôn có prop `isLoading` khi gửi request API. |
| **`Table`** | [Table.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/common-ui/Table.tsx) | Bảng học thuật chuẩn: Header xám nhạt `bg-slate-50`, hover từng hàng `hover:bg-slate-50/70`, phân cách dòng `divide-y divide-slate-100`. |
| **`StatCard`** | [StatCard.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/common-ui/StatCard.tsx) | Thẻ hiển thị chỉ số thống kê (Tổng sinh viên, Tỷ lệ chuyên cần, Lớp đang mở) kèm icon và xu hướng tăng/giảm. |
| **`Badge`** | [Badge.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/common-ui/Badge.tsx) | Hiển thị nhãn trạng thái sinh viên/vai trò: `success` (Có mặt), `danger` (Vắng), `warning` (Trễ), `info` (Đã duyệt). |
| **`Modal`** | [Modal.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/common-ui/Modal.tsx) | Hộp thoại thao tác (Thêm sinh viên, Chi tiết phiên điểm danh, Cảnh báo gian lận). Hỗ trợ đóng bằng Escape và Backdrop. |
| **`Pagination`** | [Pagination.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/common-ui/Pagination.tsx) | Điều hướng phân trang bảng dữ liệu: Trang trước/sau, danh sách số trang, tổng số bản ghi. |
| **`Input` & `Select`** | `Input.tsx`, `Select.tsx` | Ô nhập liệu và bộ lọc dropdown có label, error message tiếng Việt và icon tích hợp. |

---

## 4. Cấu Trúc Khung Khung Bố Cục (Layout Architecture)

Mọi trang nghiệp vụ sau khi đăng nhập đều nằm trong khung [MainLayout.tsx](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/frontend/src/layouts/MainLayout.tsx):
- **Cột Trái (Sidebar):** Rộng 260px cố định, hiển thị logo UniCheck, danh mục menu điều hướng phân tầng theo Role (`ADMIN`, `LECTURER`, `STUDENT`).
- **Phía Trên (Header):** Cao 64px, hiển thị Breadcrumbs, ô tìm kiếm nhanh toàn hệ thống, chuông thông báo (Notification Badge) và Profile Dropdown.
- **Khu Vực Trung Tâm (Content Area):** Tự động cuộn `overflow-y-auto`, khoảng cách đệm `p-6` hoặc `p-8`, màu nền nền tảng `bg-slate-50`.

```
+-------------------------------------------------------------------+
|  Logo UniCheck  |  Header: Breadcrumbs, Search, Alert, Avatar     |
+-----------------+-------------------------------------------------+
|                 |                                                 |
|  Sidebar Menu   |  Main Content: Page Title & Actions             |
|  - Tổng quan    |  ---------------------------------------------  |
|  - Người dùng   |  [ StatCard 1 ] [ StatCard 2 ] [ StatCard 3 ]   |
|  - Lớp học      |                                                 |
|  - Điểm danh    |  +-------------------------------------------+  |
|  - Báo cáo      |  | Table: Data with Filter & Pagination      |  |
|  - Cấu hình     |  +-------------------------------------------+  |
|                 |                                                 |
+-------------------------------------------------------------------+
```

---

## 5. Quy Tắc Ứng Xử Khi Kết Nối & Đọc Thiết Kế Stitch

1. **Tuyệt Đối Không Phỏng Đoán Screen ID:** Khi lập trình màn hình mới, bắt buộc đối chiếu ID từ tệp [`docs/audit/VERIFIED_STITCH_MAPPING.md`](file:///c:/Users/Admin/Documents/Antigravity/UniCheck/docs/audit/VERIFIED_STITCH_MAPPING.md).
2. **Không Tự Thay Đổi Vị Trí Thành Phần:** Nếu thiết kế Stitch đặt bộ lọc bên phải tiêu đề, không tự ý chuyển xuống dưới; nếu Stitch dùng Modal, không tự ý đổi sang trang riêng.
3. **Không Sử Dụng Ảnh Placeholder Ảo:** Mọi hình ảnh (Avatar mẫu, biểu đồ minh họa) phải dùng component SVG trực tiếp hoặc tạo asset rõ ràng.
4. **Báo Lỗi Rõ Ràng Khi Mất Kết Nối:** Nếu công cụ Stitch MCP không thể tải về HTML/Screenshot của một màn hình, kỹ sư phải ghi nhận lỗi kết nối cụ thể và yêu cầu tải lại, không tự ý bịa đặt giao diện khác biệt.
