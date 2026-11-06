# UniCheck - Thư Mục Tài Liệu Kỹ Thuật (Documentation Index)

> Tài liệu hướng dẫn định tuyến và tra cứu toàn bộ hồ sơ thiết kế, đặc tả kỹ thuật, hợp đồng API và báo cáo kiểm thử của dự án **UniCheck**.

---

## 🗂️ Bản Đồ Cấu Trúc Tài Liệu

```text
docs/
├── README.md                      # [File hiện tại] Mục lục tra cứu tài liệu
│
├── SDD_Updated/                   # [CỐT LÕI] Đặc tả thiết kế hệ thống phần mềm (SDD v2.1)
│   ├── UniCheck_SDD_Final.md      # Tài liệu SDD hoàn chỉnh (đối soát 100% mã nguồn thực tế)
│   ├── UniCheck_SDD_Final.docx    # Bản Word xuất bản phục vụ bảo vệ đồ án / nghiệm thu
│   ├── UniCheck_SDD_Audit_Report.md # Báo cáo kiểm định đối chiếu SDD với mã nguồn
│   ├── UniCheck_SDD_ChangeLog.md  # Nhật ký phiên bản và thay đổi kiến trúc
│   └── diagrams/                  # Lược đồ kiến trúc (PlantUML & Mermaid)
│
├── updated-specification/         # [CỐT LÕI] Đặc tả yêu cầu & Ma trận truy vết
│   ├── UniCheck_Requirement_Traceability.md # Ma trận truy vết yêu cầu (RTM 31 tính năng)
│   ├── UniCheck_Source_Code_Audit.md        # Báo cáo rà soát mã nguồn toàn diện
│   └── diagrams/                            # Lược đồ tuần tự & quan hệ thành phần
│
├── api/                           # [HỢP ĐỒNG GIAO TIẾP] Đặc tả API Contracts & OpenAPI
│   ├── openapi.yaml               # Đặc tả OpenAPI 3.0 chuẩn cho toàn bộ Backend
│   ├── auth_api_contract.md       # Hợp đồng xác thực (JWT, Refresh Token, OTP)
│   ├── academic_catalog_api_contract.md # Hợp đồng danh mục học vụ & niên khóa
│   └── class_section_enrollment_api_contract.md # Hợp đồng lớp học & ghi danh
│
├── ai/                            # [AI & SINH TRẮC HỌC] Đặc tả mô hình Face & Liveness
│   ├── FACE_MODEL_SPECIFICATION.md      # Đặc tả vector khuôn mặt 128D & kiến trúc nhận diện
│   ├── FACE_THRESHOLD_EVALUATION.md     # Đánh giá thực nghiệm ngưỡng nhận diện
│   ├── LIVENESS_MODEL_SPECIFICATION.md  # Mô hình phát hiện giả mạo thực thể sống
│   └── LIVENESS_INTEGRATION_PLAN.md     # Kế hoạch tích hợp luồng liveness
│
├── adr/                           # [QUYẾT ĐỊNH KIẾN TRÚC] Architecture Decision Records
│   ├── ADR-001-schema-and-migration-policy.md # Quy chuẩn Flyway Migration & CSDL 50 bảng
│   └── schema_map_erd.md                      # Sơ đồ quan hệ thực thể (ERD)
│
├── audit/                         # [KIỂM TOÁN DỰ ÁN] Báo cáo chất lượng & mức độ hoàn thiện
│   ├── UNICHECK_FULL_PROJECT_AUDIT.md # Báo cáo kiểm toán toàn diện dự án
│   ├── FEATURE_MATRIX.md              # Bảng ma trận 31 tính năng nghiệp vụ
│   ├── CURRENT_PROJECT_STATUS.md      # Báo cáo hiện trạng các tầng hệ thống
│   └── API_GAP_AND_DEPENDENCY_MAP.md  # Bản đồ phụ thuộc API và khoảng cách logic
│
├── testing/                       # [KIỂM THỬ & QA] Hướng dẫn & Dữ liệu kiểm thử
│   ├── MINIMAL_ATTENDANCE_TEST_DATA.md # Bộ dữ liệu mẫu tối thiểu phục vụ kiểm thử
│   └── reports/                   # Lưu trữ toàn bộ 19 báo cáo nghiệm thu task (TASK_02A -> TASK_08)
│
├── database/                      # [CƠ SỞ DỮ LIỆU]
│   └── fpt_seed_history/          # Hồ sơ, kế hoạch và nhật ký import dữ liệu mẫu FPT
│
├── implementation/                # [QUẢN TRỊ DỰ ÁN]
│   ├── DEFINITION_OF_DONE.md      # Tiêu chí hoàn thành (DoD) cho tính năng
│   ├── EXECUTION_ROADMAP.md       # Lộ trình triển khai các giai đoạn
│   └── FEATURE_TASK_QUEUE.md      # Hàng đợi công việc chi tiết
│
└── archive/                       # [LƯU TRỮ LỊCH SỬ]
    ├── baseline-report-4/         # Báo cáo Report 4 sơ khởi ban đầu (Word + Assets hình ảnh)
    ├── evidence/                  # Bằng chứng kiểm thử tự động giai đoạn nền tảng
    └── inventory/                 # Bảng kiểm kê mã nguồn ban đầu
```

---

## 📌 Hướng Dẫn Nhanh Cho Thành Viên & Giảng Viên / Hội Đồng

1. **Xem tài liệu kiến trúc tổng thể (SDD)**: Truy cập [`SDD_Updated/UniCheck_SDD_Final.md`](SDD_Updated/UniCheck_SDD_Final.md).
2. **Xem ma trận truy vết yêu cầu (RTM)**: Truy cập [`updated-specification/UniCheck_Requirement_Traceability.md`](updated-specification/UniCheck_Requirement_Traceability.md).
3. **Tra cứu quy chuẩn API giữa Frontend/Mobile và Backend**: Truy cập thư mục [`api/`](api/).
4. **Tìm hiểu thông số mô hình AI & chống giả mạo**: Truy cập thư mục [`ai/`](ai/).
5. **Xem bằng chứng nghiệm thu các task tính năng**: Truy cập [`testing/reports/`](testing/reports/).
