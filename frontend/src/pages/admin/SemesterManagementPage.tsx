import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Calendar,
  Lock,
  PlusCircle,
  Search,
  RotateCcw,
  Download,
  Edit,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  Info,
  ChevronRight,
  Archive,
  Clock,
  ShieldCheck,
  Check,
  CalendarDays,
  X,
} from 'lucide-react';
import {
  getSemestersApi,
  getActiveSemesterApi,
  checkSemesterCodeApi,
  createSemesterApi,
  updateSemesterApi,
  lockSemesterApi,
  deleteSemesterApi,
} from '../../api/semesters.api';
import {
  SemesterResponse,
  SemesterStatus,
  SemesterCreateRequest,
  SemesterUpdateRequest,
} from '../../types/api';
import { Button } from '../../common-ui/Button';
import { Badge } from '../../common-ui/Badge';
import { Modal } from '../../common-ui/Modal';
import { Pagination } from '../../common-ui/Pagination';
import { Skeleton } from '../../common-ui/Skeleton';
import { EmptyState } from '../../common-ui/EmptyState';

export const SemesterManagementPage: React.FC = () => {
  // ==========================================
  // STATE: Table Data & Active Semester & Filters
  // ==========================================
  const [semesters, setSemesters] = useState<SemesterResponse[]>([]);
  const [activeSemester, setActiveSemester] = useState<SemesterResponse | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [page, setPage] = useState<number>(0);
  const [pageSize, setPageSize] = useState<number>(10);
  const [totalElements, setTotalElements] = useState<number>(0);
  const [totalPages, setTotalPages] = useState<number>(1);

  const [searchTerm, setSearchTerm] = useState<string>('');
  const [debouncedSearch, setDebouncedSearch] = useState<string>('');
  const [selectedStatus, setSelectedStatus] = useState<SemesterStatus | 'all'>('all');

  // Debounce search
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(searchTerm);
      setPage(0);
    }, 400);
    return () => clearTimeout(handler);
  }, [searchTerm]);

  // Load Active Semester
  const loadActiveSemester = useCallback(async () => {
    try {
      const res = await getActiveSemesterApi();
      if (res.success && res.data) {
        setActiveSemester(res.data);
      } else {
        setActiveSemester(null);
      }
    } catch (e) {
      console.error('Không thể tải học kỳ hiện hành', e);
    }
  }, []);

  // Load Semesters
  const loadSemesters = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const res = await getSemestersApi({
        search: debouncedSearch || undefined,
        status: selectedStatus !== 'all' ? selectedStatus : undefined,
        page,
        size: pageSize,
        sort: 'startDate,desc',
      });

      if (res.success && res.data) {
        setSemesters(res.data.content || []);
        setTotalElements(res.data.totalElements || 0);
        setTotalPages(res.data.totalPages || 1);
      } else {
        setErrorMessage(res.message || 'Không thể tải danh sách học kỳ');
      }
    } catch (err: any) {
      setErrorMessage(err.message || 'Lỗi kết nối khi tải danh sách học kỳ');
    } finally {
      setIsLoading(false);
    }
  }, [debouncedSearch, selectedStatus, page, pageSize]);

  useEffect(() => {
    loadActiveSemester();
    loadSemesters();
  }, [loadActiveSemester, loadSemesters]);

  const handleResetFilters = () => {
    setSearchTerm('');
    setDebouncedSearch('');
    setSelectedStatus('all');
    setPage(0);
  };

  // ==========================================
  // STATE: Modal Create / Edit Semester
  // ==========================================
  const [isSemesterModalOpen, setIsSemesterModalOpen] = useState<boolean>(false);
  const [modalMode, setModalMode] = useState<'create' | 'edit'>('create');
  const [selectedSemester, setSelectedSemester] = useState<SemesterResponse | null>(null);

  const [formData, setFormData] = useState<{
    code: string;
    name: string;
    startDate: string;
    endDate: string;
    status: SemesterStatus;
    description: string;
    maxSlotPerDay: number;
    slotPerSubjectPerWeek: number;
    slotDuration: number;
    isPublished: boolean;
  }>({
    code: '',
    name: '',
    startDate: '',
    endDate: '',
    status: 'ACTIVE',
    description: '',
    maxSlotPerDay: 6,
    slotPerSubjectPerWeek: 2,
    slotDuration: 50,
    isPublished: true,
  });

  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [isSaving, setIsSaving] = useState<boolean>(false);
  const [codeCheckStatus, setCodeCheckStatus] = useState<'idle' | 'checking' | 'available' | 'taken'>('idle');

  const handleOpenSemesterModal = (mode: 'create' | 'edit', semester?: SemesterResponse) => {
    setModalMode(mode);
    setFormErrors({});
    setCodeCheckStatus('idle');

    if (semester && mode === 'edit') {
      setSelectedSemester(semester);
      setFormData({
        code: semester.code,
        name: semester.name,
        startDate: semester.startDate,
        endDate: semester.endDate,
        status: semester.status,
        description: semester.description || '',
        maxSlotPerDay: semester.config?.maxSlotPerDay || 6,
        slotPerSubjectPerWeek: semester.config?.slotPerSubjectPerWeek || 2,
        slotDuration: semester.config?.slotDuration || 50,
        isPublished: semester.config?.isPublished || true,
      });
    } else {
      setSelectedSemester(null);
      const today = new Date();
      const inFourMonths = new Date(today);
      inFourMonths.setMonth(today.getMonth() + 4);

      setFormData({
        code: '',
        name: '',
        startDate: today.toISOString().slice(0, 10),
        endDate: inFourMonths.toISOString().slice(0, 10),
        status: 'ACTIVE',
        description: '',
        maxSlotPerDay: 6,
        slotPerSubjectPerWeek: 2,
        slotDuration: 50,
        isPublished: true,
      });
    }
    setIsSemesterModalOpen(true);
  };

  const handleCheckCode = async () => {
    if (!formData.code.trim()) return;
    setCodeCheckStatus('checking');
    try {
      const res = await checkSemesterCodeApi(formData.code.trim());
      if (res.data?.available) {
        setCodeCheckStatus('available');
      } else {
        setCodeCheckStatus('taken');
      }
    } catch {
      setCodeCheckStatus('idle');
    }
  };

  const handleSaveSemester = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();

    const errors: Record<string, string> = {};
    if (!formData.name.trim()) errors.name = 'Tên học kỳ là bắt buộc';
    if (!formData.code.trim()) errors.code = 'Mã học kỳ là bắt buộc';
    if (!formData.startDate) errors.startDate = 'Ngày bắt đầu là bắt buộc';
    if (!formData.endDate) errors.endDate = 'Ngày kết thúc là bắt buộc';
    if (formData.startDate && formData.endDate && formData.endDate <= formData.startDate) {
      errors.endDate = 'Ngày kết thúc phải sau ngày bắt đầu';
    }

    if (Object.keys(errors).length > 0) {
      setFormErrors(errors);
      return;
    }

    setIsSaving(true);
    try {
      if (modalMode === 'create') {
        const payload: SemesterCreateRequest = {
          code: formData.code.trim().toUpperCase(),
          name: formData.name.trim(),
          startDate: formData.startDate,
          endDate: formData.endDate,
          status: formData.status,
          description: formData.description.trim() || null,
          maxSlotPerDay: formData.maxSlotPerDay,
          slotPerSubjectPerWeek: formData.slotPerSubjectPerWeek,
          slotDuration: formData.slotDuration,
          isPublished: formData.isPublished,
        };

        const res = await createSemesterApi(payload);
        if (res.success) {
          showToast('Thiết lập học kỳ mới thành công', 'success');
          setIsSemesterModalOpen(false);
          loadSemesters();
          loadActiveSemester();
        } else {
          showToast(res.message || 'Không thể tạo học kỳ', 'error');
        }
      } else if (modalMode === 'edit' && selectedSemester) {
        const payload: SemesterUpdateRequest = {
          name: formData.name.trim(),
          startDate: formData.startDate,
          endDate: formData.endDate,
          status: formData.status,
          description: formData.description.trim() || null,
          maxSlotPerDay: formData.maxSlotPerDay,
          slotPerSubjectPerWeek: formData.slotPerSubjectPerWeek,
          slotDuration: formData.slotDuration,
          isPublished: formData.isPublished,
        };

        const res = await updateSemesterApi(selectedSemester.id, payload);
        if (res.success) {
          showToast('Cập nhật học kỳ thành công', 'success');
          setIsSemesterModalOpen(false);
          loadSemesters();
          loadActiveSemester();
        } else {
          showToast(res.message || 'Không thể cập nhật học kỳ', 'error');
        }
      }
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi lưu thông tin học kỳ', 'error');
    } finally {
      setIsSaving(false);
    }
  };

  // ==========================================
  // STATE: Lock Semester Dialog
  // ==========================================
  const [lockDialog, setLockDialog] = useState<{
    isOpen: boolean;
    semester: SemesterResponse | null;
    isLoading: boolean;
  }>({
    isOpen: false,
    semester: null,
    isLoading: false,
  });

  const handleOpenLockDialog = (semester: SemesterResponse) => {
    setLockDialog({
      isOpen: true,
      semester,
      isLoading: false,
    });
  };

  const handleExecuteLock = async () => {
    if (!lockDialog.semester) return;
    setLockDialog((prev) => ({ ...prev, isLoading: true }));
    try {
      const res = await lockSemesterApi(lockDialog.semester.id);
      if (res.success) {
        showToast(`Đã khóa sổ dữ liệu học kỳ ${lockDialog.semester.code} thành công`, 'success');
        setLockDialog({ isOpen: false, semester: null, isLoading: false });
        loadSemesters();
        loadActiveSemester();
      } else {
        showToast(res.message || 'Không thể khóa sổ học kỳ', 'error');
      }
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi khóa sổ học kỳ', 'error');
    } finally {
      setLockDialog((prev) => ({ ...prev, isLoading: false }));
    }
  };

  // ==========================================
  // STATE: Delete Semester Dialog
  // ==========================================
  const [deleteDialog, setDeleteDialog] = useState<{
    isOpen: boolean;
    semester: SemesterResponse | null;
    isLoading: boolean;
  }>({
    isOpen: false,
    semester: null,
    isLoading: false,
  });

  const handleOpenDeleteDialog = (semester: SemesterResponse) => {
    setDeleteDialog({
      isOpen: true,
      semester,
      isLoading: false,
    });
  };

  const handleExecuteDelete = async () => {
    if (!deleteDialog.semester) return;
    setDeleteDialog((prev) => ({ ...prev, isLoading: true }));
    try {
      const res = await deleteSemesterApi(deleteDialog.semester.id);
      if (res.success) {
        showToast(`Đã xóa học kỳ ${deleteDialog.semester.code} thành công`, 'success');
        setDeleteDialog({ isOpen: false, semester: null, isLoading: false });
        loadSemesters();
        loadActiveSemester();
      } else {
        showToast(res.message || 'Không thể xóa học kỳ', 'error');
      }
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi xóa học kỳ', 'error');
    } finally {
      setDeleteDialog((prev) => ({ ...prev, isLoading: false }));
    }
  };

  // Export CSV
  const handleExportCsv = () => {
    if (semesters.length === 0) {
      showToast('Không có dữ liệu học kỳ để xuất', 'info');
      return;
    }
    const headers = ['Mã HK', 'Tên học kỳ', 'Ngày bắt đầu', 'Ngày kết thúc', 'Số tuần', 'Trạng thái'];
    const rows = semesters.map((s) => [
      `"${s.code}"`,
      `"${s.name}"`,
      `"${s.startDate}"`,
      `"${s.endDate}"`,
      s.totalWeeks || 0,
      `"${s.status}"`,
    ]);

    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `UniCheck_Semesters_Export_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    showToast('Xuất danh sách học kỳ thành công', 'success');
  };

  // Toast
  const [toast, setToast] = useState<{ visible: boolean; message: string; type: 'success' | 'error' | 'info' }>({
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

  const formatDateVN = (dateStr?: string) => {
    if (!dateStr) return '—';
    const parts = dateStr.split('-');
    if (parts.length === 3) return `${parts[2]}/${parts[1]}/${parts[0]}`;
    return dateStr;
  };

  return (
    <div className="w-full min-h-screen bg-[#faf8ff] p-4 sm:p-6 lg:p-8 flex flex-col gap-6 text-[#131b2e]">
      {/* 1. Breadcrumbs & Header Context (Matching Stitch Screen 4f0245590b1b4c6ab231b412b5ba845d) */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div className="flex flex-col gap-1">
          {/* Breadcrumb */}
          <div className="flex items-center gap-1.5 text-xs text-slate-500 font-medium">
            <span>Quản trị hệ thống</span>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
            <span>Đào tạo & Học vụ</span>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
            <span className="text-primary-700 font-semibold">Học kỳ & Niên khóa</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-slate-900">
            Quản lý học kỳ, Niên khóa & Thời hiệu đào tạo
          </h1>
          <p className="text-sm text-slate-500 max-w-3xl">
            Điều phối các chu kỳ năm học, kích hoạt mốc tính chuyên cần học phần và phân quyền chốt sổ dữ liệu toàn trường.
          </p>
        </div>

        {/* Quick Action Group */}
        <div className="flex items-center gap-2 sm:gap-3 shrink-0 flex-wrap">
          {activeSemester && (
            <Button
              variant="outline"
              size="md"
              leftIcon={<Lock className="w-4 h-4 text-red-600" />}
              onClick={() => handleOpenLockDialog(activeSemester)}
            >
              Khóa sổ học kỳ hiện hành
            </Button>
          )}

          <Button
            variant="primary"
            size="md"
            leftIcon={<PlusCircle className="w-4 h-4" />}
            onClick={() => handleOpenSemesterModal('create')}
            className="shadow-sm"
          >
            Thiết lập học kỳ mới
          </Button>
        </div>
      </div>

      {/* 2. Active Semester Banner (Hero Card Matching Stitch) */}
      {activeSemester ? (
        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-primary-800 via-primary-700 to-blue-700 text-white p-6 lg:p-8 shadow-lg">
          <div className="relative z-10 flex flex-col xl:flex-row xl:items-center justify-between gap-6">
            <div className="flex flex-col gap-3 max-w-2xl">
              <div className="flex flex-wrap items-center gap-2">
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-400/20 border border-emerald-400/40 text-emerald-300 text-xs font-bold uppercase tracking-wider">
                  <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                  {activeSemester.name} đang hoạt động
                </span>
                <span className="px-2.5 py-0.5 rounded-full bg-white/15 font-mono text-xs backdrop-blur-sm">
                  Mã: {activeSemester.code}
                </span>
              </div>

              <div>
                <h2 className="text-xl lg:text-2xl font-bold tracking-tight">
                  Giai đoạn chính quy · {formatDateVN(activeSemester.startDate)} đến {formatDateVN(activeSemester.endDate)}
                </h2>
                <p className="text-sm text-blue-100 mt-1">
                  Hệ thống đang vận hành {activeSemester.totalWeeks || 18} tuần đào tạo. Tự động liên kết các máy chấm công Wi-Fi và trạm Kiosk AI toàn khuôn viên.
                </p>
              </div>

              {/* Realtime Badges */}
              <div className="flex flex-wrap items-center gap-2 pt-1 text-xs text-blue-100">
                <div className="flex items-center gap-1.5 bg-white/10 backdrop-blur-md px-3 py-1.5 rounded-lg border border-white/10">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                  <span>Điểm danh tự động: Đang kích hoạt</span>
                </div>
                <div className="flex items-center gap-1.5 bg-white/10 backdrop-blur-md px-3 py-1.5 rounded-lg border border-white/10">
                  <ShieldCheck className="w-4 h-4 text-emerald-400" />
                  <span>Cấu hình: {activeSemester.config?.maxSlotPerDay || 6} tiết/ngày · {activeSemester.config?.slotDuration || 50} phút/tiết</span>
                </div>
              </div>
            </div>

            {/* Quick Metrics Inside Banner */}
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 shrink-0">
              <div className="bg-white/10 backdrop-blur-md rounded-xl p-4 border border-white/10 flex flex-col justify-between">
                <span className="text-xs text-blue-200">Trạng thái</span>
                <span className="text-xl lg:text-2xl font-bold font-mono">ĐANG MỞ</span>
                <span className="text-[11px] text-emerald-300 flex items-center gap-1 mt-1">
                  <Check className="w-3.5 h-3.5" /> Đồng bộ thời gian thực
                </span>
              </div>

              <div className="bg-white/10 backdrop-blur-md rounded-xl p-4 border border-white/10 flex flex-col justify-between">
                <span className="text-xs text-blue-200">Thời lượng</span>
                <span className="text-xl lg:text-2xl font-bold font-mono">{activeSemester.totalWeeks || 18}</span>
                <span className="text-[11px] text-blue-200 mt-1">tuần đào tạo</span>
              </div>

              <div className="col-span-2 sm:col-span-1 bg-white/10 backdrop-blur-md rounded-xl p-4 border border-white/10 flex flex-col justify-between">
                <span className="text-xs text-blue-200">Niêm phong dữ liệu</span>
                <span className="text-xl lg:text-2xl font-bold font-mono">SHA-256</span>
                <span className="text-[11px] text-blue-200 mt-1">Chống chỉnh sửa điểm</span>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="p-6 rounded-2xl bg-amber-50 border border-amber-200 text-amber-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <AlertTriangle className="w-6 h-6 text-amber-600 shrink-0" />
            <div>
              <p className="font-bold">Hiện chưa có học kỳ nào được kích hoạt (ACTIVE)</p>
              <p className="text-xs text-amber-700">Vui lòng thiết lập học kỳ mới hoặc kích hoạt học kỳ sẵn có để bắt đầu ca giảng dạy và điểm danh.</p>
            </div>
          </div>
          <Button variant="primary" size="sm" onClick={() => handleOpenSemesterModal('create')}>
            Thiết lập ngay
          </Button>
        </div>
      )}

      {/* 3. Operational Filter Toolbar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200/80 shadow-sm flex flex-col lg:flex-row gap-4 items-stretch lg:items-center justify-between">
        <div className="flex flex-1 flex-col sm:flex-row items-center gap-3">
          {/* Search Input */}
          <div className="relative w-full sm:max-w-md">
            <Search className="absolute left-3 top-2.5 w-4 h-4 text-slate-400 pointer-events-none" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Tìm theo mã hoặc tên học kỳ..."
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

          {/* Status Selector */}
          <div className="relative w-full sm:w-52">
            <select
              value={selectedStatus}
              onChange={(e) => {
                setSelectedStatus(e.target.value as any);
                setPage(0);
              }}
              className="w-full h-10 px-3 pr-8 rounded-lg bg-slate-50 border border-slate-200/80 text-sm text-slate-900 outline-none cursor-pointer focus:bg-white focus:border-primary-500 transition-all appearance-none"
            >
              <option value="all">Trạng thái: Tất cả</option>
              <option value="ACTIVE">Đang diễn ra (ACTIVE)</option>
              <option value="UPCOMING">Dự kiến mở (UPCOMING)</option>
              <option value="CLOSED">Đã khóa sổ (CLOSED)</option>
              <option value="ARCHIVED">Lưu trữ (ARCHIVED)</option>
            </select>
            <div className="absolute right-3 top-3 pointer-events-none text-slate-400 text-xs">▼</div>
          </div>
        </div>

        {/* Right Actions */}
        <div className="flex items-center justify-end gap-3 shrink-0">
          <Button
            variant="ghost"
            size="md"
            leftIcon={<RotateCcw className="w-4 h-4 text-slate-500" />}
            onClick={handleResetFilters}
          >
            Đặt lại
          </Button>

          <Button
            variant="outline"
            size="md"
            leftIcon={<Download className="w-4 h-4 text-slate-600" />}
            onClick={handleExportCsv}
          >
            Xuất Excel
          </Button>
        </div>
      </div>

      {/* 4. Primary Semester Master Table */}
      <div className="w-full bg-white rounded-xl border border-slate-200/90 shadow-sm overflow-hidden flex flex-col">
        <div className="w-full overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[760px]">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200/90 text-xs font-semibold uppercase tracking-wider text-slate-600 select-none">
                <th className="py-3.5 px-4 pl-6 w-28">Mã HK</th>
                <th className="py-3.5 px-4 min-w-[220px]">Tên học kỳ</th>
                <th className="py-3.5 px-4 min-w-[200px]">Khung thời gian</th>
                <th className="py-3.5 px-4 w-32">Tuần đào tạo</th>
                <th className="py-3.5 px-4 w-36">Trạng thái</th>
                <th className="py-3.5 px-4 pr-6 text-right w-28">Thao tác</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
              {isLoading ? (
                Array.from({ length: 4 }).map((_, rIdx) => (
                  <tr key={`loading-row-${rIdx}`} className="animate-pulse">
                    <td className="py-4 px-4 pl-6">
                      <Skeleton variant="text" className="h-4 w-16" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-4 w-48" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-4 w-36" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-4 w-16" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-5 w-24 rounded-full" />
                    </td>
                    <td className="py-4 px-4 pr-6 text-right">
                      <Skeleton variant="text" className="h-7 w-20 ml-auto" />
                    </td>
                  </tr>
                ))
              ) : semesters.length > 0 ? (
                semesters.map((sem) => (
                  <tr key={sem.id} className="hover:bg-slate-50/80 transition-colors group">
                    {/* Mã HK */}
                    <td className="py-3.5 px-4 pl-6 align-middle font-mono font-bold text-primary-700">
                      {sem.code}
                    </td>

                    {/* Tên học kỳ */}
                    <td className="py-3.5 px-4 align-middle">
                      <div className="flex flex-col">
                        <span className="font-semibold text-slate-900">{sem.name}</span>
                        <span className="text-xs text-slate-400">
                          {sem.description || 'Chính quy tập trung · Đại học'}
                        </span>
                      </div>
                    </td>

                    {/* Khung thời gian */}
                    <td className="py-3.5 px-4 align-middle font-mono text-xs text-slate-600">
                      <div>
                        {formatDateVN(sem.startDate)} → {formatDateVN(sem.endDate)}
                      </div>
                    </td>

                    {/* Tuần đào tạo */}
                    <td className="py-3.5 px-4 align-middle">
                      <span className="font-semibold text-slate-900">{sem.totalWeeks || 18} tuần</span>
                      <span className="text-xs text-slate-400 block">{sem.config?.maxSlotPerDay || 6} tiết/ngày</span>
                    </td>

                    {/* Trạng thái */}
                    <td className="py-3.5 px-4 align-middle">
                      {sem.status === 'ACTIVE' ? (
                        <Badge variant="active" size="md">
                          Đang diễn ra
                        </Badge>
                      ) : sem.status === 'CLOSED' || sem.status === 'ARCHIVED' ? (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-100 text-slate-700 text-xs font-semibold border border-slate-200">
                          <Archive className="w-3.5 h-3.5 text-slate-500" />
                          Đã khóa sổ
                        </span>
                      ) : (
                        <Badge variant="pending" size="md">
                          Dự kiến mở
                        </Badge>
                      )}
                    </td>

                    {/* Thao tác */}
                    <td className="py-3.5 px-4 pr-6 align-middle text-right">
                      <div className="flex items-center justify-end gap-1">
                        {/* Khóa sổ */}
                        {sem.status === 'ACTIVE' && (
                          <button
                            type="button"
                            onClick={() => handleOpenLockDialog(sem)}
                            className="p-1.5 rounded-lg text-slate-400 hover:text-amber-600 hover:bg-amber-50 transition-colors"
                            title="Khóa sổ học kỳ"
                          >
                            <Lock className="w-4 h-4" />
                          </button>
                        )}

                        {/* Chỉnh sửa */}
                        <button
                          type="button"
                          onClick={() => handleOpenSemesterModal('edit', sem)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-primary-700 hover:bg-slate-100 transition-colors"
                          title="Chỉnh sửa học kỳ"
                        >
                          <Edit className="w-4 h-4" />
                        </button>

                        {/* Xóa */}
                        <button
                          type="button"
                          onClick={() => handleOpenDeleteDialog(sem)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                          title="Xóa học kỳ"
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
        {!isLoading && semesters.length === 0 && (
          <div className="p-8">
            <EmptyState
              title="Không tìm thấy học kỳ phù hợp"
              description="Hãy thử thay đổi từ khóa tìm kiếm hoặc bấm nút 'Đặt lại'."
              actionText="Đặt lại bộ lọc"
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
                <option value={20}>20</option>
              </select>
              <span>kỳ mỗi trang</span>
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

      {/* 5. Analytical Policy Card Grid (3 Cards Matching Stitch) */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="rounded-xl bg-white p-5 border border-slate-200/80 shadow-sm flex flex-col gap-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Quy chuẩn cấm thi
            </span>
            <span className="w-8 h-8 rounded-lg bg-red-50 text-red-600 flex items-center justify-center">
              <Clock className="w-4 h-4" />
            </span>
          </div>
          <div className="text-xl font-bold text-slate-900">Vắng &gt; 20% tổng số tiết</div>
          <p className="text-xs text-slate-500">
            Học sinh chạm ngưỡng vắng trên 20% số tiết quy định sẽ tự động nhận cờ cảnh báo cấm thi và thông báo đến cố vấn học tập.
          </p>
        </div>

        <div className="rounded-xl bg-white p-5 border border-slate-200/80 shadow-sm flex flex-col gap-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Thời hạn khiếu nại điểm danh
            </span>
            <span className="w-8 h-8 rounded-lg bg-blue-50 text-primary-700 flex items-center justify-center">
              <CalendarDays className="w-4 h-4" />
            </span>
          </div>
          <div className="text-xl font-bold text-slate-900">7 ngày làm việc</div>
          <p className="text-xs text-slate-500">
            Tính từ thời điểm kết thúc ca giảng dạy. Quá 7 ngày, trạng thái điểm danh sẽ chuyển sang bất biến, chỉ Admin được mở lại.
          </p>
        </div>

        <div className="rounded-xl bg-white p-5 border border-slate-200/80 shadow-sm flex flex-col gap-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Bảo vệ toàn vẹn (Audit Log)
            </span>
            <span className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-700 flex items-center justify-center">
              <ShieldCheck className="w-4 h-4" />
            </span>
          </div>
          <div className="text-xl font-bold text-slate-900">SHA-256 Checksum</div>
          <p className="text-xs text-slate-500">
            Mọi thao tác khóa sổ học kỳ được niêm phong mật mã vào Sổ nhật ký kiểm định đào tạo của Trường Đại học.
          </p>
        </div>
      </div>

      {/* ======================================================== */}
      {/* 6. MODAL THIẾT LẬP / CHỈNH SỬA HỌC KỲ                     */}
      {/* ======================================================== */}
      <Modal
        isOpen={isSemesterModalOpen}
        onClose={() => !isSaving && setIsSemesterModalOpen(false)}
        title={modalMode === 'create' ? 'Thiết lập học kỳ đào tạo mới' : 'Chỉnh sửa thông tin học kỳ'}
        description="Quản lý mốc thời gian đào tạo, cấu hình ca học và quy chế điểm danh"
        size="lg"
        hideFooter
      >
        <form onSubmit={handleSaveSemester} className="space-y-4 text-sm">
          {/* Tên học kỳ & Mã HK */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="sm:col-span-1 space-y-1">
              <label className="font-semibold text-slate-800 flex items-center justify-between">
                <span>Mã HK <span className="text-red-500">*</span></span>
                {modalMode === 'create' && formData.code && (
                  <button type="button" onClick={handleCheckCode} className="text-[11px] text-primary-700 hover:underline font-semibold">
                    Kiểm tra
                  </button>
                )}
              </label>
              <input
                type="text"
                disabled={modalMode !== 'create'}
                value={formData.code}
                onChange={(e) => {
                  setFormData({ ...formData, code: e.target.value.toUpperCase().replace(/\s/g, '') });
                  setCodeCheckStatus('idle');
                }}
                placeholder="VD: HK242"
                className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 font-mono font-semibold text-slate-900 outline-none focus:bg-white focus:border-primary-500 disabled:bg-slate-100"
              />
              {codeCheckStatus === 'available' && <span className="text-xs text-emerald-600 font-semibold">Mã khả dụng</span>}
              {codeCheckStatus === 'taken' && <span className="text-xs text-red-500 font-semibold">Mã đã tồn tại</span>}
              {formErrors.code && <span className="text-xs text-red-500">{formErrors.code}</span>}
            </div>

            <div className="sm:col-span-2 space-y-1">
              <label className="font-semibold text-slate-800">Tên học kỳ <span className="text-red-500">*</span></label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="VD: Học kỳ II 2024 - 2025"
                className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500"
              />
              {formErrors.name && <span className="text-xs text-red-500">{formErrors.name}</span>}
            </div>
          </div>

          {/* Ngày bắt đầu & Ngày kết thúc */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="space-y-1">
              <label className="font-semibold text-slate-800">Ngày bắt đầu <span className="text-red-500">*</span></label>
              <input
                type="date"
                value={formData.startDate}
                onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500"
              />
              {formErrors.startDate && <span className="text-xs text-red-500">{formErrors.startDate}</span>}
            </div>

            <div className="space-y-1">
              <label className="font-semibold text-slate-800">Ngày kết thúc <span className="text-red-500">*</span></label>
              <input
                type="date"
                value={formData.endDate}
                onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500"
              />
              {formErrors.endDate && <span className="text-xs text-red-500">{formErrors.endDate}</span>}
            </div>
          </div>

          {/* Trạng thái & Cấu hình ca học */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="space-y-1">
              <label className="font-semibold text-slate-800">Trạng thái</label>
              <select
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value as SemesterStatus })}
                className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500"
              >
                <option value="ACTIVE">Đang diễn ra (ACTIVE)</option>
                <option value="UPCOMING">Dự kiến mở (UPCOMING)</option>
                <option value="CLOSED">Đã khóa sổ (CLOSED)</option>
              </select>
            </div>

            <div className="space-y-1">
              <label className="font-semibold text-slate-800">Tiết tối đa/ngày</label>
              <input
                type="number"
                min={1}
                max={12}
                value={formData.maxSlotPerDay}
                onChange={(e) => setFormData({ ...formData, maxSlotPerDay: Number(e.target.value) })}
                className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500"
              />
            </div>

            <div className="space-y-1">
              <label className="font-semibold text-slate-800">Thời lượng (phút/tiết)</label>
              <input
                type="number"
                min={30}
                max={90}
                value={formData.slotDuration}
                onChange={(e) => setFormData({ ...formData, slotDuration: Number(e.target.value) })}
                className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500"
              />
            </div>
          </div>

          {/* Mô tả */}
          <div className="space-y-1">
            <label className="font-semibold text-slate-800">Ghi chú điều hành</label>
            <textarea
              rows={2}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="VD: Học kỳ chính khóa mùa thu, triển khai điểm danh AI đợt 1..."
              className="w-full p-2.5 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500"
            />
          </div>

          {/* Footer Buttons */}
          <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
            <Button variant="outline" size="md" disabled={isSaving} onClick={() => setIsSemesterModalOpen(false)}>
              Hủy bỏ
            </Button>
            <Button variant="primary" size="md" isLoading={isSaving} onClick={() => handleSaveSemester()}>
              {modalMode === 'create' ? 'Tạo học kỳ' : 'Lưu thay đổi'}
            </Button>
          </div>
        </form>
      </Modal>

      {/* ======================================================== */}
      {/* 7. MODAL KHÓA SỔ HỌC KỲ (LOCK CONFIRMATION)              */}
      {/* ======================================================== */}
      <Modal
        isOpen={lockDialog.isOpen}
        onClose={() => setLockDialog((prev) => ({ ...prev, isOpen: false }))}
        title="Khóa sổ lưu trữ dữ liệu học kỳ"
        description="Bạn có chắc chắn muốn khóa sổ học kỳ này? Khi khóa sổ, toàn bộ điểm danh và dữ liệu chuyên cần sẽ được niêm phong bất biến."
        isDanger
        confirmText="Xác nhận khóa sổ"
        onConfirm={handleExecuteLock}
        isLoading={lockDialog.isLoading}
      >
        {lockDialog.semester && (
          <div className="p-4 rounded-lg bg-slate-50 border border-slate-200 space-y-1 font-mono">
            <div className="font-bold text-slate-900">{lockDialog.semester.name} ({lockDialog.semester.code})</div>
            <div className="text-xs text-slate-500">
              Thời gian: {formatDateVN(lockDialog.semester.startDate)} - {formatDateVN(lockDialog.semester.endDate)}
            </div>
          </div>
        )}
      </Modal>

      {/* ======================================================== */}
      {/* 8. MODAL XÓA HỌC KỲ                                      */}
      {/* ======================================================== */}
      <Modal
        isOpen={deleteDialog.isOpen}
        onClose={() => setDeleteDialog((prev) => ({ ...prev, isOpen: false }))}
        title="Xóa học kỳ khỏi hệ thống"
        description="Bạn có chắc chắn muốn xóa học kỳ này? Thao tác không thể hoàn tác nếu đã có lớp học phần phát sinh."
        isDanger
        confirmText="Xóa học kỳ"
        onConfirm={handleExecuteDelete}
        isLoading={deleteDialog.isLoading}
      >
        {deleteDialog.semester && (
          <div className="p-4 rounded-lg bg-slate-50 border border-slate-200 space-y-1 font-mono">
            <div className="font-bold text-slate-900">{deleteDialog.semester.name} ({deleteDialog.semester.code})</div>
          </div>
        )}
      </Modal>

      {/* ======================================================== */}
      {/* 9. TOAST NOTIFICATION                                    */}
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

export default SemesterManagementPage;
