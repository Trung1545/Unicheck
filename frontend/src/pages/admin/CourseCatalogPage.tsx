import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  BookOpen,
  Globe,
  GitFork,
  Award,
  FlaskConical,
  Upload,
  Download,
  PlusCircle,
  Search,
  RotateCcw,
  Eye,
  Edit,
  Trash2,
  CheckCircle,
  X,
  Link as LinkIcon,
  Radio,
  ChevronRight,
  Info,
  AlertTriangle,
  Layers,
} from 'lucide-react';
import {
  getCoursesApi,
  getCourseSummariesApi,
  getCourseByIdApi,
  checkCourseCodeApi,
  createCourseApi,
  updateCourseApi,
  deleteCourseApi,
} from '../../api/courses.api';
import {
  CourseResponse,
  CourseSummaryDto,
  CourseStatus,
  CourseCreateRequest,
  CourseUpdateRequest,
} from '../../types/api';
import { Button } from '../../common-ui/Button';
import { Badge } from '../../common-ui/Badge';
import { Modal } from '../../common-ui/Modal';
import { Pagination } from '../../common-ui/Pagination';
import { Skeleton } from '../../common-ui/Skeleton';
import { EmptyState } from '../../common-ui/EmptyState';

export const CourseCatalogPage: React.FC = () => {
  // ==========================================
  // STATE: Table Data & Pagination & Filtering
  // ==========================================
  const [courses, setCourses] = useState<CourseResponse[]>([]);
  const [courseSummaries, setCourseSummaries] = useState<CourseSummaryDto[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [page, setPage] = useState<number>(0);
  const [pageSize, setPageSize] = useState<number>(10);
  const [totalElements, setTotalElements] = useState<number>(0);
  const [totalPages, setTotalPages] = useState<number>(1);

  const [searchTerm, setSearchTerm] = useState<string>('');
  const [debouncedSearch, setDebouncedSearch] = useState<string>('');
  const [selectedCredits, setSelectedCredits] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<CourseStatus | 'all'>('all');

  // Debounce search
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(searchTerm);
      setPage(0);
    }, 400);
    return () => clearTimeout(handler);
  }, [searchTerm]);

  // Load Course Summaries for Prerequisite Dropdown
  const loadSummaries = useCallback(async () => {
    try {
      const res = await getCourseSummariesApi();
      if (res.success && res.data) {
        setCourseSummaries(res.data);
      }
    } catch (e) {
      console.error('Không thể tải danh sách tóm tắt học phần', e);
    }
  }, []);

  useEffect(() => {
    loadSummaries();
  }, [loadSummaries]);

  // Load Courses
  const loadCourses = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const creditsNum = selectedCredits !== 'all' ? Number(selectedCredits) : undefined;
      const res = await getCoursesApi({
        search: debouncedSearch || undefined,
        credits: creditsNum,
        status: selectedStatus !== 'all' ? selectedStatus : undefined,
        page,
        size: pageSize,
        sort: 'code,asc',
      });

      if (res.success && res.data) {
        setCourses(res.data.content || []);
        setTotalElements(res.data.totalElements || 0);
        setTotalPages(res.data.totalPages || 1);
      } else {
        setErrorMessage(res.message || 'Không thể tải danh mục học phần');
      }
    } catch (err: any) {
      setErrorMessage(err.message || 'Lỗi kết nối khi tải danh mục học phần');
    } finally {
      setIsLoading(false);
    }
  }, [debouncedSearch, selectedCredits, selectedStatus, page, pageSize]);

  useEffect(() => {
    loadCourses();
  }, [loadCourses]);

  const handleResetFilters = () => {
    setSearchTerm('');
    setDebouncedSearch('');
    setSelectedCredits('all');
    setSelectedStatus('all');
    setPage(0);
  };

  // ==========================================
  // METRIC SUMMARY CARDS CALCULATION
  // ==========================================
  const stats = useMemo(() => {
    const total = totalElements || courses.length;
    let labCourses = 0;
    let foundationCourses = 0;
    let majorCourses = 0;
    let generalCourses = 0;

    courses.forEach((c) => {
      if (c.numberOfSlots > 30) labCourses++;
      if (c.credits <= 2) generalCourses++;
      else if (c.credits === 3) foundationCourses++;
      else majorCourses++;
    });

    return {
      total,
      general: generalCourses,
      foundation: foundationCourses,
      major: majorCourses,
      lab: labCourses,
    };
  }, [totalElements, courses]);

  // ==========================================
  // STATE: Slide-Out Drawer (Create / Edit / View)
  // ==========================================
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false);
  const [drawerMode, setDrawerMode] = useState<'create' | 'edit' | 'view'>('create');
  const [selectedCourse, setSelectedCourse] = useState<CourseResponse | null>(null);

  const [formData, setFormData] = useState<{
    code: string;
    name: string;
    description: string;
    credits: number;
    numberOfSlots: number;
    status: CourseStatus;
    isCalculatedInGpa: boolean;
    prerequisiteIds: number[];
  }>({
    code: '',
    name: '',
    description: '',
    credits: 3,
    numberOfSlots: 45,
    status: 'ACTIVE',
    isCalculatedInGpa: true,
    prerequisiteIds: [],
  });

  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [isSaving, setIsSaving] = useState<boolean>(false);
  const [codeCheckStatus, setCodeCheckStatus] = useState<'idle' | 'checking' | 'available' | 'taken'>('idle');

  const handleOpenDrawer = (mode: 'create' | 'edit' | 'view', course?: CourseResponse) => {
    setDrawerMode(mode);
    setFormErrors({});
    setCodeCheckStatus('idle');

    if (course && (mode === 'edit' || mode === 'view')) {
      setSelectedCourse(course);
      setFormData({
        code: course.code,
        name: course.name,
        description: course.description || '',
        credits: course.credits,
        numberOfSlots: course.numberOfSlots,
        status: course.status,
        isCalculatedInGpa: course.isCalculatedInGpa,
        prerequisiteIds: course.prerequisites ? course.prerequisites.map((p) => p.id) : [],
      });
    } else {
      setSelectedCourse(null);
      setFormData({
        code: '',
        name: '',
        description: '',
        credits: 3,
        numberOfSlots: 45,
        status: 'ACTIVE',
        isCalculatedInGpa: true,
        prerequisiteIds: [],
      });
    }
    setIsDrawerOpen(true);
  };

  const handleCloseDrawer = () => {
    if (!isSaving) {
      setIsDrawerOpen(false);
      setSelectedCourse(null);
      setFormErrors({});
    }
  };

  // Check Code Availability
  const handleCheckCode = async () => {
    if (!formData.code.trim()) return;
    setCodeCheckStatus('checking');
    try {
      const res = await checkCourseCodeApi(formData.code.trim());
      if (res.data?.available) {
        setCodeCheckStatus('available');
      } else {
        setCodeCheckStatus('taken');
      }
    } catch {
      setCodeCheckStatus('idle');
    }
  };

  // Drawer Form Submit
  const handleSaveCourse = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (drawerMode === 'view') return;

    const errors: Record<string, string> = {};
    if (!formData.code.trim()) errors.code = 'Mã học phần là bắt buộc';
    if (!formData.name.trim()) errors.name = 'Tên học phần là bắt buộc';
    if (!formData.credits || formData.credits < 1) errors.credits = 'Số tín chỉ tối thiểu là 1';
    if (!formData.numberOfSlots || formData.numberOfSlots < 1) errors.numberOfSlots = 'Số tiết học tối thiểu là 1';

    if (Object.keys(errors).length > 0) {
      setFormErrors(errors);
      return;
    }

    setIsSaving(true);
    try {
      if (drawerMode === 'create') {
        const payload: CourseCreateRequest = {
          code: formData.code.trim().toUpperCase(),
          name: formData.name.trim(),
          description: formData.description.trim() || null,
          credits: formData.credits,
          numberOfSlots: formData.numberOfSlots,
          status: formData.status,
          isCalculatedInGpa: formData.isCalculatedInGpa,
          prerequisiteIds: formData.prerequisiteIds,
        };

        const res = await createCourseApi(payload);
        if (res.success) {
          showToast('Tạo mới học phần thành công', 'success');
          setIsDrawerOpen(false);
          loadCourses();
          loadSummaries();
        } else {
          showToast(res.message || 'Không thể tạo học phần', 'error');
        }
      } else if (drawerMode === 'edit' && selectedCourse) {
        const payload: CourseUpdateRequest = {
          name: formData.name.trim(),
          description: formData.description.trim() || null,
          credits: formData.credits,
          numberOfSlots: formData.numberOfSlots,
          status: formData.status,
          isCalculatedInGpa: formData.isCalculatedInGpa,
          prerequisiteIds: formData.prerequisiteIds,
        };

        const res = await updateCourseApi(selectedCourse.id, payload);
        if (res.success) {
          showToast('Cập nhật học phần thành công', 'success');
          setIsDrawerOpen(false);
          loadCourses();
          loadSummaries();
        } else {
          showToast(res.message || 'Không thể cập nhật học phần', 'error');
        }
      }
    } catch (err: any) {
      showToast(err.message || 'Đã xảy ra lỗi khi lưu học phần', 'error');
    } finally {
      setIsSaving(false);
    }
  };

  // ==========================================
  // STATE: Delete Confirmation Dialog
  // ==========================================
  const [deleteDialog, setDeleteDialog] = useState<{
    isOpen: boolean;
    course: CourseResponse | null;
    isLoading: boolean;
  }>({
    isOpen: false,
    course: null,
    isLoading: false,
  });

  const handleOpenDeleteDialog = (course: CourseResponse) => {
    setDeleteDialog({
      isOpen: true,
      course,
      isLoading: false,
    });
  };

  const handleExecuteDelete = async () => {
    if (!deleteDialog.course) return;
    setDeleteDialog((prev) => ({ ...prev, isLoading: true }));
    try {
      const res = await deleteCourseApi(deleteDialog.course.id);
      if (res.success) {
        showToast(`Đã xóa học phần ${deleteDialog.course.code} thành công`, 'success');
        setDeleteDialog({ isOpen: false, course: null, isLoading: false });
        loadCourses();
        loadSummaries();
      } else {
        showToast(res.message || 'Không thể xóa học phần', 'error');
      }
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi xóa học phần', 'error');
    } finally {
      setDeleteDialog((prev) => ({ ...prev, isLoading: false }));
    }
  };

  // Export CSV
  const handleExportCsv = () => {
    if (courses.length === 0) {
      showToast('Không có dữ liệu học phần để xuất', 'info');
      return;
    }
    const headers = ['Mã HP', 'Tên học phần', 'Số tín chỉ', 'Số tiết', 'Trạng thái', 'Tính vào GPA', 'Môn tiên quyết'];
    const rows = courses.map((c) => [
      `"${c.code}"`,
      `"${c.name}"`,
      c.credits,
      c.numberOfSlots,
      `"${c.status}"`,
      c.isCalculatedInGpa ? 'Có' : 'Không',
      `"${(c.prerequisites || []).map((p) => p.code).join('; ')}"`,
    ]);

    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `UniCheck_Courses_Export_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    showToast('Xuất danh mục học phần thành công', 'success');
  };

  // Toast Notification
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

  return (
    <div className="w-full min-h-screen bg-[#faf8ff] p-4 sm:p-6 lg:p-8 flex flex-col gap-6 text-[#131b2e]">
      {/* 1. Header & Breadcrumbs Context (Matching Stitch Screen a9f520acd00440c8a26633aec9a8799c) */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div className="flex flex-col gap-1">
          {/* Breadcrumb */}
          <div className="flex items-center gap-1.5 text-xs text-slate-500 font-medium">
            <span>Quản trị hệ thống</span>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
            <span>Đào tạo & Học vụ</span>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
            <span className="text-primary-700 font-semibold">Danh mục học phần</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-slate-900">
            Danh mục học phần & Chương trình đào tạo
          </h1>
          <p className="text-sm text-slate-500 max-w-3xl">
            Quản lý chuẩn hóa cấu trúc môn học, tiên quyết, tỷ lệ chuyên cần bắt buộc và cấu hình điểm danh tích hợp Kiosk AI toàn trường.
          </p>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2 sm:gap-3 shrink-0 flex-wrap">
          <Button
            variant="outline"
            size="md"
            leftIcon={<Upload className="w-4 h-4 text-slate-600" />}
            onClick={() => showToast('Chức năng nhập Excel học phần đang được xử lý trong đợt phát hành kế tiếp', 'info')}
          >
            Nhập danh mục (.xlsx)
          </Button>

          <Button
            variant="outline"
            size="md"
            leftIcon={<Download className="w-4 h-4 text-slate-600" />}
            onClick={handleExportCsv}
          >
            Xuất đề cương học phần
          </Button>

          <Button
            variant="primary"
            size="md"
            leftIcon={<PlusCircle className="w-4 h-4" />}
            onClick={() => handleOpenDrawer('create')}
            className="shadow-sm"
          >
            Thêm học phần mới
          </Button>
        </div>
      </div>

      {/* 2. Metric Summary Bento Grid (5 Cards) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        {/* Stat 1: Tổng số học phần */}
        <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm flex flex-col justify-between gap-3 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Tổng số học phần
            </span>
            <div className="w-9 h-9 rounded-lg bg-blue-50 text-blue-700 flex items-center justify-center">
              <BookOpen className="w-5 h-5" />
            </div>
          </div>
          <div>
            <div className="text-2xl lg:text-3xl font-bold tracking-tight text-slate-900 font-mono">
              {stats.total}{' '}
              <span className="text-xs font-normal text-slate-400">môn</span>
            </div>
            <div className="mt-1 flex items-center gap-1 text-xs font-semibold text-emerald-600">
              <CheckCircle className="w-3.5 h-3.5" />
              <span>100% Khung chuẩn MOET</span>
            </div>
          </div>
        </div>

        {/* Stat 2: Môn Đại cương */}
        <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm flex flex-col justify-between gap-3 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Môn Đại cương
            </span>
            <div className="w-9 h-9 rounded-lg bg-slate-100 text-slate-700 flex items-center justify-center">
              <Globe className="w-5 h-5" />
            </div>
          </div>
          <div>
            <div className="text-2xl lg:text-3xl font-bold tracking-tight text-slate-900 font-mono">
              {stats.general}{' '}
              <span className="text-xs font-normal text-slate-400">môn</span>
            </div>
            <div className="mt-1 text-xs text-slate-400">Toán, Lý, Triết học & Ngoại ngữ</div>
          </div>
        </div>

        {/* Stat 3: Cơ sở ngành */}
        <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm flex flex-col justify-between gap-3 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Cơ sở ngành
            </span>
            <div className="w-9 h-9 rounded-lg bg-emerald-50 text-emerald-700 flex items-center justify-center">
              <GitFork className="w-5 h-5" />
            </div>
          </div>
          <div>
            <div className="text-2xl lg:text-3xl font-bold tracking-tight text-slate-900 font-mono">
              {stats.foundation}{' '}
              <span className="text-xs font-normal text-slate-400">môn</span>
            </div>
            <div className="mt-1 text-xs text-slate-400">Kiến trúc MT, DSA, CSDL</div>
          </div>
        </div>

        {/* Stat 4: Chuyên ngành & Tự chọn */}
        <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm flex flex-col justify-between gap-3 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Chuyên ngành
            </span>
            <div className="w-9 h-9 rounded-lg bg-indigo-50 text-indigo-700 flex items-center justify-center">
              <Award className="w-5 h-5" />
            </div>
          </div>
          <div>
            <div className="text-2xl lg:text-3xl font-bold tracking-tight text-slate-900 font-mono">
              {stats.major}{' '}
              <span className="text-xs font-normal text-slate-400">môn</span>
            </div>
            <div className="mt-1 text-xs text-slate-400">AI, An toàn TT, KTPM, IoT</div>
          </div>
        </div>

        {/* Stat 5: Tích hợp Thực hành/Lab */}
        <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm flex flex-col justify-between gap-3 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Tích hợp Lab
            </span>
            <div className="w-9 h-9 rounded-lg bg-purple-50 text-purple-700 flex items-center justify-center">
              <FlaskConical className="w-5 h-5" />
            </div>
          </div>
          <div>
            <div className="text-2xl lg:text-3xl font-bold tracking-tight text-primary-700 font-mono">
              {stats.lab}{' '}
              <span className="text-xs font-normal text-slate-400">môn</span>
            </div>
            <div className="mt-1 flex items-center gap-1 text-xs font-semibold text-primary-700">
              <Radio className="w-3.5 h-3.5" />
              <span>Điểm danh QR / IP LAN</span>
            </div>
          </div>
        </div>
      </div>

      {/* 3. Search & Advanced Filter Section */}
      <div className="bg-white p-4 rounded-xl border border-slate-200/80 shadow-sm flex flex-col lg:flex-row gap-4 items-stretch lg:items-center justify-between">
        <div className="flex flex-1 flex-col sm:flex-row items-center gap-3">
          {/* Search Input */}
          <div className="relative w-full sm:max-w-md">
            <Search className="absolute left-3 top-2.5 w-4 h-4 text-slate-400 pointer-events-none" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Tìm theo mã môn (IT301, CS205...) hoặc tên học phần..."
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

          {/* Credits Selector */}
          <div className="relative w-full sm:w-44">
            <select
              value={selectedCredits}
              onChange={(e) => {
                setSelectedCredits(e.target.value);
                setPage(0);
              }}
              className="w-full h-10 px-3 pr-8 rounded-lg bg-slate-50 border border-slate-200/80 text-sm text-slate-900 outline-none cursor-pointer focus:bg-white focus:border-primary-500 transition-all appearance-none"
            >
              <option value="all">Số tín chỉ: Tất cả</option>
              <option value="2">2 Tín chỉ</option>
              <option value="3">3 Tín chỉ</option>
              <option value="4">4 Tín chỉ</option>
              <option value="5">5+ Tín chỉ</option>
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
              <option value="all">Trạng thái: Tất cả</option>
              <option value="ACTIVE">Đang giảng dạy (ACTIVE)</option>
              <option value="INACTIVE">Ngừng giảng dạy (INACTIVE)</option>
              <option value="DRAFT">Dự thảo (DRAFT)</option>
            </select>
            <div className="absolute right-3 top-3 pointer-events-none text-slate-400 text-xs">▼</div>
          </div>
        </div>

        {/* Right Actions / Reset */}
        <div className="flex items-center justify-end gap-3 shrink-0">
          <Button
            variant="ghost"
            size="md"
            leftIcon={<RotateCcw className="w-4 h-4 text-slate-500" />}
            onClick={handleResetFilters}
          >
            Đặt lại bộ lọc
          </Button>
          <div className="h-6 w-px bg-slate-200 hidden sm:block" />
          <span className="text-xs text-slate-500 font-medium">
            Hiển thị <strong className="text-slate-900 font-semibold">{courses.length}</strong> / {totalElements} học phần
          </span>
        </div>
      </div>

      {/* 4. Primary Course Catalog Table */}
      <div className="w-full bg-white rounded-xl border border-slate-200/90 shadow-sm overflow-hidden flex flex-col">
        <div className="w-full overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[840px]">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200/90 text-xs font-semibold uppercase tracking-wider text-slate-600 select-none">
                <th className="py-3.5 px-4 pl-6 w-28">Mã HP</th>
                <th className="py-3.5 px-4 min-w-[240px]">Tên môn học & Phân loại</th>
                <th className="py-3.5 px-4 w-32">Tín chỉ (LT/TH)</th>
                <th className="py-3.5 px-4 min-w-[180px]">Môn tiên quyết</th>
                <th className="py-3.5 px-4 min-w-[190px]">Chuyên cần & Cấm thi</th>
                <th className="py-3.5 px-4 w-32">Trạng thái</th>
                <th className="py-3.5 px-4 pr-6 text-right w-28">Thao tác</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, rIdx) => (
                  <tr key={`loading-row-${rIdx}`} className="animate-pulse">
                    <td className="py-4 px-4 pl-6">
                      <Skeleton variant="text" className="h-4 w-16" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-4 w-48 mb-1" />
                      <Skeleton variant="text" className="h-3 w-28" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-4 w-20" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-4 w-24" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-4 w-32" />
                    </td>
                    <td className="py-4 px-4">
                      <Skeleton variant="text" className="h-5 w-20 rounded-full" />
                    </td>
                    <td className="py-4 px-4 pr-6 text-right">
                      <Skeleton variant="text" className="h-7 w-20 ml-auto" />
                    </td>
                  </tr>
                ))
              ) : courses.length > 0 ? (
                courses.map((course) => (
                  <tr key={course.id} className="hover:bg-slate-50/80 transition-colors group">
                    {/* Mã HP */}
                    <td className="py-3.5 px-4 pl-6 align-middle font-mono font-bold text-primary-700">
                      {course.code}
                    </td>

                    {/* Tên môn học */}
                    <td className="py-3.5 px-4 align-middle">
                      <div className="flex flex-col">
                        <button
                          type="button"
                          onClick={() => handleOpenDrawer('view', course)}
                          className="font-semibold text-slate-900 hover:text-primary-700 transition-colors text-left"
                        >
                          {course.name}
                        </button>
                        <div className="flex items-center gap-2 mt-1">
                          <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-slate-100 text-slate-600">
                            {course.numberOfSlots > 30 ? 'Lý thuyết + Lab' : 'Lý thuyết'}
                          </span>
                          {course.isCalculatedInGpa && (
                            <span className="text-[11px] text-slate-400">Tính GPA</span>
                          )}
                        </div>
                      </div>
                    </td>

                    {/* Tín chỉ */}
                    <td className="py-3.5 px-4 align-middle font-mono">
                      <span className="font-semibold text-slate-900">{course.credits} TC</span>
                      <span className="text-slate-400 block text-xs">{course.numberOfSlots} tiết</span>
                    </td>

                    {/* Môn tiên quyết */}
                    <td className="py-3.5 px-4 align-middle">
                      {course.prerequisites && course.prerequisites.length > 0 ? (
                        <div className="flex flex-wrap gap-1">
                          {course.prerequisites.map((p) => (
                            <span
                              key={p.id}
                              className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-blue-50 text-primary-700 font-mono font-semibold text-xs border border-blue-200"
                              title={p.name}
                            >
                              <LinkIcon className="w-3 h-3" /> {p.code}
                            </span>
                          ))}
                        </div>
                      ) : (
                        <span className="text-xs text-slate-400 italic">Không có</span>
                      )}
                    </td>

                    {/* Chuyên cần & Cấm thi */}
                    <td className="py-3.5 px-4 align-middle">
                      <div className="flex flex-col gap-1 max-w-[180px]">
                        <div className="flex items-center justify-between text-xs">
                          <span className="text-slate-500">Trọng số: <strong>10%</strong></span>
                          <span className="text-red-600 font-semibold">Vắng &gt;20%</span>
                        </div>
                        <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
                          <div className="bg-red-500 h-full rounded-full" style={{ width: '20%' }} />
                        </div>
                      </div>
                    </td>

                    {/* Trạng thái */}
                    <td className="py-3.5 px-4 align-middle">
                      {course.status === 'ACTIVE' ? (
                        <Badge variant="active" size="md">
                          Đang mở
                        </Badge>
                      ) : course.status === 'INACTIVE' ? (
                        <Badge variant="inactive" size="md">
                          Ngừng mở
                        </Badge>
                      ) : (
                        <Badge variant="pending" size="md">
                          Dự thảo
                        </Badge>
                      )}
                    </td>

                    {/* Thao tác */}
                    <td className="py-3.5 px-4 pr-6 align-middle text-right">
                      <div className="flex items-center justify-end gap-1">
                        <button
                          type="button"
                          onClick={() => handleOpenDrawer('view', course)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-primary-700 hover:bg-slate-100 transition-colors"
                          title="Xem chi tiết"
                        >
                          <Eye className="w-4 h-4" />
                        </button>

                        <button
                          type="button"
                          onClick={() => handleOpenDrawer('edit', course)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-primary-700 hover:bg-slate-100 transition-colors"
                          title="Chỉnh sửa học phần"
                        >
                          <Edit className="w-4 h-4" />
                        </button>

                        <button
                          type="button"
                          onClick={() => handleOpenDeleteDialog(course)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                          title="Xóa học phần"
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
        {!isLoading && courses.length === 0 && (
          <div className="p-8">
            <EmptyState
              title="Không tìm thấy học phần nào"
              description="Hãy thử thay đổi từ khóa tìm kiếm hoặc làm mới bộ lọc số tín chỉ, trạng thái."
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
                <option value={20}>20</option>
                <option value={50}>50</option>
              </select>
              <span>dòng mỗi trang</span>
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
      {/* 5. SLIDE-OUT DRAWER (CREATE / EDIT / VIEW COURSE)        */}
      {/* ======================================================== */}
      {isDrawerOpen && (
        <div className="fixed inset-0 z-50 overflow-hidden">
          <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity" onClick={handleCloseDrawer} />
          <div className="fixed inset-y-0 right-0 max-w-full flex pl-10">
            <div className="w-screen max-w-xl bg-white shadow-2xl flex flex-col justify-between">
              {/* Header */}
              <div className="p-6 bg-slate-50 border-b border-slate-200 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-primary-700 text-white flex items-center justify-center shadow-sm">
                    {drawerMode === 'create' ? <PlusCircle className="w-5 h-5" /> : drawerMode === 'edit' ? <Edit className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </div>
                  <div>
                    <h3 className="text-lg font-bold text-slate-900">
                      {drawerMode === 'create' ? 'Thêm học phần mới' : drawerMode === 'edit' ? 'Chỉnh sửa học phần' : 'Thông tin chi tiết học phần'}
                    </h3>
                    <p className="text-xs text-slate-500">
                      {drawerMode === 'create' ? 'Thiết lập định danh, số tín chỉ và điều kiện tiên quyết' : 'Cập nhật cấu trúc học phần và đề cương'}
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

              {/* Form Body */}
              <form onSubmit={handleSaveCourse} className="flex-1 overflow-y-auto p-6 space-y-5 text-sm">
                {/* Mã HP & Tên môn */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div className="space-y-1.5 sm:col-span-1">
                    <label className="font-semibold text-slate-800 flex items-center justify-between">
                      <span>Mã HP <span className="text-red-500">*</span></span>
                      {drawerMode === 'create' && formData.code && (
                        <button type="button" onClick={handleCheckCode} className="text-[11px] text-primary-700 hover:underline font-semibold">
                          Kiểm tra
                        </button>
                      )}
                    </label>
                    <input
                      type="text"
                      disabled={drawerMode !== 'create'}
                      value={formData.code}
                      onChange={(e) => {
                        setFormData({ ...formData, code: e.target.value.toUpperCase().replace(/\s/g, '') });
                        setCodeCheckStatus('idle');
                      }}
                      placeholder="VD: CS2050"
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 font-mono font-semibold text-slate-900 outline-none focus:bg-white focus:border-primary-500 disabled:bg-slate-100"
                    />
                    {codeCheckStatus === 'available' && <span className="text-xs text-emerald-600 font-semibold">Mã khả dụng</span>}
                    {codeCheckStatus === 'taken' && <span className="text-xs text-red-500 font-semibold">Mã đã tồn tại</span>}
                    {formErrors.code && <span className="text-xs text-red-500">{formErrors.code}</span>}
                  </div>

                  <div className="space-y-1.5 sm:col-span-2">
                    <label className="font-semibold text-slate-800">Tên học phần <span className="text-red-500">*</span></label>
                    <input
                      type="text"
                      disabled={drawerMode === 'view'}
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      placeholder="VD: Cấu trúc Dữ liệu & Giải thuật"
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500 disabled:bg-slate-100"
                    />
                    {formErrors.name && <span className="text-xs text-red-500">{formErrors.name}</span>}
                  </div>
                </div>

                {/* Số tín chỉ & Số tiết & Trạng thái */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div className="space-y-1.5">
                    <label className="font-semibold text-slate-800">Số tín chỉ <span className="text-red-500">*</span></label>
                    <input
                      type="number"
                      min={1}
                      max={20}
                      disabled={drawerMode === 'view'}
                      value={formData.credits}
                      onChange={(e) => setFormData({ ...formData, credits: Number(e.target.value) })}
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500 disabled:bg-slate-100"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="font-semibold text-slate-800">Số tiết học <span className="text-red-500">*</span></label>
                    <input
                      type="number"
                      min={1}
                      disabled={drawerMode === 'view'}
                      value={formData.numberOfSlots}
                      onChange={(e) => setFormData({ ...formData, numberOfSlots: Number(e.target.value) })}
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500 disabled:bg-slate-100"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="font-semibold text-slate-800">Trạng thái</label>
                    <select
                      disabled={drawerMode === 'view'}
                      value={formData.status}
                      onChange={(e) => setFormData({ ...formData, status: e.target.value as CourseStatus })}
                      className="w-full h-10 px-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500 disabled:bg-slate-100"
                    >
                      <option value="ACTIVE">Đang mở (ACTIVE)</option>
                      <option value="INACTIVE">Ngừng mở (INACTIVE)</option>
                      <option value="DRAFT">Dự thảo (DRAFT)</option>
                    </select>
                  </div>
                </div>

                {/* Tính vào GPA */}
                <div className="pt-1">
                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      disabled={drawerMode === 'view'}
                      checked={formData.isCalculatedInGpa}
                      onChange={(e) => setFormData({ ...formData, isCalculatedInGpa: e.target.checked })}
                      className="w-4 h-4 rounded text-primary-700 accent-primary-700"
                    />
                    <span className="font-medium text-slate-800">Tính điểm tích lũy vào GPA học kỳ & toàn khóa</span>
                  </label>
                </div>

                {/* Môn tiên quyết Selection */}
                <div className="space-y-2">
                  <label className="font-semibold text-slate-800 flex items-center justify-between">
                    <span>Học phần tiên quyết (Prerequisites)</span>
                    <span className="text-xs text-slate-400 font-normal">Đã chọn: {formData.prerequisiteIds.length} môn</span>
                  </label>
                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-200/80 max-h-44 overflow-y-auto space-y-1.5">
                    {courseSummaries.filter((s) => selectedCourse ? s.id !== selectedCourse.id : true).map((s) => {
                      const isSelected = formData.prerequisiteIds.includes(s.id);
                      return (
                        <label
                          key={s.id}
                          className={`flex items-center justify-between p-2 rounded-lg cursor-pointer transition-colors ${isSelected ? 'bg-blue-50 border border-blue-200' : 'hover:bg-slate-100'}`}
                        >
                          <div className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              disabled={drawerMode === 'view'}
                              checked={isSelected}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setFormData({ ...formData, prerequisiteIds: [...formData.prerequisiteIds, s.id] });
                                } else {
                                  setFormData({ ...formData, prerequisiteIds: formData.prerequisiteIds.filter((id) => id !== s.id) });
                                }
                              }}
                              className="w-4 h-4 rounded text-primary-700 accent-primary-700"
                            />
                            <span className="font-mono font-bold text-xs text-primary-700">{s.code}</span>
                            <span className="text-xs text-slate-700">{s.name}</span>
                          </div>
                          <span className="text-[11px] text-slate-400 font-mono">{s.credits} TC</span>
                        </label>
                      );
                    })}
                  </div>
                </div>

                {/* Mô tả đề cương */}
                <div className="space-y-1.5">
                  <label className="font-semibold text-slate-800">Mô tả tóm tắt học phần</label>
                  <textarea
                    rows={3}
                    disabled={drawerMode === 'view'}
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    placeholder="Mục tiêu kiến thức, chuẩn đầu ra, phương pháp đánh giá chuyên cần..."
                    className="w-full p-3 rounded-lg border border-slate-200 bg-slate-50 text-slate-900 outline-none focus:bg-white focus:border-primary-500 disabled:bg-slate-100"
                  />
                </div>
              </form>

              {/* Footer */}
              <div className="p-4 sm:p-6 bg-slate-50 border-t border-slate-200 flex items-center justify-end gap-3">
                <Button variant="outline" size="md" onClick={handleCloseDrawer}>
                  {drawerMode === 'view' ? 'Đóng' : 'Hủy bỏ'}
                </Button>
                {drawerMode !== 'view' && (
                  <Button variant="primary" size="md" isLoading={isSaving} onClick={() => handleSaveCourse()}>
                    {drawerMode === 'create' ? 'Lưu học phần' : 'Cập nhật thay đổi'}
                  </Button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* 6. DELETE CONFIRMATION MODAL                             */}
      {/* ======================================================== */}
      <Modal
        isOpen={deleteDialog.isOpen}
        onClose={() => setDeleteDialog((prev) => ({ ...prev, isOpen: false }))}
        title="Xác nhận xóa học phần"
        description="Bạn có chắc chắn muốn xóa học phần này khỏi hệ thống? Thao tác này sẽ bị chặn nếu học phần đang là môn tiên quyết của học phần khác."
        isDanger
        confirmText="Xóa học phần"
        onConfirm={handleExecuteDelete}
        isLoading={deleteDialog.isLoading}
      >
        {deleteDialog.course && (
          <div className="p-4 rounded-lg bg-slate-50 border border-slate-200 space-y-1">
            <span className="text-xs uppercase font-semibold text-slate-400">Học phần chịu ảnh hưởng:</span>
            <div className="font-semibold text-slate-900 text-base font-mono">
              {deleteDialog.course.code} - {deleteDialog.course.name}
            </div>
            <div className="text-xs text-slate-500">
              Số tín chỉ: {deleteDialog.course.credits} TC · Số tiết: {deleteDialog.course.numberOfSlots}
            </div>
          </div>
        )}
      </Modal>

      {/* ======================================================== */}
      {/* 7. TOAST NOTIFICATION                                    */}
      {/* ======================================================== */}
      {toast.visible && (
        <div
          role="alert"
          className="fixed bottom-6 right-6 z-50 bg-slate-900 text-white px-5 py-3.5 rounded-xl shadow-2xl flex items-center gap-3 animate-in slide-in-from-bottom-5 duration-200 border border-slate-700"
        >
          {toast.type === 'success' ? (
            <CheckCircle className="w-5 h-5 text-emerald-400 shrink-0" />
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

export default CourseCatalogPage;
