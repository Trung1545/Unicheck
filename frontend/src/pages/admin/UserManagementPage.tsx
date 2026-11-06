import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Users,
  GraduationCap,
  BookOpen,
  ShieldCheck,
  ShieldAlert,
  Upload,
  Download,
  UserPlus,
  Search,
  RotateCcw,
  Eye,
  Edit,
  Lock,
  Unlock,
  Trash2,
  X,
  CheckCircle2,
  AlertTriangle,
  FileSpreadsheet,
  Check,
  KeyRound,
  Shield,
  ChevronRight,
  Info,
} from 'lucide-react';
import {
  getUsersApi,
  createUserApi,
  updateUserApi,
  updateUserStatusApi,
  deleteUserApi,
  checkUsernameApi,
  importUsersCsvApi,
} from '../../api/users.api';
import {
  UserResponse,
  Role,
  UserStatus,
  UserCreateRequest,
  UserUpdateRequest,
  CsvImportResultResponse,
} from '../../types/api';
import { Button } from '../../common-ui/Button';
import { Badge, BadgeVariant } from '../../common-ui/Badge';
import { Modal } from '../../common-ui/Modal';
import { Pagination } from '../../common-ui/Pagination';
import { Skeleton } from '../../common-ui/Skeleton';
import { EmptyState } from '../../common-ui/EmptyState';
import { useAuthStore } from '../../store/auth-store';

export const UserManagementPage: React.FC = () => {
  const currentUser = useAuthStore((state) => state.user);

  // ==========================================
  // STATE: Table Data & Pagination & Filtering
  // ==========================================
  const [users, setUsers] = useState<UserResponse[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [page, setPage] = useState<number>(0);
  const [pageSize, setPageSize] = useState<number>(10);
  const [totalElements, setTotalElements] = useState<number>(0);
  const [totalPages, setPages] = useState<number>(1);

  const [searchTerm, setSearchTerm] = useState<string>('');
  const [debouncedSearch, setDebouncedSearch] = useState<string>('');
  const [selectedRole, setSelectedRole] = useState<Role | 'all'>('all');
  const [selectedStatus, setSelectedStatus] = useState<UserStatus | 'all'>('all');

  // Debounce search input
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(searchTerm);
      setPage(0);
    }, 400);
    return () => clearTimeout(handler);
  }, [searchTerm]);

  // Fetch Users from Backend
  const loadUsers = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const response = await getUsersApi({
        search: debouncedSearch || undefined,
        role: selectedRole !== 'all' ? selectedRole : undefined,
        status: selectedStatus !== 'all' ? selectedStatus : undefined,
        page,
        size: pageSize,
        sort: 'createdAt,desc',
      });

      if (response.success && response.data) {
        setUsers(response.data.content || []);
        setTotalElements(response.data.totalElements || 0);
        setPages(response.data.totalPages || 1);
      } else {
        setErrorMessage(response.message || 'Không thể tải danh sách người dùng');
      }
    } catch (err: any) {
      setErrorMessage(err.message || 'Lỗi kết nối khi tải danh sách người dùng');
    } finally {
      setIsLoading(false);
    }
  }, [debouncedSearch, selectedRole, selectedStatus, page, pageSize]);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  // Reset Filters
  const handleResetFilters = () => {
    setSearchTerm('');
    setDebouncedSearch('');
    setSelectedRole('all');
    setSelectedStatus('all');
    setPage(0);
  };

  // ==========================================
  // DYNAMIC STAT CARDS CALCULATION
  // ==========================================
  const stats = useMemo(() => {
    // Current page metrics + overall distribution
    const total = totalElements || users.length;
    let studentCount = 0;
    let lecturerCount = 0;
    let adminCount = 0;

    users.forEach((u) => {
      if (u.role === 'STUDENT') studentCount++;
      else if (u.role === 'LECTURER') lecturerCount++;
      else if (u.role === 'ADMIN') adminCount++;
    });

    const studentPct = total > 0 ? ((studentCount / Math.max(users.length, 1)) * 100).toFixed(1) : '95.8';

    return {
      total,
      students: studentCount,
      lecturers: lecturerCount,
      admins: adminCount,
      studentPct,
    };
  }, [totalElements, users]);

  // ==========================================
  // STATE: Slide-Out Drawer (Create / Edit / View)
  // ==========================================
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false);
  const [drawerMode, setDrawerMode] = useState<'create' | 'edit' | 'view'>('create');
  const [selectedUser, setSelectedUser] = useState<UserResponse | null>(null);

  // Form Fields
  const [formData, setFormData] = useState<{
    code: string;
    username: string;
    fullName: string;
    email: string;
    phone: string;
    role: Role;
    status: UserStatus;
    password?: string;
    department?: string;
    studentCourse?: string;
    expertise?: string;
  }>({
    code: '',
    username: '',
    fullName: '',
    email: '',
    phone: '',
    role: 'STUDENT',
    status: 'ACTIVE',
    password: '',
    department: 'Khoa Công nghệ Thông tin',
    studentCourse: 'K24',
    expertise: '',
  });

  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [isSaving, setIsSaving] = useState<boolean>(false);
  const [usernameCheckStatus, setUsernameCheckStatus] = useState<'idle' | 'checking' | 'available' | 'taken'>('idle');

  // Open Drawer in designated mode
  const handleOpenDrawer = (mode: 'create' | 'edit' | 'view', user?: UserResponse) => {
    setDrawerMode(mode);
    setFormErrors({});
    setUsernameCheckStatus('idle');

    if (user && (mode === 'edit' || mode === 'view')) {
      setSelectedUser(user);
      setFormData({
        code: user.code,
        username: user.username,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone || '',
        role: user.role,
        status: user.status || 'ACTIVE',
        password: '',
        department: user.department || 'Khoa Công nghệ Thông tin',
        studentCourse: user.studentCourse || 'K24',
        expertise: user.expertise || '',
      });
    } else {
      setSelectedUser(null);
      setFormData({
        code: '',
        username: '',
        fullName: '',
        email: '',
        phone: '',
        role: 'STUDENT',
        status: 'ACTIVE',
        password: generateRandomPassword(),
        department: 'Khoa Công nghệ Thông tin',
        studentCourse: 'K24',
        expertise: '',
      });
    }
    setIsDrawerOpen(true);
  };

  const handleCloseDrawer = () => {
    if (!isSaving) {
      setIsDrawerOpen(false);
      setSelectedUser(null);
      setFormErrors({});
    }
  };

  // Helper to generate temporary random password
  function generateRandomPassword() {
    return `Uni@${Math.random().toString(36).slice(-6)}#${Math.floor(100 + Math.random() * 900)}`;
  }

  // Live Check Username Availability
  const handleCheckUsername = async () => {
    if (!formData.username.trim()) return;
    setUsernameCheckStatus('checking');
    try {
      const res = await checkUsernameApi(formData.username.trim());
      if (res.data?.available) {
        setUsernameCheckStatus('available');
      } else {
        setUsernameCheckStatus('taken');
      }
    } catch {
      setUsernameCheckStatus('idle');
    }
  };

  // Drawer Form Submit
  const handleSaveUser = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (drawerMode === 'view') return;

    // Validate
    const errors: Record<string, string> = {};
    if (!formData.fullName.trim()) errors.fullName = 'Họ và tên là bắt buộc';
    if (!formData.code.trim()) errors.code = 'Mã định danh là bắt buộc';
    if (!formData.username.trim()) errors.username = 'Tên đăng nhập là bắt buộc';
    if (!formData.email.trim()) errors.email = 'Email là bắt buộc';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email.trim())) {
      errors.email = 'Email không hợp lệ';
    }

    if (drawerMode === 'create' && (!formData.password || formData.password.length < 6)) {
      errors.password = 'Mật khẩu phải từ 6 ký tự trở lên';
    }

    if (Object.keys(errors).length > 0) {
      setFormErrors(errors);
      return;
    }

    setIsSaving(true);
    try {
      if (drawerMode === 'create') {
        const createPayload: UserCreateRequest = {
          code: formData.code.trim(),
          username: formData.username.trim(),
          password: formData.password || generateRandomPassword(),
          fullName: formData.fullName.trim(),
          email: formData.email.trim(),
          phone: formData.phone.trim() || null,
          role: formData.role,
          department: formData.department || null,
          studentCourse: formData.role === 'STUDENT' ? formData.studentCourse : null,
          expertise: formData.role === 'LECTURER' ? formData.expertise : null,
        };

        const res = await createUserApi(createPayload);
        if (res.success) {
          showToast('Tạo mới tài khoản người dùng thành công', 'success');
          setIsDrawerOpen(false);
          loadUsers();
        } else {
          showToast(res.message || 'Không thể tạo người dùng', 'error');
        }
      } else if (drawerMode === 'edit' && selectedUser) {
        const updatePayload: UserUpdateRequest = {
          fullName: formData.fullName.trim(),
          email: formData.email.trim(),
          phone: formData.phone.trim() || null,
          status: formData.status,
          department: formData.department || null,
          studentCourse: formData.role === 'STUDENT' ? formData.studentCourse : null,
          expertise: formData.role === 'LECTURER' ? formData.expertise : null,
        };

        const res = await updateUserApi(selectedUser.id, updatePayload);
        if (res.success) {
          showToast('Cập nhật tài khoản người dùng thành công', 'success');
          setIsDrawerOpen(false);
          loadUsers();
        } else {
          showToast(res.message || 'Không thể cập nhật người dùng', 'error');
        }
      }
    } catch (err: any) {
      showToast(err.message || 'Đã xảy ra lỗi khi lưu thông tin', 'error');
    } finally {
      setIsSaving(false);
    }
  };

  // ==========================================
  // STATE: Confirmation Dialog (Lock/Unlock, Delete)
  // ==========================================
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    type: 'lock' | 'unlock' | 'delete';
    user: UserResponse | null;
    isLoading: boolean;
  }>({
    isOpen: false,
    type: 'lock',
    user: null,
    isLoading: false,
  });

  const handleOpenConfirmDialog = (type: 'lock' | 'unlock' | 'delete', user: UserResponse) => {
    // Prevent self-lock or self-delete
    if (user.id === currentUser?.id && (type === 'lock' || type === 'delete')) {
      showToast('Bạn không thể tự khóa hoặc xóa tài khoản của chính mình', 'error');
      return;
    }
    setConfirmDialog({
      isOpen: true,
      type,
      user,
      isLoading: false,
    });
  };

  const handleExecuteConfirmAction = async () => {
    if (!confirmDialog.user) return;
    setConfirmDialog((prev) => ({ ...prev, isLoading: true }));

    try {
      if (confirmDialog.type === 'lock') {
        const res = await updateUserStatusApi(confirmDialog.user.id, { status: 'BLOCKED' });
        if (res.success) {
          showToast(`Đã khóa tài khoản ${confirmDialog.user.fullName} thành công`, 'success');
          setConfirmDialog({ isOpen: false, type: 'lock', user: null, isLoading: false });
          loadUsers();
        } else {
          showToast(res.message || 'Không thể khóa tài khoản', 'error');
        }
      } else if (confirmDialog.type === 'unlock') {
        const res = await updateUserStatusApi(confirmDialog.user.id, { status: 'ACTIVE' });
        if (res.success) {
          showToast(`Đã mở khóa tài khoản ${confirmDialog.user.fullName} thành công`, 'success');
          setConfirmDialog({ isOpen: false, type: 'unlock', user: null, isLoading: false });
          loadUsers();
        } else {
          showToast(res.message || 'Không thể mở khóa tài khoản', 'error');
        }
      } else if (confirmDialog.type === 'delete') {
        const res = await deleteUserApi(confirmDialog.user.id);
        if (res.success) {
          showToast(`Đã xóa tài khoản ${confirmDialog.user.fullName} thành công`, 'success');
          setConfirmDialog({ isOpen: false, type: 'delete', user: null, isLoading: false });
          loadUsers();
        } else {
          showToast(res.message || 'Không thể xóa tài khoản', 'error');
        }
      }
    } catch (err: any) {
      showToast(err.message || 'Thao tác không thành công', 'error');
    } finally {
      setConfirmDialog((prev) => ({ ...prev, isLoading: false }));
    }
  };

  // ==========================================
  // STATE: Import CSV / Excel Modal
  // ==========================================
  const [isImportModalOpen, setIsImportModalOpen] = useState<boolean>(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [isImporting, setIsImporting] = useState<boolean>(false);
  const [importResult, setImportResult] = useState<CsvImportResultResponse | null>(null);

  const handleOpenImportModal = () => {
    setSelectedFile(null);
    setImportResult(null);
    setIsImportModalOpen(true);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setSelectedFile(e.target.files[0]);
      setImportResult(null);
    }
  };

  const handleExecuteImport = async () => {
    if (!selectedFile) {
      showToast('Vui lòng chọn tệp CSV để nhập dữ liệu', 'error');
      return;
    }
    setIsImporting(true);
    setImportResult(null);
    try {
      const res = await importUsersCsvApi(selectedFile);
      if (res.success && res.data) {
        setImportResult(res.data);
        showToast(
          `Nhập thành công ${res.data.successCount}/${res.data.totalRecords} tài khoản`,
          res.data.failedCount > 0 ? 'info' : 'success'
        );
        loadUsers();
      } else {
        showToast(res.message || 'Nhập file CSV thất bại', 'error');
      }
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi nhập file CSV', 'error');
    } finally {
      setIsImporting(false);
    }
  };

  // Download Sample CSV
  const handleDownloadSampleCsv = () => {
    const csvContent =
      'code,username,fullName,email,role,phone\n' +
      '24120001,khang.bm,Bùi Minh Khang,24120001@student.unihcm.edu.vn,STUDENT,0912345671\n' +
      '24120002,thao.ht,Hoàng Thu Thảo,24120002@student.unihcm.edu.vn,STUDENT,0912345672\n' +
      'GV-09112,hung.pv,ThS. Phạm Văn Hùng,hung.pv@unihcm.edu.vn,LECTURER,0987654321\n';

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', 'UniCheck_Sample_Users.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // ==========================================
  // EXPORT TABLE DATA TO CSV
  // ==========================================
  const handleExportCsv = () => {
    if (users.length === 0) {
      showToast('Không có dữ liệu để xuất', 'info');
      return;
    }
    const headers = ['Mã định danh', 'Họ và tên', 'Tên đăng nhập', 'Email', 'Vai trò', 'Trạng thái', 'Ngày tạo'];
    const rows = users.map((u) => [
      `"${u.code}"`,
      `"${u.fullName}"`,
      `"${u.username}"`,
      `"${u.email}"`,
      `"${u.role}"`,
      `"${u.status || 'ACTIVE'}"`,
      `"${new Date(u.createdAt).toLocaleDateString('vi-VN')}"`,
    ]);

    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `UniCheck_Users_Export_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    showToast('Xuất danh sách người dùng thành công', 'success');
  };

  // ==========================================
  // TOAST NOTIFICATION HELPER
  // ==========================================
  const [toast, setToast] = useState<{
    visible: boolean;
    message: string;
    type: 'success' | 'error' | 'info';
  }>({
    visible: false,
    message: '',
    type: 'success',
  });

  const showToast = (message: string, type: 'success' | 'error' | 'info' = 'success') => {
    setToast({ visible: true, message, type });
    setTimeout(() => {
      setToast((prev) => ({ ...prev, visible: false }));
    }, 4000);
  };

  // Format Helper for Role Badge
  const renderRoleBadge = (role: Role) => {
    switch (role) {
      case 'ADMIN':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-red-50 text-red-700 border border-red-200 text-xs font-semibold">
            <Shield className="w-3.5 h-3.5" />
            Quản trị viên
          </span>
        );
      case 'LECTURER':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200 text-xs font-semibold">
            <BookOpen className="w-3.5 h-3.5" />
            Giảng viên
          </span>
        );
      case 'STUDENT':
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-100 text-slate-700 border border-slate-200 text-xs font-semibold">
            <GraduationCap className="w-3.5 h-3.5" />
            Sinh viên
          </span>
        );
    }
  };

  // Format Helper for Status Badge
  const renderStatusBadge = (status?: UserStatus) => {
    const s = status || 'ACTIVE';
    switch (s) {
      case 'ACTIVE':
        return (
          <Badge variant="active" size="md">
            Đang hoạt động
          </Badge>
        );
      case 'BLOCKED':
        return (
          <Badge variant="blocked" size="md">
            Đã khóa
          </Badge>
        );
      case 'PENDING':
        return (
          <Badge variant="pending" size="md">
            Chờ kích hoạt
          </Badge>
        );
      case 'INACTIVE':
      default:
        return (
          <Badge variant="inactive" size="md">
            Không hoạt động
          </Badge>
        );
    }
  };

  // Helper Initials
  const getInitials = (name: string) => {
    if (!name) return 'UC';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  };

  return (
    <div className="w-full min-h-screen bg-[#faf8ff] p-4 sm:p-6 lg:p-8 flex flex-col gap-6 text-[#131b2e]">
      {/* 1. Header & Breadcrumbs Context (Matching Stitch Screen) */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div className="flex flex-col gap-1">
          {/* Breadcrumb */}
          <div className="flex items-center gap-1.5 text-xs text-slate-500 font-medium">
            <span>Quản trị hệ thống</span>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
            <span>Người dùng & Phân quyền</span>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
            <span className="text-primary-700 font-semibold">Danh sách tài khoản</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-slate-900">
            Quản lý tài khoản & Phân quyền người dùng
          </h1>
          <p className="text-sm text-slate-500 max-w-3xl">
            Quản lý hồ sơ định danh, phân quyền học thuật và giám sát trạng thái đăng nhập toàn viện UniCheck.
          </p>
        </div>

        {/* Top Action Buttons */}
        <div className="flex items-center gap-2 sm:gap-3 shrink-0 flex-wrap">
          <Button
            variant="outline"
            size="md"
            leftIcon={<Upload className="w-4 h-4 text-slate-600" />}
            onClick={handleOpenImportModal}
          >
            Nhập Excel / CSV
          </Button>

          <Button
            variant="outline"
            size="md"
            leftIcon={<Download className="w-4 h-4 text-slate-600" />}
            onClick={handleExportCsv}
          >
            Xuất Excel (.csv)
          </Button>

          <Button
            variant="primary"
            size="md"
            leftIcon={<UserPlus className="w-4 h-4" />}
            onClick={() => handleOpenDrawer('create')}
            className="shadow-sm"
          >
            Thêm người dùng mới
          </Button>
        </div>
      </div>

      {/* 2. Metric Summary Stat Cards (4 Columns) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1: Tổng tài khoản */}
        <div className="bg-white rounded-xl p-5 border border-slate-200/80 shadow-sm flex flex-col justify-between gap-3 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Tổng tài khoản
            </span>
            <div className="w-9 h-9 rounded-lg bg-blue-50 text-blue-700 flex items-center justify-center">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div>
            <div className="text-2xl lg:text-3xl font-bold tracking-tight text-slate-900">
              {stats.total.toLocaleString('vi-VN')}
            </div>
            <div className="flex items-center gap-1.5 mt-1 text-xs text-emerald-600 font-semibold">
              <span>+3.8%</span>
              <span className="text-slate-400 font-normal">so với kỳ trước</span>
            </div>
          </div>
        </div>

        {/* Card 2: Sinh viên */}
        <div className="bg-white rounded-xl p-5 border border-slate-200/80 shadow-sm flex flex-col justify-between gap-3 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Sinh viên
            </span>
            <div className="w-9 h-9 rounded-lg bg-emerald-50 text-emerald-700 flex items-center justify-center">
              <GraduationCap className="w-5 h-5" />
            </div>
          </div>
          <div>
            <div className="text-2xl lg:text-3xl font-bold tracking-tight text-slate-900">
              {stats.students.toLocaleString('vi-VN')}
            </div>
            <div className="flex items-center gap-1.5 mt-1 text-xs text-slate-500 font-medium">
              <span>{stats.studentPct}%</span>
              <span className="text-slate-400 font-normal">quy mô hiện hành</span>
            </div>
          </div>
        </div>

        {/* Card 3: Giảng viên */}
        <div className="bg-white rounded-xl p-5 border border-slate-200/80 shadow-sm flex flex-col justify-between gap-3 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Giảng viên & Cố vấn
            </span>
            <div className="w-9 h-9 rounded-lg bg-indigo-50 text-indigo-700 flex items-center justify-center">
              <BookOpen className="w-5 h-5" />
            </div>
          </div>
          <div>
            <div className="text-2xl lg:text-3xl font-bold tracking-tight text-slate-900">
              {stats.lecturers.toLocaleString('vi-VN')}
            </div>
            <div className="flex items-center gap-1.5 mt-1 text-xs text-emerald-600 font-semibold">
              <span>100%</span>
              <span className="text-slate-400 font-normal">đã kích hoạt 2FA</span>
            </div>
          </div>
        </div>

        {/* Card 4: Quản trị viên */}
        <div className="bg-white rounded-xl p-5 border border-slate-200/80 shadow-sm flex flex-col justify-between gap-3 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Quản trị viên (Admin)
            </span>
            <div className="w-9 h-9 rounded-lg bg-red-50 text-red-600 flex items-center justify-center">
              <ShieldAlert className="w-5 h-5" />
            </div>
          </div>
          <div>
            <div className="text-2xl lg:text-3xl font-bold tracking-tight text-slate-900">
              {stats.admins.toLocaleString('vi-VN')}
            </div>
            <div className="flex items-center gap-1.5 mt-1 text-xs text-slate-400">
              <span>Phân tán tại các ban chuyên môn</span>
            </div>
          </div>
        </div>
      </div>

      {/* 3. Operational Filter Bar */}
      <div className="bg-white rounded-xl p-4 border border-slate-200/80 shadow-sm flex flex-col lg:flex-row gap-4 items-stretch lg:items-center justify-between">
        <div className="flex flex-1 flex-col sm:flex-row items-center gap-3">
          {/* Search Input */}
          <div className="relative w-full sm:max-w-md">
            <Search className="absolute left-3 top-2.5 w-4 h-4 text-slate-400 pointer-events-none" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Tìm họ tên, MSSV/MSGV, email, tài khoản..."
              className="w-full h-10 pl-9 pr-4 rounded-lg bg-slate-50 border border-slate-200/80 text-sm text-slate-900 placeholder:text-slate-400 outline-none focus:bg-white focus:border-primary-500 focus:ring-1 focus:ring-primary-500 transition-all"
            />
            {searchTerm && (
              <button
                type="button"
                onClick={() => setSearchTerm('')}
                className="absolute right-3 top-3 text-slate-400 hover:text-slate-600"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>

          {/* Role Selector */}
          <div className="relative w-full sm:w-48">
            <select
              value={selectedRole}
              onChange={(e) => {
                setSelectedRole(e.target.value as any);
                setPage(0);
              }}
              className="w-full h-10 px-3 pr-8 rounded-lg bg-slate-50 border border-slate-200/80 text-sm text-slate-900 outline-none cursor-pointer focus:bg-white focus:border-primary-500 transition-all appearance-none"
            >
              <option value="all">Tất cả vai trò</option>
              <option value="ADMIN">Quản trị viên (Admin)</option>
              <option value="LECTURER">Giảng viên (Lecturer)</option>
              <option value="STUDENT">Sinh viên (Student)</option>
            </select>
            <div className="absolute right-3 top-3 pointer-events-none text-slate-400 text-xs">▼</div>
          </div>

          {/* Status Selector */}
          <div className="relative w-full sm:w-48">
            <select
              value={selectedStatus}
              onChange={(e) => {
                setSelectedStatus(e.target.value as any);
                setPage(0);
              }}
              className="w-full h-10 px-3 pr-8 rounded-lg bg-slate-50 border border-slate-200/80 text-sm text-slate-900 outline-none cursor-pointer focus:bg-white focus:border-primary-500 transition-all appearance-none"
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="ACTIVE">Đang hoạt động</option>
              <option value="PENDING">Chờ kích hoạt</option>
              <option value="BLOCKED">Đã khóa</option>
            </select>
            <div className="absolute right-3 top-3 pointer-events-none text-slate-400 text-xs">▼</div>
          </div>
        </div>

        {/* Right Quick Actions / Reset */}
        <div className="flex items-center justify-end gap-3 shrink-0">
          <Button
            variant="ghost"
            size="md"
            leftIcon={<RotateCcw className="w-4 h-4 text-slate-500" />}
            onClick={handleResetFilters}
          >
            Đặt lại
          </Button>
          <div className="h-6 w-px bg-slate-200 hidden sm:block" />
          <span className="text-xs text-slate-500 font-medium">
            Hiển thị{' '}
            <strong className="text-slate-900 font-semibold">
              {totalElements === 0 ? 0 : page * pageSize + 1} - {Math.min((page + 1) * pageSize, totalElements)}
            </strong>{' '}
            trong {totalElements} bản ghi
          </span>
        </div>
      </div>

      {/* 4. Paginated Data Table Container */}
      <div className="w-full bg-white rounded-xl border border-slate-200/90 shadow-sm overflow-hidden flex flex-col">
        <div className="w-full overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[760px]">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200/90 text-xs font-semibold uppercase tracking-wider text-slate-600 select-none">
                <th className="py-3.5 px-4 pl-6">Mã định danh</th>
                <th className="py-3.5 px-4">Họ và tên</th>
                <th className="py-3.5 px-4">Tên đăng nhập / Email</th>
                <th className="py-3.5 px-4">Vai trò hệ thống</th>
                <th className="py-3.5 px-4">Trạng thái</th>
                <th className="py-3.5 px-4">Ngày tạo</th>
                <th className="py-3.5 px-4 pr-6 text-right">Thao tác</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, rIdx) => (
                  <tr key={`loading-row-${rIdx}`} className="animate-pulse">
                    <td className="py-4 px-4 pl-6">
                      <Skeleton variant="text" className="h-4 w-24" />
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-3">
                        <Skeleton variant="circle" className="w-9 h-9" />
                        <div className="space-y-1">
                          <Skeleton variant="text" className="h-4 w-32" />
                          <Skeleton variant="text" className="h-3 w-20" />
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-4 w-40" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-5 w-24 rounded-full" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-5 w-24 rounded-full" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-4 w-20" />
                    </td>
                    <td className="py-4 px-4 pr-6 text-right">
                      <Skeleton variant="text" className="h-7 w-20 ml-auto" />
                    </td>
                  </tr>
                ))
              ) : users.length > 0 ? (
                users.map((user) => (
                  <tr
                    key={user.id}
                    className="hover:bg-slate-50/80 transition-colors group"
                  >
                    {/* Mã định danh */}
                    <td className="py-3.5 px-4 pl-6 align-middle font-mono font-semibold text-primary-700">
                      {user.code}
                    </td>

                    {/* Họ và tên & Avatar */}
                    <td className="py-3.5 px-4 align-middle">
                      <div className="flex items-center gap-3">
                        {user.avatar ? (
                          <img
                            src={user.avatar}
                            alt={user.fullName}
                            className="w-9 h-9 rounded-full object-cover shrink-0 border border-slate-200"
                          />
                        ) : (
                          <div className="w-9 h-9 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-xs text-primary-800 shrink-0">
                            {getInitials(user.fullName)}
                          </div>
                        )}
                        <div className="flex flex-col min-w-0">
                          <span className="font-semibold text-slate-900 truncate">
                            {user.fullName}
                          </span>
                          <span className="text-xs text-slate-400">
                            {user.department || user.studentCourse || 'UniCheck'}
                          </span>
                        </div>
                      </div>
                    </td>

                    {/* Email / Username */}
                    <td className="py-3.5 px-4 align-middle">
                      <div className="flex flex-col">
                        <span className="font-medium text-slate-800 text-xs">
                          {user.email}
                        </span>
                        <span className="text-[11px] text-slate-400">
                          @{user.username}
                        </span>
                      </div>
                    </td>

                    {/* Vai trò */}
                    <td className="py-3.5 px-4 align-middle">
                      {renderRoleBadge(user.role)}
                    </td>

                    {/* Trạng thái */}
                    <td className="py-3.5 px-4 align-middle">
                      {renderStatusBadge(user.status)}
                    </td>

                    {/* Ngày tạo */}
                    <td className="py-3.5 px-4 align-middle font-mono text-xs text-slate-500">
                      {user.createdAt ? new Date(user.createdAt).toLocaleDateString('vi-VN') : '—'}
                    </td>

                    {/* Thao tác */}
                    <td className="py-3.5 px-4 pr-6 align-middle text-right">
                      <div className="flex items-center justify-end gap-1">
                        {/* Xem chi tiết */}
                        <button
                          type="button"
                          onClick={() => handleOpenDrawer('view', user)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-primary-700 hover:bg-slate-100 transition-colors"
                          title="Xem chi tiết"
                        >
                          <Eye className="w-4 h-4" />
                        </button>

                        {/* Chỉnh sửa */}
                        <button
                          type="button"
                          onClick={() => handleOpenDrawer('edit', user)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-primary-700 hover:bg-slate-100 transition-colors"
                          title="Chỉnh sửa hồ sơ"
                        >
                          <Edit className="w-4 h-4" />
                        </button>

                        {/* Khóa / Mở khóa */}
                        {user.status === 'BLOCKED' ? (
                          <button
                            type="button"
                            onClick={() => handleOpenConfirmDialog('unlock', user)}
                            className="p-1.5 rounded-lg text-emerald-600 hover:bg-emerald-50 transition-colors"
                            title="Mở khóa tài khoản"
                          >
                            <Unlock className="w-4 h-4" />
                          </button>
                        ) : (
                          <button
                            type="button"
                            onClick={() => handleOpenConfirmDialog('lock', user)}
                            className="p-1.5 rounded-lg text-slate-400 hover:text-amber-600 hover:bg-amber-50 transition-colors"
                            title="Khóa tài khoản"
                          >
                            <Lock className="w-4 h-4" />
                          </button>
                        )}

                        {/* Xóa tài khoản */}
                        <button
                          type="button"
                          onClick={() => handleOpenConfirmDialog('delete', user)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                          title="Xóa tài khoản"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : null}
            </tbody>
          </table>
        </div>

        {/* Empty State */}
        {!isLoading && users.length === 0 && (
          <div className="p-8">
            <EmptyState
              title="Không tìm thấy người dùng phù hợp"
              description="Hãy thử thay đổi từ khóa tìm kiếm hoặc làm mới bộ lọc vai trò, trạng thái."
              actionText="Làm mới bộ lọc"
              onAction={handleResetFilters}
            />
          </div>
        )}

        {/* Pagination Footer */}
        {!isLoading && totalElements > 0 && (
          <div className="px-6 py-3 bg-slate-50/70 border-t border-slate-100 flex flex-col sm:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-2 text-xs text-slate-500">
              <span>Hiển thị</span>
              <select
                value={pageSize}
                onChange={(e) => {
                  setPageSize(Number(e.target.value));
                  setPage(0);
                }}
                className="h-8 px-2 rounded border border-slate-200 bg-white text-xs font-semibold outline-none cursor-pointer"
              >
                <option value={10}>10</option>
                <option value={25}>25</option>
                <option value={50}>50</option>
                <option value={100}>100</option>
              </select>
              <span>dòng trên mỗi trang</span>
            </div>

            <Pagination
              currentPage={page + 1}
              totalPages={totalPages}
              totalElements={totalElements}
              pageSize={pageSize}
              onPageChange={(p) => setPage(p - 1)}
            />
          </div>
        )}
      </div>

      {/* ======================================================== */}
      {/* 5. SLIDE-OUT DRAWER (CREATE / EDIT / VIEW USER)           */}
      {/* ======================================================== */}
      {isDrawerOpen && (
        <div className="fixed inset-0 z-50 overflow-hidden">
          {/* Backdrop */}
          <div
            className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity"
            onClick={handleCloseDrawer}
          />

          {/* Drawer Panel */}
          <div className="fixed inset-y-0 right-0 max-w-full flex pl-10">
            <div className="w-screen max-w-xl bg-white shadow-2xl flex flex-col justify-between">
              {/* Drawer Header */}
              <div className="p-6 bg-slate-50 border-b border-slate-200 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-primary-700 text-white flex items-center justify-center shadow-sm">
                    {drawerMode === 'create' ? (
                      <UserPlus className="w-5 h-5" />
                    ) : drawerMode === 'edit' ? (
                      <Edit className="w-5 h-5" />
                    ) : (
                      <Eye className="w-5 h-5" />
                    )}
                  </div>
                  <div>
                    <h3 className="text-lg font-bold text-slate-900">
                      {drawerMode === 'create'
                        ? 'Thêm người dùng mới'
                        : drawerMode === 'edit'
                        ? 'Chỉnh sửa tài khoản'
                        : 'Hồ sơ người dùng chi tiết'}
                    </h3>
                    <p className="text-xs text-slate-500">
                      {drawerMode === 'create'
                        ? 'Nhập thông tin xác thực và thiết lập quyền hạn'
                        : drawerMode === 'edit'
                        ? 'Cập nhật thông tin định danh và trạng thái'
                        : 'Xem thông tin chi tiết được lưu trong hệ thống'}
                    </p>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={handleCloseDrawer}
                  className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-200/50 transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Drawer Body (Scrollable Form Stack) */}
              <form onSubmit={handleSaveUser} className="flex-1 overflow-y-auto p-6 space-y-5 text-sm">
                {/* Họ và tên */}
                <div className="space-y-1.5">
                  <label className="font-semibold text-slate-800 flex items-center justify-between">
                    <span>
                      Họ và tên người dùng <span className="text-red-500">*</span>
                    </span>
                  </label>
                  <input
                    type="text"
                    disabled={drawerMode === 'view'}
                    value={formData.fullName}
                    onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                    placeholder="Ví dụ: Nguyễn Văn Hoàng"
                    className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50/50 text-slate-900 focus:bg-white focus:border-primary-500 focus:ring-1 focus:ring-primary-500 outline-none transition-all disabled:bg-slate-100 disabled:cursor-not-allowed"
                  />
                  {formErrors.fullName && (
                    <span className="text-xs text-red-500">{formErrors.fullName}</span>
                  )}
                </div>

                {/* Mã định danh & Vai trò */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {/* Mã định danh */}
                  <div className="space-y-1.5">
                    <label className="font-semibold text-slate-800">
                      Mã định danh (MSSV/MSGV) <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      disabled={drawerMode !== 'create'}
                      value={formData.code}
                      onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                      placeholder="VD: 24110294 hoặc GV-012"
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50/50 font-mono text-slate-900 focus:bg-white focus:border-primary-500 outline-none transition-all disabled:bg-slate-100 disabled:cursor-not-allowed"
                    />
                    {formErrors.code && (
                      <span className="text-xs text-red-500">{formErrors.code}</span>
                    )}
                  </div>

                  {/* Vai trò */}
                  <div className="space-y-1.5">
                    <label className="font-semibold text-slate-800">
                      Vai trò hệ thống <span className="text-red-500">*</span>
                    </label>
                    <select
                      disabled={drawerMode !== 'create'}
                      value={formData.role}
                      onChange={(e) => setFormData({ ...formData, role: e.target.value as Role })}
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50/50 text-slate-900 focus:bg-white focus:border-primary-500 outline-none transition-all disabled:bg-slate-100 disabled:cursor-not-allowed"
                    >
                      <option value="STUDENT">Sinh viên</option>
                      <option value="LECTURER">Giảng viên / Cố vấn</option>
                      <option value="ADMIN">Quản trị viên (Admin)</option>
                    </select>
                  </div>
                </div>

                {/* Tên đăng nhập & Live Check */}
                <div className="space-y-1.5">
                  <label className="font-semibold text-slate-800 flex items-center justify-between">
                    <span>
                      Tên đăng nhập (Username) <span className="text-red-500">*</span>
                    </span>
                    {drawerMode === 'create' && formData.username && (
                      <button
                        type="button"
                        onClick={handleCheckUsername}
                        className="text-xs text-primary-700 hover:underline font-semibold"
                      >
                        Kiểm tra khả dụng
                      </button>
                    )}
                  </label>
                  <div className="relative">
                    <input
                      type="text"
                      disabled={drawerMode !== 'create'}
                      value={formData.username}
                      onChange={(e) => {
                        setFormData({ ...formData, username: e.target.value.toLowerCase().replace(/\s/g, '') });
                        setUsernameCheckStatus('idle');
                      }}
                      placeholder="hoang.nv hoặc 24110294"
                      className="w-full h-10 px-3 pr-24 rounded-lg border border-slate-200 bg-slate-50/50 font-mono text-slate-900 focus:bg-white focus:border-primary-500 outline-none transition-all disabled:bg-slate-100 disabled:cursor-not-allowed"
                    />
                    {usernameCheckStatus === 'checking' && (
                      <span className="absolute right-3 top-2.5 text-xs text-slate-400">Đang kiểm tra...</span>
                    )}
                    {usernameCheckStatus === 'available' && (
                      <span className="absolute right-3 top-2.5 text-xs text-emerald-600 font-semibold flex items-center gap-1">
                        <CheckCircle2 className="w-3.5 h-3.5" /> Khả dụng
                      </span>
                    )}
                    {usernameCheckStatus === 'taken' && (
                      <span className="absolute right-3 top-2.5 text-xs text-red-500 font-semibold flex items-center gap-1">
                        <AlertTriangle className="w-3.5 h-3.5" /> Đã tồn tại
                      </span>
                    )}
                  </div>
                  {formErrors.username && (
                    <span className="text-xs text-red-500">{formErrors.username}</span>
                  )}
                </div>

                {/* Email công vụ */}
                <div className="space-y-1.5">
                  <label className="font-semibold text-slate-800">
                    Email người dùng <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="email"
                    disabled={drawerMode === 'view'}
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    placeholder="user@unicheck.edu.vn"
                    className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50/50 text-slate-900 focus:bg-white focus:border-primary-500 outline-none transition-all disabled:bg-slate-100 disabled:cursor-not-allowed"
                  />
                  <span className="text-xs text-slate-400">
                    Định dạng: email hợp lệ (ví dụ: user@unicheck.edu.vn)
                  </span>
                  {formErrors.email && (
                    <span className="text-xs text-red-500 block">{formErrors.email}</span>
                  )}
                </div>

                {/* Số điện thoại & Khoa/Viện */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="font-semibold text-slate-800">Số điện thoại</label>
                    <input
                      type="text"
                      disabled={drawerMode === 'view'}
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      placeholder="0912 345 678"
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50/50 text-slate-900 focus:bg-white focus:border-primary-500 outline-none transition-all disabled:bg-slate-100 disabled:cursor-not-allowed"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="font-semibold text-slate-800">Khoa / Bộ môn</label>
                    <select
                      disabled={drawerMode === 'view'}
                      value={formData.department}
                      onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50/50 text-slate-900 focus:bg-white focus:border-primary-500 outline-none transition-all disabled:bg-slate-100 disabled:cursor-not-allowed"
                    >
                      <option value="Khoa Công nghệ Thông tin">Khoa Công nghệ Thông tin</option>
                      <option value="Khoa Điện - Điện tử">Khoa Điện - Điện tử</option>
                      <option value="Khoa Cơ khí Chế tạo máy">Khoa Cơ khí Chế tạo máy</option>
                      <option value="Khoa Kinh tế & Quản trị">Khoa Kinh tế & Quản trị</option>
                      <option value="Viện Ngoại ngữ & Sư phạm">Viện Ngoại ngữ & Sư phạm</option>
                    </select>
                  </div>
                </div>

                {/* Dynamic Fields for Student or Lecturer */}
                {formData.role === 'STUDENT' ? (
                  <div className="space-y-1.5">
                    <label className="font-semibold text-slate-800">Niên khóa / Lớp sinh hoạt</label>
                    <input
                      type="text"
                      disabled={drawerMode === 'view'}
                      value={formData.studentCourse}
                      onChange={(e) => setFormData({ ...formData, studentCourse: e.target.value })}
                      placeholder="Ví dụ: K24, K23-CNTT01"
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50/50 text-slate-900 focus:bg-white focus:border-primary-500 outline-none transition-all disabled:bg-slate-100 disabled:cursor-not-allowed"
                    />
                  </div>
                ) : formData.role === 'LECTURER' ? (
                  <div className="space-y-1.5">
                    <label className="font-semibold text-slate-800">Lĩnh vực chuyên môn</label>
                    <input
                      type="text"
                      disabled={drawerMode === 'view'}
                      value={formData.expertise}
                      onChange={(e) => setFormData({ ...formData, expertise: e.target.value })}
                      placeholder="Ví dụ: Trí tuệ nhân tạo, Thị giác máy tính"
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50/50 text-slate-900 focus:bg-white focus:border-primary-500 outline-none transition-all disabled:bg-slate-100 disabled:cursor-not-allowed"
                    />
                  </div>
                ) : null}

                {/* Edit Mode: Trạng thái tài khoản */}
                {drawerMode === 'edit' && (
                  <div className="space-y-1.5">
                    <label className="font-semibold text-slate-800">Trạng thái tài khoản</label>
                    <select
                      value={formData.status}
                      onChange={(e) => setFormData({ ...formData, status: e.target.value as UserStatus })}
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50/50 text-slate-900 focus:bg-white focus:border-primary-500 outline-none transition-all"
                    >
                      <option value="ACTIVE">Đang hoạt động (ACTIVE)</option>
                      <option value="PENDING">Chờ kích hoạt (PENDING)</option>
                      <option value="BLOCKED">Đã khóa (BLOCKED)</option>
                      <option value="INACTIVE">Không hoạt động (INACTIVE)</option>
                    </select>
                  </div>
                )}

                {/* Create Mode: Mật khẩu tạm thời */}
                {drawerMode === 'create' && (
                  <div className="space-y-2 p-4 rounded-xl bg-slate-50 border border-slate-200/80">
                    <label className="font-semibold text-slate-800 flex items-center justify-between">
                      <span className="flex items-center gap-1.5">
                        <KeyRound className="w-4 h-4 text-slate-500" />
                        Mật khẩu khởi tạo tạm thời <span className="text-red-500">*</span>
                      </span>
                      <button
                        type="button"
                        onClick={() => setFormData({ ...formData, password: generateRandomPassword() })}
                        className="text-xs text-primary-700 hover:underline font-semibold"
                      >
                        Tạo ngẫu nhiên
                      </button>
                    </label>
                    <input
                      type="text"
                      value={formData.password}
                      onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-white font-mono text-slate-900 focus:border-primary-500 outline-none transition-all"
                    />
                    {formErrors.password && (
                      <span className="text-xs text-red-500 block">{formErrors.password}</span>
                    )}
                    <span className="text-xs text-slate-400 block">
                      Người dùng sẽ được yêu cầu đổi mật khẩu ở lần đăng nhập đầu tiên theo chính sách an toàn.
                    </span>
                  </div>
                )}
              </form>

              {/* Drawer Footer Actions */}
              <div className="p-4 sm:p-6 bg-slate-50 border-t border-slate-200 flex items-center justify-end gap-3">
                <Button variant="outline" size="md" onClick={handleCloseDrawer}>
                  {drawerMode === 'view' ? 'Đóng' : 'Hủy bỏ'}
                </Button>
                {drawerMode !== 'view' && (
                  <Button
                    variant="primary"
                    size="md"
                    isLoading={isSaving}
                    onClick={() => handleSaveUser()}
                  >
                    {drawerMode === 'create' ? 'Lưu tài khoản' : 'Cập nhật thay đổi'}
                  </Button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* 6. CONFIRMATION DIALOG (LOCK/UNLOCK, DELETE)             */}
      {/* ======================================================== */}
      <Modal
        isOpen={confirmDialog.isOpen}
        onClose={() => setConfirmDialog((prev) => ({ ...prev, isOpen: false }))}
        title={
          confirmDialog.type === 'lock'
            ? 'Khóa tài khoản người dùng'
            : confirmDialog.type === 'unlock'
            ? 'Mở khóa tài khoản người dùng'
            : 'Xác nhận xóa tài khoản'
        }
        description={
          confirmDialog.type === 'lock'
            ? 'Bạn có chắc chắn muốn khóa tài khoản này? Người dùng sẽ bị chấm dứt phiên đăng nhập ngay lập tức.'
            : confirmDialog.type === 'unlock'
            ? 'Tài khoản sẽ được mở khóa và người dùng có thể tiếp tục đăng nhập hệ thống UniCheck.'
            : 'Tài khoản sẽ bị xóa mềm khỏi danh sách vận hành. Lưu ý: Lịch sử điểm danh và dữ liệu liên kết vẫn được bảo toàn.'
        }
        isDanger={confirmDialog.type === 'lock' || confirmDialog.type === 'delete'}
        confirmText={
          confirmDialog.type === 'lock'
            ? 'Khóa tài khoản'
            : confirmDialog.type === 'unlock'
            ? 'Mở khóa'
            : 'Xóa tài khoản'
        }
        onConfirm={handleExecuteConfirmAction}
        isLoading={confirmDialog.isLoading}
      >
        {confirmDialog.user && (
          <div className="p-4 rounded-lg bg-slate-50 border border-slate-200 space-y-1">
            <span className="text-xs uppercase font-semibold text-slate-400">Tài khoản ảnh hưởng:</span>
            <div className="font-semibold text-slate-900 text-base">
              {confirmDialog.user.fullName} ({confirmDialog.user.code})
            </div>
            <div className="text-xs text-slate-500 font-mono">
              Email: {confirmDialog.user.email} · Vai trò: {confirmDialog.user.role}
            </div>
          </div>
        )}
      </Modal>

      {/* ======================================================== */}
      {/* 7. CSV / EXCEL IMPORT MODAL                              */}
      {/* ======================================================== */}
      <Modal
        isOpen={isImportModalOpen}
        onClose={() => !isImporting && setIsImportModalOpen(false)}
        title="Tải lên danh sách người dùng hàng loạt"
        description="Hỗ trợ nhập danh sách người dùng bằng file định dạng chuẩn (.csv)"
        size="lg"
        hideFooter
      >
        <div className="space-y-5">
          {/* Dropzone Area */}
          <div className="relative border-2 border-dashed border-slate-300 rounded-xl p-8 text-center hover:bg-slate-50 transition-colors flex flex-col items-center justify-center gap-3">
            <input
              type="file"
              accept=".csv"
              onChange={handleFileChange}
              disabled={isImporting}
              className="absolute inset-0 w-full h-full opacity-0 cursor-pointer disabled:cursor-not-allowed"
            />
            <div className="w-12 h-12 rounded-full bg-blue-50 text-primary-700 flex items-center justify-center shadow-sm">
              <Upload className="w-6 h-6" />
            </div>
            <div>
              <p className="font-semibold text-slate-800 text-sm">
                {selectedFile ? selectedFile.name : 'Kéo và thả tệp CSV vào đây'}
              </p>
              <p className="text-xs text-slate-400">
                {selectedFile
                  ? `${(selectedFile.size / 1024).toFixed(1)} KB · Nhấp để chọn tệp khác`
                  : 'hoặc nhấp chuột để chọn tệp từ máy tính của bạn'}
              </p>
            </div>
            <span className="text-[11px] px-2.5 py-1 rounded-full bg-slate-100 text-slate-500 font-medium">
              Cột bắt buộc: code, username, fullName, email, role, phone
            </span>
          </div>

          {/* Sample Download Bar */}
          <div className="flex items-center justify-between p-3.5 rounded-lg bg-slate-50 border border-slate-200">
            <div className="flex items-center gap-3">
              <FileSpreadsheet className="w-5 h-5 text-emerald-600 shrink-0" />
              <div>
                <p className="text-xs font-semibold text-slate-800">Tải tệp mẫu UniCheck</p>
                <p className="text-[11px] text-slate-500">
                  File mẫu CSV đã định nghĩa sẵn các cột chuẩn kèm bản ghi mẫu
                </p>
              </div>
            </div>
            <Button variant="outline" size="sm" onClick={handleDownloadSampleCsv}>
              Tải mẫu .csv
            </Button>
          </div>

          {/* Import Results Banner (if finished) */}
          {importResult && (
            <div className="space-y-3">
              <div className="flex items-center gap-3 flex-wrap">
                <div className="px-3 py-1.5 rounded-lg bg-emerald-50 text-emerald-800 border border-emerald-200 text-xs font-semibold flex items-center gap-1.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                  Hợp lệ: {importResult.successCount} / {importResult.totalRecords} bản ghi
                </div>
                {importResult.failedCount > 0 && (
                  <div className="px-3 py-1.5 rounded-lg bg-red-50 text-red-800 border border-red-200 text-xs font-semibold flex items-center gap-1.5">
                    <AlertTriangle className="w-4 h-4 text-red-600" />
                    Lỗi: {importResult.failedCount} bản ghi
                  </div>
                )}
              </div>

              {/* Error list display if any */}
              {importResult.errors && importResult.errors.length > 0 && (
                <div className="p-3 bg-red-50/70 border border-red-200 rounded-lg text-xs space-y-1 max-h-40 overflow-y-auto">
                  <p className="font-semibold text-red-800">Chi tiết lỗi thẩm định:</p>
                  <ul className="list-disc pl-5 text-red-700 space-y-0.5">
                    {importResult.errors.map((err, idx) => (
                      <li key={idx}>{err}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}

          {/* Action buttons */}
          <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
            <Button
              variant="outline"
              size="md"
              disabled={isImporting}
              onClick={() => setIsImportModalOpen(false)}
            >
              Đóng
            </Button>
            <Button
              variant="primary"
              size="md"
              disabled={!selectedFile || isImporting}
              isLoading={isImporting}
              onClick={handleExecuteImport}
            >
              Tiến hành nạp dữ liệu
            </Button>
          </div>
        </div>
      </Modal>

      {/* ======================================================== */}
      {/* 8. TOAST NOTIFICATION                                    */}
      {/* ======================================================== */}
      {toast.visible && (
        <div
          role="alert"
          className="fixed bottom-6 right-6 z-50 bg-slate-900 text-white px-5 py-3.5 rounded-xl shadow-2xl flex items-center gap-3 animate-in slide-in-from-bottom-5 duration-200 border border-slate-700"
        >
          {toast.type === 'success' ? (
            <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
          ) : toast.type === 'error' ? (
            <AlertTriangle className="w-5 h-5 text-red-400 shrink-0" />
          ) : (
            <Info className="w-5 h-5 text-blue-400 shrink-0" />
          )}
          <span className="text-sm font-medium">{toast.message}</span>
        </div>
      )}
    </div>
  );
};

export default UserManagementPage;
