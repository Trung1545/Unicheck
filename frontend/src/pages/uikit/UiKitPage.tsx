import React, { useState } from 'react';
import {
  Users,
  GraduationCap,
  Calendar,
  CheckCircle2,
  Trash2,
  Plus,
  Shield,
  Filter,
} from 'lucide-react';
import {
  Button,
  Input,
  Select,
  Badge,
  StatCard,
  DataTable,
  Modal,
  Pagination,
  LoadingSpinner,
  Skeleton,
  EmptyState,
  ErrorState,
  Alert,
  SearchInput,
  FilterBar,
  ColumnDef,
} from '../../common-ui';
import { useAuthStore } from '../../store/auth-store';
import { Role } from '../../types/api';

interface SampleStudent {
  id: number;
  code: string;
  fullName: string;
  email: string;
  course: string;
  attendanceStatus: 'present' | 'late' | 'absent' | 'excused';
  confidence: string;
  status: 'active' | 'inactive';
}

const sampleData: SampleStudent[] = [
  {
    id: 1,
    code: 'SV2026001',
    fullName: 'Nguyễn Văn An',
    email: 'an.nv@unicheck.edu.vn',
    course: 'K18',
    attendanceStatus: 'present',
    confidence: '99.4%',
    status: 'active',
  },
  {
    id: 2,
    code: 'SV2026002',
    fullName: 'Trần Thị Bình',
    email: 'binh.tt@unicheck.edu.vn',
    course: 'K18',
    attendanceStatus: 'late',
    confidence: '98.1%',
    status: 'active',
  },
  {
    id: 3,
    code: 'SV2026003',
    fullName: 'Lê Hoàng Cường',
    email: 'cuong.lh@unicheck.edu.vn',
    course: 'K19',
    attendanceStatus: 'absent',
    confidence: '—',
    status: 'active',
  },
  {
    id: 4,
    code: 'SV2026004',
    fullName: 'Phạm Minh Đức',
    email: 'duc.pm@unicheck.edu.vn',
    course: 'K17',
    attendanceStatus: 'excused',
    confidence: '—',
    status: 'inactive',
  },
];

export const UiKitPage: React.FC = () => {
  const [searchValue, setSearchValue] = useState('');
  const [selectedRole, setSelectedRole] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDangerModalOpen, setIsDangerModalOpen] = useState(false);
  const [isTableLoading, setIsTableLoading] = useState(false);
  const [isTableEmpty, setIsTableEmpty] = useState(false);
  const [showAlert, setShowAlert] = useState(true);

  const { user, setUser } = useAuthStore();

  const handleRoleSwitch = (newRole: Role) => {
    setUser({
      id: user?.id || 1,
      code: user?.code || 'AD001',
      username: user?.username || 'admin',
      fullName: user?.fullName || 'Người dùng thử nghiệm',
      email: user?.email || 'admin@unicheck.edu.vn',
      role: newRole,
      isPasswordChanged: true,
      permissions: ['ALL'],
    });
  };

  const columns: ColumnDef<SampleStudent>[] = [
    {
      key: 'code',
      header: 'MSSV',
      render: (item) => <span className="font-semibold text-slate-900 data-tabular">{item.code}</span>,
    },
    {
      key: 'fullName',
      header: 'Họ và tên',
      render: (item) => (
        <div>
          <div className="font-medium text-slate-900">{item.fullName}</div>
          <div className="text-xs text-slate-500">{item.email}</div>
        </div>
      ),
    },
    {
      key: 'course',
      header: 'Khóa',
      align: 'center',
      render: (item) => <span className="text-xs text-slate-600 font-medium">{item.course}</span>,
    },
    {
      key: 'attendanceStatus',
      header: 'Trạng thái điểm danh',
      align: 'center',
      render: (item) => {
        const labelMap = {
          present: 'Có mặt',
          late: 'Đi trễ',
          absent: 'Vắng mặt',
          excused: 'Có phép',
        };
        return <Badge variant={item.attendanceStatus}>{labelMap[item.attendanceStatus]}</Badge>;
      },
    },
    {
      key: 'confidence',
      header: 'Độ khớp Face-ID',
      align: 'right',
      render: (item) => <span className="font-semibold text-slate-800 data-tabular">{item.confidence}</span>,
    },
    {
      key: 'status',
      header: 'Tài khoản',
      align: 'center',
      render: (item) => (
        <Badge variant={item.status === 'active' ? 'active' : 'inactive'}>
          {item.status === 'active' ? 'Hoạt động' : 'Chưa kích hoạt'}
        </Badge>
      ),
    },
    {
      key: 'actions',
      header: 'Thao tác',
      align: 'right',
      render: () => (
        <div className="flex items-center justify-end gap-1">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setIsDangerModalOpen(true)}
            className="text-red-600 hover:bg-red-50"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </Button>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-8 text-left pb-12">
      {/* Title & Role Switcher */}
      <div className="bg-white p-6 rounded-xl border border-slate-200/90 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-bold text-slate-900 tracking-tight flex items-center gap-2">
            UniCheck Design System
            <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-primary-50 text-primary-700 border border-primary-200">
              Academic Precision v1.0
            </span>
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Bộ linh kiện nguyên tử dùng chung và App Layout Shell cho Cổng Quản trị UniCheck.
          </p>
        </div>

        {/* Live Role Switcher for Testing Navigation */}
        <div className="flex items-center gap-2 bg-slate-50 p-1.5 rounded-lg border border-slate-200">
          <span className="text-xs text-slate-500 font-semibold px-2">Xem vai trò:</span>
          {(['ADMIN', 'LECTURER', 'STUDENT'] as Role[]).map((r) => (
            <button
              key={r}
              type="button"
              onClick={() => handleRoleSwitch(r)}
              className={`px-2.5 py-1 text-xs font-bold rounded-md transition ${
                (user?.role || 'ADMIN') === r
                  ? 'bg-primary-700 text-white shadow-sm'
                  : 'text-slate-600 hover:bg-slate-200'
              }`}
            >
              {r}
            </button>
          ))}
        </div>
      </div>

      {/* Alert Component Showcase */}
      {showAlert && (
        <Alert
          variant="info"
          title="Môi trường thử nghiệm Design Tokens"
          message="Trang này dùng để kiểm tra tính nhất quán về kích thước 8pt, font Inter diacritics, và phản hồi tương tác của toàn bộ component dùng chung."
          onClose={() => setShowAlert(false)}
        />
      )}

      {/* 1. StatCard Section */}
      <section className="space-y-3">
        <h2 className="text-base font-bold text-slate-800">1. Thẻ chỉ số tổng quan (StatCard)</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            title="Tổng sinh viên"
            value="14,850"
            icon={<Users className="w-5 h-5 text-primary-700" />}
            trend={{ value: '+3.2%', isPositive: true, label: 'so với kỳ trước' }}
            progressPercent={95.1}
            subMetrics={[
              { label: 'Đang theo học', value: '14,120' },
              { label: 'Bảo lưu', value: '730' },
            ]}
          />
          <StatCard
            title="Tổng giảng viên"
            value="642"
            icon={<GraduationCap className="w-5 h-5 text-accent-600" />}
            iconBgColor="bg-accent-50"
            trend={{ value: '215', isPositive: true, label: 'hoạt động hôm nay' }}
            progressPercent={74.7}
            subMetrics={[
              { label: 'Cơ hữu', value: '480' },
              { label: 'Thỉnh giảng', value: '162' },
            ]}
          />
          <StatCard
            title="Lớp học trong ngày"
            value="186"
            icon={<Calendar className="w-5 h-5 text-blue-700" />}
            iconBgColor="bg-blue-50"
            trend={{ value: '98.4%', isPositive: true, label: 'đúng giờ' }}
            progressPercent={50.5}
            subMetrics={[
              { label: 'Ca sáng', value: '94 lớp' },
              { label: 'Ca chiều', value: '92 lớp' },
            ]}
          />
          <StatCard
            title="Tỷ lệ điểm danh"
            value="94.8%"
            icon={<CheckCircle2 className="w-5 h-5 text-emerald-700" />}
            iconBgColor="bg-emerald-50"
            trend={{ value: '+1.5%', isPositive: true, label: 'so với tuần trước' }}
            progressPercent={94.8}
            subMetrics={[
              { label: 'Có mặt', value: '4,820' },
              { label: 'Dự kiến', value: '5,084' },
            ]}
          />
        </div>
      </section>

      {/* 2. Buttons Showcase */}
      <section className="bg-white p-6 rounded-xl border border-slate-200/90 shadow-sm space-y-4">
        <h2 className="text-base font-bold text-slate-800">2. Nút bấm (Button Variants & Sizes)</h2>
        <div className="flex flex-wrap items-center gap-3">
          <Button variant="primary" leftIcon={<Plus className="w-4 h-4" />}>
            Primary CTA
          </Button>
          <Button variant="secondary">Secondary Teal</Button>
          <Button variant="outline">Outline</Button>
          <Button variant="ghost">Ghost Button</Button>
          <Button variant="danger" leftIcon={<Trash2 className="w-4 h-4" />}>
            Danger
          </Button>
          <Button variant="primary" isLoading>
            Loading...
          </Button>
          <Button variant="primary" disabled>
            Disabled
          </Button>
        </div>
        <div className="flex flex-wrap items-center gap-3 pt-2">
          <Button variant="primary" size="sm">
            Small (h-8)
          </Button>
          <Button variant="primary" size="md">
            Medium (h-10)
          </Button>
          <Button variant="primary" size="lg">
            Large (h-12)
          </Button>
        </div>
      </section>

      {/* 3. Inputs & Selects */}
      <section className="bg-white p-6 rounded-xl border border-slate-200/90 shadow-sm space-y-4">
        <h2 className="text-base font-bold text-slate-800">3. Biểu mẫu nhập liệu (Input & Select)</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <Input
            label="Họ và tên"
            placeholder="Nhập họ và tên..."
            helperText="Định dạng theo CCCD/Hộ chiếu"
          />
          <Input
            label="Mật khẩu"
            placeholder="Nhập mật khẩu..."
            isPassword
            helperText="Nhấn biểu tượng mắt để bật/tắt hiển thị"
          />
          <Input
            label="Trường có lỗi"
            defaultValue="invalid@unicheck"
            error="Địa chỉ email không đúng định dạng hợp lệ"
          />
          <Select
            label="Vai trò tài khoản"
            options={[
              { label: 'Sinh viên (STUDENT)', value: 'STUDENT' },
              { label: 'Giảng viên (LECTURER)', value: 'LECTURER' },
              { label: 'Quản trị viên (ADMIN)', value: 'ADMIN' },
            ]}
          />
          <Select
            label="Học kỳ áp dụng"
            placeholder="-- Chọn học kỳ --"
            options={[
              { label: 'Học kỳ I (2024 - 2025)', value: 'HK1_2024' },
              { label: 'Học kỳ II (2024 - 2025)', value: 'HK2_2024' },
            ]}
          />
          <Select
            label="Trạng thái chọn lỗi"
            options={[{ label: 'Mục chọn', value: '1' }]}
            error="Vui lòng chọn ít nhất một mục"
          />
        </div>
      </section>

      {/* 4. Badges Showcase */}
      <section className="bg-white p-6 rounded-xl border border-slate-200/90 shadow-sm space-y-4">
        <h2 className="text-base font-bold text-slate-800">4. Huy hiệu trạng thái (Badge)</h2>
        <div className="space-y-3">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs font-semibold text-slate-500 w-32">Điểm danh:</span>
            <Badge variant="present">Có mặt (Present)</Badge>
            <Badge variant="late">Đi trễ (Late)</Badge>
            <Badge variant="absent">Vắng mặt (Absent)</Badge>
            <Badge variant="excused">Có phép (Excused)</Badge>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs font-semibold text-slate-500 w-32">Tài khoản:</span>
            <Badge variant="active">Đang hoạt động</Badge>
            <Badge variant="inactive">Chưa kích hoạt</Badge>
            <Badge variant="blocked">Bị tạm khóa</Badge>
            <Badge variant="pending">Chờ phê duyệt</Badge>
          </div>
        </div>
      </section>

      {/* 5. FilterBar, SearchInput & DataTable */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-base font-bold text-slate-800">5. Bảng dữ liệu (DataTable & FilterBar)</h2>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsTableLoading(!isTableLoading)}
            >
              {isTableLoading ? 'Tắt loading' : 'Bật loading skeleton'}
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsTableEmpty(!isTableEmpty)}
            >
              {isTableEmpty ? 'Hiện dữ liệu' : 'Hiện empty state'}
            </Button>
            <Button
              variant="primary"
              size="sm"
              onClick={() => setIsModalOpen(true)}
              leftIcon={<Plus className="w-4 h-4" />}
            >
              Mở Modal Thêm mới
            </Button>
          </div>
        </div>

        {/* FilterBar */}
        <FilterBar
          onReset={() => {
            setSearchValue('');
            setSelectedRole('');
          }}
          hasActiveFilters={!!searchValue || !!selectedRole}
        >
          <SearchInput
            value={searchValue}
            onChange={setSearchValue}
            placeholder="Tìm kiếm MSSV, tên sinh viên, email..."
          />
          <div className="w-48">
            <Select
              value={selectedRole}
              onChange={(e) => setSelectedRole(e.target.value)}
              placeholder="Lọc theo khóa"
              options={[
                { label: 'Tất cả các khóa', value: '' },
                { label: 'Khóa K17', value: 'K17' },
                { label: 'Khóa K18', value: 'K18' },
                { label: 'Khóa K19', value: 'K19' },
              ]}
            />
          </div>
        </FilterBar>

        {/* DataTable */}
        <DataTable
          columns={columns}
          data={isTableEmpty ? [] : sampleData}
          isLoading={isTableLoading}
          pagination={{
            currentPage,
            totalPages: 5,
            totalElements: 48,
            pageSize: 10,
            onPageChange: setCurrentPage,
          }}
        />
      </section>

      {/* 6. LoadingSpinner & ErrorState */}
      <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-white p-6 rounded-xl border border-slate-200/90 shadow-sm flex flex-col items-center justify-center min-h-[160px]">
          <LoadingSpinner size="lg" label="Đang kiểm tra dữ liệu sinh trắc học..." />
        </div>
        <ErrorState onRetry={() => alert('Thử tải lại dữ liệu!')} />
      </section>

      {/* Modals */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Thêm mới tài khoản sinh viên"
        description="Điền thông tin định danh sinh viên để khởi tạo hồ sơ học vụ trong hệ thống."
        confirmText="Lưu tài khoản"
        onConfirm={() => {
          alert('Đã lưu tài khoản thành công!');
          setIsModalOpen(false);
        }}
      >
        <div className="space-y-3 pt-2">
          <Input label="Mã sinh viên (MSSV)" placeholder="SV2026..." required />
          <Input label="Họ và tên đầy đủ" placeholder="Nhập họ và tên..." required />
          <Input label="Email trường cấp" placeholder="user@unicheck.edu.vn" required />
          <Select
            label="Chuyên ngành đào tạo"
            options={[
              { label: 'Kỹ thuật Phần mềm (SE)', value: 'SE' },
              { label: 'Trí tuệ Nhân tạo (AI)', value: 'AI' },
              { label: 'An toàn Thông tin (IA)', value: 'IA' },
            ]}
          />
        </div>
      </Modal>

      <Modal
        isOpen={isDangerModalOpen}
        onClose={() => setIsDangerModalOpen(false)}
        title="Xác nhận xóa tài khoản"
        description="Bạn có chắc chắn muốn xóa tài khoản này khỏi hệ thống? Thao tác này sẽ thu hồi toàn bộ token đăng nhập và không thể hoàn tác."
        isDanger
        confirmText="Xác nhận xóa"
        onConfirm={() => {
          alert('Đã xóa thành công!');
          setIsDangerModalOpen(false);
        }}
      />
    </div>
  );
};

export default UiKitPage;
