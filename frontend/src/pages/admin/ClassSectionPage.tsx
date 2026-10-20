// ==============================================================================
// UniCheck - Class Section Management Page (F-14)
// Stitch Screen ID: 495a21f075ca479698f5f5075cee8a41
// Viewport: Desktop 1440px / 1280px | React Route: /admin/classes & /dashboard/classes
// ==============================================================================

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  BookOpen,
  Layers,
  Users,
  CheckCircle2,
  AlertTriangle,
  Upload,
  Download,
  PlusCircle,
  Search,
  RotateCcw,
  Eye,
  Edit,
  Trash2,
  X,
  ChevronRight,
  UserCheck,
  Calendar,
  Sparkles,
  ArrowRight,
  ShieldCheck,
  Check,
  AlertCircle,
  ExternalLink,
} from 'lucide-react';
import {
  getClassesApi,
  getClassStatsApi,
  createClassApi,
  updateClassApi,
  deleteClassApi,
  getClassStudentsApi,
  checkClassNameApi,
} from '../../api/classes.api';
import { getCourseSummariesApi } from '../../api/courses.api';
import { getSemestersApi } from '../../api/semesters.api';
import { getUsersApi } from '../../api/users.api';
import {
  ClassSectionResponse,
  ClassSectionStatsResponse,
  ClassSectionStatus,
  ClassSectionCreateRequest,
  ClassSectionUpdateRequest,
  CourseSummaryDto,
  SemesterResponse,
  UserResponse,
  EnrollmentResponse,
} from '../../types/api';
import { Button } from '../../common-ui/Button';
import { Badge } from '../../common-ui/Badge';
import { Modal } from '../../common-ui/Modal';
import { Pagination } from '../../common-ui/Pagination';
import { Skeleton } from '../../common-ui/Skeleton';
import { EmptyState } from '../../common-ui/EmptyState';

export const ClassSectionPage: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  // ==========================================
  // STATE: Table Data & Pagination & Filtering
  // ==========================================
  const [classes, setClasses] = useState<ClassSectionResponse[]>([]);
  const [stats, setStats] = useState<ClassSectionStatsResponse | null>(null);
  const [courses, setCourses] = useState<CourseSummaryDto[]>([]);
  const [semesters, setSemesters] = useState<SemesterResponse[]>([]);
  const [lecturers, setLecturers] = useState<UserResponse[]>([]);

  const [isLookupsLoading, setIsLookupsLoading] = useState<boolean>(false);
  const [lookupsError, setLookupsError] = useState<string | null>(null);

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successToast, setSuccessToast] = useState<string | null>(null);

  const [page, setPage] = useState<number>(0);
  const [pageSize, setPageSize] = useState<number>(10);
  const [totalElements, setTotalElements] = useState<number>(0);
  const [totalPages, setTotalPages] = useState<number>(1);

  const [searchTerm, setSearchTerm] = useState<string>('');
  const [debouncedSearch, setDebouncedSearch] = useState<string>('');
  const [selectedSemester, setSelectedSemester] = useState<string>('all');
  const [selectedCourse, setSelectedCourse] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<ClassSectionStatus | 'all'>('all');

  // Drawer detail state
  const [selectedClassForDrawer, setSelectedClassForDrawer] = useState<ClassSectionResponse | null>(null);
  const [drawerTab, setDrawerTab] = useState<'roster' | 'sessions'>('roster');
  const [rosterStudents, setRosterStudents] = useState<EnrollmentResponse[]>([]);
  const [isRosterLoading, setIsRosterLoading] = useState<boolean>(false);

  // Modals state
  const [isCreateModalOpen, setIsCreateModalOpen] = useState<boolean>(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState<boolean>(false);
  const [classToEdit, setClassToEdit] = useState<ClassSectionResponse | null>(null);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState<boolean>(false);
  const [classToDelete, setClassToDelete] = useState<ClassSectionResponse | null>(null);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [formError, setFormError] = useState<string | null>(null);

  // Create Form State
  const [createForm, setCreateForm] = useState({
    courseId: '',
    semesterId: '',
    lecturerId: '',
    className: '',
    maxStudents: 70,
    numberOfSlots: 45,
    status: 'OPEN' as ClassSectionStatus,
  });

  // Edit Form State
  const [editForm, setEditForm] = useState({
    lecturerId: '',
    maxStudents: 70,
    numberOfSlots: 45,
    status: 'OPEN' as ClassSectionStatus,
  });

  // Debounce search input
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(searchTerm);
      setPage(0);
    }, 400);
    return () => clearTimeout(handler);
  }, [searchTerm]);

  // Load lookup metadata (courses, semesters, lecturers)
  const loadLookups = useCallback(async () => {
    setIsLookupsLoading(true);
    setLookupsError(null);
    try {
      const [coursesRes, semestersRes, lecturersRes] = await Promise.all([
        getCourseSummariesApi(),
        getSemestersApi({ size: 100 }),
        getUsersApi({ role: 'LECTURER', status: 'ACTIVE', size: 100 }),
      ]);

      if (coursesRes.success && coursesRes.data) {
        const cList = Array.isArray(coursesRes.data)
          ? coursesRes.data
          : (coursesRes.data as any).content || [];
        setCourses(cList);
      }
      if (semestersRes.success && semestersRes.data) {
        const sList = Array.isArray(semestersRes.data)
          ? semestersRes.data
          : (semestersRes.data as any).content || [];
        setSemesters(sList);
      }
      if (lecturersRes.success && lecturersRes.data) {
        const lList = Array.isArray(lecturersRes.data)
          ? lecturersRes.data
          : (lecturersRes.data as any).content || [];
        setLecturers(lList);
      }
    } catch (e: any) {
      console.error('Không thể nạp dữ liệu danh mục', e);
      setLookupsError(e?.message || 'Không thể tải dữ liệu danh mục (Môn học / Học kỳ / Giảng viên)');
    } finally {
      setIsLookupsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadLookups();
  }, [loadLookups]);

  // Load stats
  const loadStats = useCallback(async () => {
    try {
      const semId = selectedSemester !== 'all' ? Number(selectedSemester) : undefined;
      const res = await getClassStatsApi(semId);
      if (res.success && res.data) {
        setStats(res.data);
      }
    } catch (e) {
      console.error('Không thể nạp thống kê lớp học phần', e);
    }
  }, [selectedSemester]);

  // Load Classes
  const loadClasses = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const semId = selectedSemester !== 'all' ? Number(selectedSemester) : undefined;
      const cId = selectedCourse !== 'all' ? Number(selectedCourse) : undefined;
      const statusParam = selectedStatus !== 'all' ? selectedStatus : undefined;

      const res = await getClassesApi({
        search: debouncedSearch || undefined,
        semesterId: semId,
        courseId: cId,
        status: statusParam,
        page,
        size: pageSize,
        sort: 'className,asc',
      });

      if (res.success && res.data) {
        setClasses(res.data.content);
        setTotalElements(res.data.totalElements);
        setTotalPages(res.data.totalPages || 1);
      }
    } catch (err: any) {
      setErrorMessage(err.message || 'Lỗi khi tải danh sách lớp học phần');
    } finally {
      setIsLoading(false);
    }
  }, [debouncedSearch, selectedSemester, selectedCourse, selectedStatus, page, pageSize]);

  useEffect(() => {
    loadClasses();
    loadStats();
  }, [loadClasses, loadStats]);

  // Load Roster for Drawer
  const openClassDrawer = async (cs: ClassSectionResponse) => {
    setSelectedClassForDrawer(cs);
    setDrawerTab('roster');
    setIsRosterLoading(true);
    try {
      const res = await getClassStudentsApi(cs.className);
      if (res.success && res.data) {
        setRosterStudents(res.data);
      } else {
        setRosterStudents([]);
      }
    } catch (e) {
      setRosterStudents([]);
    } finally {
      setIsRosterLoading(false);
    }
  };

  const closeClassDrawer = () => {
    setSelectedClassForDrawer(null);
    setRosterStudents([]);
  };

  // Toast auto dismiss
  useEffect(() => {
    if (successToast) {
      const timer = setTimeout(() => setSuccessToast(null), 4000);
      return () => clearTimeout(timer);
    }
  }, [successToast]);

  // Handle Create Class
  const handleOpenCreateModal = async () => {
    setFormError(null);
    setIsCreateModalOpen(true);
    // Freshly re-fetch lookups to ensure latest courses & semesters are available
    await loadLookups();
  };

  // Auto-sync form default when lookups finish or modal opens
  useEffect(() => {
    if (isCreateModalOpen) {
      const activeSem = semesters.find((s) => s.status === 'ACTIVE') || semesters[0];
      setCreateForm((prev) => {
        const nextCourseId = prev.courseId || (courses.length > 0 ? String(courses[0].id) : '');
        const nextSemId = prev.semesterId || (activeSem ? String(activeSem.id) : '');
        let nextClassName = prev.className;
        if (!nextClassName && courses.length > 0) {
          const selectedC = courses.find((c) => String(c.id) === nextCourseId) || courses[0];
          nextClassName = `${selectedC.code}.01`;
        }
        return {
          ...prev,
          courseId: nextCourseId,
          semesterId: nextSemId,
          className: nextClassName,
        };
      });
    }
  }, [isCreateModalOpen, courses, semesters]);

  // Auto-generate suggested className when course changes
  const handleCourseChangeInCreate = (courseId: string) => {
    const selected = courses.find((c) => String(c.id) === courseId);
    let suggestedName = '';
    if (selected) {
      suggestedName = `${selected.code}.01`;
    }
    setCreateForm((prev) => ({
      ...prev,
      courseId,
      className: suggestedName,
    }));
  };

  const handleCreateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (!createForm.courseId) {
      setFormError('Vui lòng chọn môn học từ catalog');
      return;
    }
    if (!createForm.semesterId) {
      setFormError('Vui lòng chọn học kỳ');
      return;
    }
    if (!createForm.className.trim()) {
      setFormError('Vui lòng nhập mã lớp học phần (ví dụ: IT301.01)');
      return;
    }

    setIsSubmitting(true);
    try {
      const req: ClassSectionCreateRequest = {
        className: createForm.className.trim().toUpperCase(),
        courseId: Number(createForm.courseId),
        semesterId: Number(createForm.semesterId),
        lecturerId: createForm.lecturerId ? Number(createForm.lecturerId) : null,
        maxStudents: Number(createForm.maxStudents) || 70,
        numberOfSlots: Number(createForm.numberOfSlots) || 45,
        status: createForm.status,
      };

      const res = await createClassApi(req);
      if (res.success) {
        setSuccessToast(`Đã mở thành công lớp học phần ${res.data.className}`);
        setIsCreateModalOpen(false);
        loadClasses();
        loadStats();
      }
    } catch (err: any) {
      setFormError(err.message || 'Không thể tạo mới lớp học phần');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle Edit Class
  const handleOpenEditModal = (cs: ClassSectionResponse) => {
    setClassToEdit(cs);
    setFormError(null);
    setEditForm({
      lecturerId: cs.lecturerId ? String(cs.lecturerId) : '',
      maxStudents: cs.maxStudents,
      numberOfSlots: cs.numberOfSlots,
      status: cs.status,
    });
    setIsEditModalOpen(true);
  };

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!classToEdit) return;
    setFormError(null);

    if (editForm.maxStudents < classToEdit.currentEnrollment) {
      setFormError(`Sĩ số tối đa không thể nhỏ hơn số sinh viên đã ghi danh (${classToEdit.currentEnrollment} SV)`);
      return;
    }

    setIsSubmitting(true);
    try {
      const req: ClassSectionUpdateRequest = {
        lecturerId: editForm.lecturerId ? Number(editForm.lecturerId) : null,
        maxStudents: Number(editForm.maxStudents),
        numberOfSlots: Number(editForm.numberOfSlots),
        status: editForm.status,
      };

      const res = await updateClassApi(classToEdit.className, req);
      if (res.success) {
        setSuccessToast(`Cập nhật thông tin lớp ${classToEdit.className} thành công`);
        setIsEditModalOpen(false);
        loadClasses();
        loadStats();
      }
    } catch (err: any) {
      setFormError(err.message || 'Không thể cập nhật lớp học phần');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle Delete Class
  const handleOpenDeleteModal = (cs: ClassSectionResponse) => {
    setClassToDelete(cs);
    setFormError(null);
    setIsDeleteModalOpen(true);
  };

  const handleDeleteConfirm = async () => {
    if (!classToDelete) return;
    setIsSubmitting(true);
    setFormError(null);
    try {
      const res = await deleteClassApi(classToDelete.className);
      if (res.success) {
        setSuccessToast(`Đã xóa thành công lớp ${classToDelete.className}`);
        setIsDeleteModalOpen(false);
        loadClasses();
        loadStats();
      }
    } catch (err: any) {
      setFormError(err.message || 'Không thể xóa lớp học phần');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Active semester display label
  const activeSemesterLabel = useMemo(() => {
    const act = semesters.find((s) => s.status === 'ACTIVE');
    return act ? act.name : 'HK I (2024-2025)';
  }, [semesters]);

  return (
    <div className="w-full flex flex-col gap-6 p-4 sm:p-6 lg:p-8 max-w-[1440px] mx-auto animate-in fade-in duration-200">
      {/* Toast Alert */}
      {successToast && (
        <div className="fixed top-20 right-6 z-50 flex items-center gap-3 bg-secondary text-white px-5 py-3 rounded-xl shadow-lg animate-in slide-in-from-top-4">
          <CheckCircle2 className="w-5 h-5" />
          <span className="font-semibold text-sm">{successToast}</span>
          <button onClick={() => setSuccessToast(null)} className="ml-2 hover:opacity-80">
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Breadcrumb & Top Command Bar */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex flex-col gap-1">
          <div className="flex items-center gap-1.5 text-xs text-on-surface-variant font-medium">
            <span>Quản trị hệ thống</span>
            <ChevronRight className="w-3.5 h-3.5 text-outline-variant" />
            <span>Đào tạo &amp; Học vụ</span>
            <ChevronRight className="w-3.5 h-3.5 text-outline-variant" />
            <span className="text-primary font-semibold">Lớp học phần</span>
          </div>
          <div className="flex items-center gap-3 flex-wrap">
            <h1 className="text-2xl sm:text-3xl font-bold text-on-surface tracking-tight">
              Quản lý Lớp học phần &amp; Kế hoạch giảng dạy
            </h1>
            <span className="px-3 py-1 rounded-full bg-surface-container text-primary text-xs font-semibold">
              {activeSemesterLabel}
            </span>
          </div>
        </div>

        {/* Quick Action Buttons */}
        <div className="flex items-center gap-2.5 flex-wrap">
          <Button
            variant="outline"
            className="flex items-center gap-1.5 h-10 shadow-sm"
            onClick={() => setSuccessToast('Tính năng nhập file (.xlsx) đã sẵn sàng qua phân hệ Ghi danh')}
          >
            <Upload className="w-4 h-4 text-secondary" />
            <span>Nhập file (.xlsx)</span>
          </Button>
          <Button
            variant="outline"
            className="flex items-center gap-1.5 h-10 shadow-sm"
            onClick={() => setSuccessToast('Đang tạo và tải xuống bản báo cáo kế hoạch đào tạo')}
          >
            <Download className="w-4 h-4" />
            <span>Xuất kế hoạch</span>
          </Button>
          <Button
            variant="primary"
            className="flex items-center gap-1.5 h-10 shadow-md bg-primary hover:bg-primary-container text-white"
            onClick={handleOpenCreateModal}
          >
            <PlusCircle className="w-4 h-4" />
            <span>Thêm lớp học phần mới</span>
          </Button>
        </div>
      </div>

      {/* Key Metrics Bento Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
        {/* Stat 1 */}
        <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-surface-container flex flex-col justify-between relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-on-surface-variant">Tổng số lớp mở</span>
            <div className="w-10 h-10 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
              <BookOpen className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4 flex items-baseline gap-2">
            <span className="text-3xl font-bold text-on-surface tracking-tight">
              {stats ? stats.totalClasses : totalElements}
            </span>
            <span className="text-xs text-on-surface-variant font-medium">lớp trong kỳ</span>
          </div>
          <div className="mt-2 flex items-center gap-1 text-xs text-secondary font-medium">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Đồng bộ thời khóa biểu trực tuyến</span>
          </div>
        </div>

        {/* Stat 2 */}
        <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-surface-container flex flex-col justify-between relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-on-surface-variant">Đang mở / Giảng dạy</span>
            <div className="w-10 h-10 rounded-lg bg-secondary/10 text-secondary flex items-center justify-center">
              <CheckCircle2 className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4 flex items-baseline gap-2">
            <span className="text-3xl font-bold text-secondary tracking-tight">
              {stats ? stats.activeClasses : classes.filter((c) => c.status === 'OPEN' || c.status === 'ACTIVE').length}
            </span>
            <span className="text-xs text-on-surface-variant font-medium">lớp active</span>
          </div>
          <div className="mt-2 flex items-center gap-1.5 text-xs text-secondary font-semibold">
            <span className="w-2 h-2 rounded-full bg-secondary animate-pulse"></span>
            <span>AI Kiosk &amp; WiFi AP đồng bộ</span>
          </div>
        </div>

        {/* Stat 3 */}
        <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-surface-container flex flex-col justify-between relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-on-surface-variant">Lớp đủ sĩ số (&gt;80%)</span>
            <div className="w-10 h-10 rounded-lg bg-surface-container text-primary flex items-center justify-center">
              <ShieldCheck className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4 flex items-baseline gap-2">
            <span className="text-3xl font-bold text-on-surface tracking-tight">
              {stats ? stats.fullCapacityClasses : classes.filter((c) => c.currentEnrollment / c.maxStudents >= 0.8).length}
            </span>
            <span className="text-xs text-on-surface-variant font-medium">đạt chỉ tiêu</span>
          </div>
          <div className="mt-2 flex items-center gap-1 text-xs text-primary font-medium">
            <Check className="w-3.5 h-3.5" />
            <span>Kế hoạch phòng học ổn định</span>
          </div>
        </div>

        {/* Stat 4 */}
        <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-surface-container flex flex-col justify-between relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-error">Dưới sĩ số tối thiểu</span>
            <div className="w-10 h-10 rounded-lg bg-error-container text-error flex items-center justify-center">
              <AlertTriangle className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4 flex items-baseline gap-2">
            <span className="text-3xl font-bold text-error tracking-tight">
              {stats ? stats.underCapacityClasses : classes.filter((c) => c.currentEnrollment < 15).length}
            </span>
            <span className="text-xs text-on-surface-variant font-medium">lớp &lt; 15 SV</span>
          </div>
          <div className="mt-2 flex items-center justify-between text-xs">
            <span className="text-error font-semibold">Cần duyệt hủy / gộp</span>
            <button
              onClick={() => {
                setSelectedStatus('OPEN');
              }}
              className="text-error underline hover:text-on-error-container font-medium"
            >
              Lọc ngay
            </button>
          </div>
        </div>
      </div>

      {/* Filter & Omni Search Ribbon */}
      <div className="bg-surface-container-lowest p-4 sm:p-5 rounded-xl shadow-sm border border-surface-container flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div className="flex flex-1 items-center gap-3 flex-wrap">
          {/* Search Input */}
          <div className="relative min-w-[240px] flex-1 max-w-md">
            <Search className="w-4 h-4 absolute left-3 top-3 text-outline" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Tìm kiếm mã lớp (IT301.01), tên học phần, giảng viên..."
              className="w-full h-10 pl-9 pr-4 rounded-lg bg-surface-container-low text-on-surface text-sm placeholder:text-outline outline-none focus:bg-surface-container-lowest focus:ring-2 ring-primary/20 transition-all border border-transparent focus:border-primary/30"
            />
          </div>

          {/* Semester Filter */}
          <div className="flex items-center gap-1.5 bg-surface-container-low px-3 py-1.5 rounded-lg text-sm border border-surface-container">
            <span className="text-on-surface-variant text-xs font-semibold">Học kỳ:</span>
            <select
              value={selectedSemester}
              onChange={(e) => {
                setSelectedSemester(e.target.value);
                setPage(0);
              }}
              className="bg-transparent text-on-surface font-semibold outline-none cursor-pointer text-xs"
            >
              <option value="all">Tất cả học kỳ</option>
              {semesters.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>
          </div>

          {/* Course Filter */}
          <div className="flex items-center gap-1.5 bg-surface-container-low px-3 py-1.5 rounded-lg text-sm border border-surface-container">
            <span className="text-on-surface-variant text-xs font-semibold">Học phần:</span>
            <select
              value={selectedCourse}
              onChange={(e) => {
                setSelectedCourse(e.target.value);
                setPage(0);
              }}
              className="bg-transparent text-on-surface font-semibold outline-none cursor-pointer text-xs max-w-[180px] truncate"
            >
              <option value="all">Tất cả môn học</option>
              {courses.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.code} - {c.name}
                </option>
              ))}
            </select>
          </div>

          {/* Status Filter */}
          <div className="flex items-center gap-1.5 bg-surface-container-low px-3 py-1.5 rounded-lg text-sm border border-surface-container">
            <span className="text-on-surface-variant text-xs font-semibold">Trạng thái:</span>
            <select
              value={selectedStatus}
              onChange={(e) => {
                setSelectedStatus(e.target.value as ClassSectionStatus | 'all');
                setPage(0);
              }}
              className="bg-transparent text-on-surface font-semibold outline-none cursor-pointer text-xs"
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="OPEN">Mở đăng ký (OPEN)</option>
              <option value="ACTIVE">Đang giảng dạy (ACTIVE)</option>
              <option value="CLOSED">Đã khóa (CLOSED)</option>
              <option value="CANCELLED">Tạm hủy (CANCELLED)</option>
            </select>
          </div>
        </div>

        {/* Refresh & Pagination info */}
        <div className="flex items-center gap-2.5 justify-end shrink-0">
          <span className="text-xs text-on-surface-variant">
            Hiển thị <span className="font-semibold text-on-surface">{classes.length}</span> / {totalElements} lớp
          </span>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              loadClasses();
              loadStats();
            }}
            className="w-9 h-9 p-0"
            title="Tải lại danh sách"
          >
            <RotateCcw className="w-4 h-4 text-on-surface-variant" />
          </Button>
        </div>
      </div>

      {/* Master Data Table Container */}
      <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-surface-container overflow-hidden flex flex-col">
        {errorMessage && (
          <div className="p-4 bg-error-container/30 border-b border-error/20 flex items-center gap-2 text-error text-sm">
            <AlertCircle className="w-4 h-4" />
            <span>{errorMessage}</span>
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low text-on-surface-variant text-xs font-semibold uppercase tracking-wider border-b border-surface-container">
                <th className="py-3.5 px-4 w-12 text-center">STT</th>
                <th className="py-3.5 px-4">Mã Lớp HP</th>
                <th className="py-3.5 px-4">Môn học &amp; Tín chỉ</th>
                <th className="py-3.5 px-4">Giảng viên phụ trách</th>
                <th className="py-3.5 px-4">Số tiết học</th>
                <th className="py-3.5 px-4 min-w-[180px]">Sĩ số đăng ký</th>
                <th className="py-3.5 px-4">Trạng thái</th>
                <th className="py-3.5 px-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-container text-sm text-on-surface">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}>
                    <td colSpan={8} className="py-4 px-4">
                      <Skeleton className="h-6 w-full rounded" />
                    </td>
                  </tr>
                ))
              ) : classes.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center">
                    <EmptyState
                      title="Không tìm thấy lớp học phần nào"
                      description="Chưa có dữ liệu lớp học phần khớp với bộ lọc tìm kiếm hiện tại."
                      actionText="Thêm lớp học phần mới"
                      onAction={handleOpenCreateModal}
                    />
                  </td>
                </tr>
              ) : (
                classes.map((cs, idx) => {
                  const percent = cs.maxStudents > 0 ? Math.min(100, Math.round((cs.currentEnrollment / cs.maxStudents) * 100)) : 0;
                  return (
                    <tr key={cs.className} className="hover:bg-surface-container-low/60 transition-colors group">
                      <td className="py-3.5 px-4 text-center text-xs text-on-surface-variant font-medium">
                        {page * pageSize + idx + 1}
                      </td>
                      <td className="py-3.5 px-4 font-bold text-primary">
                        <div className="flex items-center gap-1.5">
                          <span>{cs.className}</span>
                          {cs.status === 'ACTIVE' && (
                            <span className="w-2 h-2 rounded-full bg-secondary animate-pulse" title="Đang trong kỳ học" />
                          )}
                        </div>
                      </td>
                      <td className="py-3.5 px-4">
                        <div className="flex flex-col">
                          <span className="font-semibold text-on-surface">{cs.courseName}</span>
                          <span className="text-xs text-on-surface-variant">
                            {cs.courseCode} · {cs.credits} Tín chỉ
                          </span>
                        </div>
                      </td>
                      <td className="py-3.5 px-4">
                        {cs.lecturerName ? (
                          <div className="flex items-center gap-2">
                            <div className="w-7 h-7 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-xs">
                              {cs.lecturerName.charAt(0)}
                            </div>
                            <div className="flex flex-col">
                              <span className="font-medium text-xs text-on-surface">{cs.lecturerName}</span>
                              <span className="text-[11px] text-on-surface-variant">{cs.lecturerCode || cs.lecturerEmail}</span>
                            </div>
                          </div>
                        ) : (
                          <span className="text-xs text-outline italic">Chưa phân công</span>
                        )}
                      </td>
                      <td className="py-3.5 px-4 text-xs font-semibold text-on-surface">
                        {cs.numberOfSlots} tiết
                      </td>
                      <td className="py-3.5 px-4">
                        <div className="flex flex-col gap-1.5">
                          <div className="flex items-center justify-between text-xs">
                            <span className="font-bold text-on-surface">
                              {cs.currentEnrollment} <span className="font-normal text-outline">/ {cs.maxStudents} SV</span>
                            </span>
                            <span className={`font-semibold ${percent >= 80 ? 'text-secondary' : 'text-primary'}`}>
                              {percent}%
                            </span>
                          </div>
                          <div className="w-full bg-surface-container h-1.5 rounded-full overflow-hidden">
                            <div
                              className={`h-full rounded-full ${percent >= 100 ? 'bg-error' : percent >= 80 ? 'bg-secondary' : 'bg-primary'}`}
                              style={{ width: `${percent}%` }}
                            />
                          </div>
                        </div>
                      </td>
                      <td className="py-3.5 px-4">
                        {cs.status === 'OPEN' && <Badge variant="primary">Mở đăng ký</Badge>}
                        {cs.status === 'ACTIVE' && <Badge variant="active">Đang giảng dạy</Badge>}
                        {cs.status === 'CLOSED' && <Badge variant="neutral">Đã đóng</Badge>}
                        {cs.status === 'CANCELLED' && <Badge variant="blocked">Tạm hủy</Badge>}
                      </td>
                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end gap-1">
                          <button
                            onClick={() => openClassDrawer(cs)}
                            className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-surface-container text-on-surface-variant transition-colors"
                            title="Xem chi tiết & danh sách sinh viên"
                          >
                            <Eye className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => navigate(`/admin/enrollments?className=${cs.className}`)}
                            className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-surface-container text-secondary transition-colors"
                            title="Quản lý ghi danh sinh viên cho lớp này"
                          >
                            <Users className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleOpenEditModal(cs)}
                            className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-surface-container text-primary transition-colors"
                            title="Chỉnh sửa lớp học phần"
                          >
                            <Edit className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleOpenDeleteModal(cs)}
                            className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-error-container text-error transition-colors"
                            title="Xóa lớp học phần"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination footer */}
        <div className="p-4 border-t border-surface-container flex flex-col sm:flex-row items-center justify-between gap-3">
          <span className="text-xs text-on-surface-variant">
            Trang {page + 1} trên {totalPages} ({totalElements} bản ghi)
          </span>
          <Pagination
            currentPage={page + 1}
            totalPages={totalPages}
            onPageChange={(newPage) => setPage(newPage - 1)}
          />
        </div>
      </div>

      {/* Drawer: Class Detail & Roster */}
      {selectedClassForDrawer && (
        <div className="fixed inset-0 z-50 flex justify-end bg-on-surface/30 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="w-full max-w-xl bg-surface-container-lowest h-full shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-right duration-200">
            {/* Drawer Header */}
            <div className="p-5 border-b border-surface-container bg-surface-container-low flex items-start justify-between">
              <div className="flex flex-col gap-1">
                <div className="flex items-center gap-2">
                  <span className="px-2.5 py-0.5 rounded bg-primary text-white font-bold text-xs">
                    {selectedClassForDrawer.className}
                  </span>
                  <Badge variant={selectedClassForDrawer.status === 'ACTIVE' ? 'active' : 'primary'}>
                    {selectedClassForDrawer.status}
                  </Badge>
                </div>
                <h2 className="text-lg font-bold text-on-surface">
                  {selectedClassForDrawer.courseName}
                </h2>
                <div className="flex items-center gap-4 text-xs text-on-surface-variant flex-wrap mt-1">
                  <span className="flex items-center gap-1">
                    <UserCheck className="w-3.5 h-3.5" />
                    <span>{selectedClassForDrawer.lecturerName || 'Chưa phân công'}</span>
                  </span>
                  <span className="flex items-center gap-1">
                    <Users className="w-3.5 h-3.5" />
                    <span>Sĩ số: {selectedClassForDrawer.currentEnrollment}/{selectedClassForDrawer.maxStudents}</span>
                  </span>
                  <span className="flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5" />
                    <span>{selectedClassForDrawer.semesterName}</span>
                  </span>
                </div>
              </div>
              <button
                onClick={closeClassDrawer}
                className="w-8 h-8 rounded-full hover:bg-surface-container flex items-center justify-center text-on-surface-variant"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Drawer Tabs */}
            <div className="flex border-b border-surface-container px-5 bg-surface-container-lowest">
              <button
                onClick={() => setDrawerTab('roster')}
                className={`py-3 text-sm font-semibold border-b-2 flex items-center gap-2 transition-all ${
                  drawerTab === 'roster'
                    ? 'border-primary text-primary'
                    : 'border-transparent text-on-surface-variant hover:text-on-surface'
                }`}
              >
                <Users className="w-4 h-4" />
                <span>Danh sách sinh viên ({selectedClassForDrawer.currentEnrollment})</span>
              </button>
              <button
                onClick={() => setDrawerTab('sessions')}
                className={`py-3 px-4 text-sm font-semibold border-b-2 flex items-center gap-2 transition-all ${
                  drawerTab === 'sessions'
                    ? 'border-primary text-primary'
                    : 'border-transparent text-on-surface-variant hover:text-on-surface'
                }`}
              >
                <Layers className="w-4 h-4" />
                <span>Thông tin &amp; Kế hoạch</span>
              </button>
            </div>

            {/* Drawer Content */}
            <div className="flex-1 overflow-y-auto p-5">
              {drawerTab === 'roster' && (
                <div className="flex flex-col gap-4">
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-on-surface-variant font-medium">
                      Danh sách đã ghi danh chính thức
                    </span>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => {
                        navigate(`/admin/enrollments?className=${selectedClassForDrawer.className}`);
                      }}
                      className="text-xs flex items-center gap-1 h-8"
                    >
                      <ExternalLink className="w-3.5 h-3.5" />
                      <span>Quản lý ghi danh</span>
                    </Button>
                  </div>

                  {isRosterLoading ? (
                    <div className="flex flex-col gap-2 py-4">
                      {Array.from({ length: 4 }).map((_, i) => (
                        <Skeleton key={i} className="h-10 w-full rounded" />
                      ))}
                    </div>
                  ) : rosterStudents.length === 0 ? (
                    <div className="py-12 text-center text-on-surface-variant text-sm">
                      Lớp học phần này hiện chưa có sinh viên nào ghi danh.
                    </div>
                  ) : (
                    <div className="border border-surface-container rounded-lg overflow-hidden">
                      <table className="w-full text-left text-xs">
                        <thead className="bg-surface-container-low text-on-surface-variant font-semibold">
                          <tr>
                            <th className="py-2.5 px-3">MSSV</th>
                            <th className="py-2.5 px-3">Họ và tên</th>
                            <th className="py-2.5 px-3">Lớp SH</th>
                            <th className="py-2.5 px-3">Trạng thái</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-surface-container">
                          {rosterStudents.map((stu) => (
                            <tr key={stu.id} className="hover:bg-surface-container-low/40">
                              <td className="py-2.5 px-3 font-semibold text-primary">{stu.studentCode}</td>
                              <td className="py-2.5 px-3 font-medium text-on-surface">{stu.studentName}</td>
                              <td className="py-2.5 px-3 text-on-surface-variant">{stu.studentClass || '—'}</td>
                              <td className="py-2.5 px-3">
                                <span className="px-2 py-0.5 rounded-full bg-secondary/10 text-secondary font-bold text-[10px]">
                                  {stu.status}
                                </span>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              )}

              {drawerTab === 'sessions' && (
                <div className="flex flex-col gap-4 text-sm">
                  <div className="p-4 bg-surface-container-low rounded-xl flex flex-col gap-2">
                    <span className="text-xs font-semibold text-on-surface-variant uppercase">Chi tiết môn học</span>
                    <div className="flex justify-between">
                      <span className="text-on-surface-variant">Mã môn:</span>
                      <span className="font-bold text-on-surface">{selectedClassForDrawer.courseCode}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-on-surface-variant">Số tín chỉ:</span>
                      <span className="font-bold text-on-surface">{selectedClassForDrawer.credits} TC</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-on-surface-variant">Kế hoạch số tiết:</span>
                      <span className="font-bold text-on-surface">{selectedClassForDrawer.numberOfSlots} tiết</span>
                    </div>
                  </div>

                  <div className="p-4 bg-surface-container-low rounded-xl flex flex-col gap-2">
                    <span className="text-xs font-semibold text-on-surface-variant uppercase">Thông tin giảng viên</span>
                    <div className="flex justify-between">
                      <span className="text-on-surface-variant">Giảng viên:</span>
                      <span className="font-bold text-on-surface">{selectedClassForDrawer.lecturerName || 'Chưa phân công'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-on-surface-variant">Mã giảng viên:</span>
                      <span className="font-mono text-on-surface">{selectedClassForDrawer.lecturerCode || '—'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-on-surface-variant">Email:</span>
                      <span className="text-on-surface">{selectedClassForDrawer.lecturerEmail || '—'}</span>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Drawer Footer */}
            <div className="p-4 border-t border-surface-container bg-surface-container-lowest flex justify-end">
              <Button variant="outline" onClick={closeClassDrawer}>
                Đóng
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Modal: Thêm Lớp học phần Mới */}
      {isCreateModalOpen && (
        <Modal
          isOpen={isCreateModalOpen}
          onClose={() => setIsCreateModalOpen(false)}
          title="Thêm Lớp học phần Mới"
          hideFooter={true}
        >
          <form onSubmit={handleCreateSubmit} className="flex flex-col gap-4">
            {formError && (
              <div className="p-3 rounded-lg bg-error-container/40 border border-error/30 text-error text-xs flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{formError}</span>
              </div>
            )}

            {lookupsError && (
              <div className="p-3 rounded-lg bg-error-container/40 border border-error/30 text-error text-xs flex items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{lookupsError}</span>
                </div>
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  onClick={() => loadLookups()}
                  className="text-xs h-7 shrink-0"
                >
                  Thử lại
                </Button>
              </div>
            )}

            {/* Course Select */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-semibold text-on-surface">
                Chọn Môn học từ Catalog đào tạo <span className="text-error">*</span>
              </label>
              {isLookupsLoading ? (
                <div className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container flex items-center text-xs text-on-surface-variant gap-2">
                  <div className="w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin" />
                  <span>Đang tải danh mục môn học...</span>
                </div>
              ) : courses.length === 0 ? (
                <div className="flex flex-col gap-2">
                  <select
                    disabled
                    className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-outline opacity-70 cursor-not-allowed"
                  >
                    <option value="">-- Catalog đào tạo chưa có môn học --</option>
                  </select>
                  <div className="p-3 bg-amber-500/10 border border-amber-500/30 rounded-lg text-amber-700 dark:text-amber-300 text-xs flex items-center justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <AlertTriangle className="w-4 h-4 shrink-0" />
                      <span>Chưa có môn học nào trong Catalog. Bạn cần tạo môn học trước khi mở lớp.</span>
                    </div>
                    <Button
                      type="button"
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        setIsCreateModalOpen(false);
                        navigate('/admin/courses');
                      }}
                      className="text-xs h-7 shrink-0 flex items-center gap-1"
                    >
                      <ExternalLink className="w-3 h-3" />
                      <span>Tạo Môn học</span>
                    </Button>
                  </div>
                </div>
              ) : (
                <select
                  value={createForm.courseId}
                  onChange={(e) => handleCourseChangeInCreate(e.target.value)}
                  className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface outline-none focus:border-primary"
                  required
                >
                  <option value="">-- Chọn môn học từ Catalog --</option>
                  {courses.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.code} — {c.name} ({c.credits} TC)
                    </option>
                  ))}
                </select>
              )}
            </div>

            {/* Semester & Lecturer Row */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-on-surface">
                  Học kỳ &amp; Niên khóa <span className="text-error">*</span>
                </label>
                {isLookupsLoading ? (
                  <div className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container flex items-center text-xs text-on-surface-variant gap-2">
                    <div className="w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin" />
                    <span>Đang tải danh sách học kỳ...</span>
                  </div>
                ) : semesters.length === 0 ? (
                  <div className="flex flex-col gap-2">
                    <select
                      disabled
                      className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-outline opacity-70 cursor-not-allowed"
                    >
                      <option value="">-- Hệ thống chưa có học kỳ nào --</option>
                    </select>
                    <div className="p-3 bg-amber-500/10 border border-amber-500/30 rounded-lg text-amber-700 dark:text-amber-300 text-xs flex items-center justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <AlertTriangle className="w-4 h-4 shrink-0" />
                        <span>Chưa có học kỳ nào được cấu hình trong hệ thống.</span>
                      </div>
                      <Button
                        type="button"
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          setIsCreateModalOpen(false);
                          navigate('/admin/semesters');
                        }}
                        className="text-xs h-7 shrink-0 flex items-center gap-1"
                      >
                        <ExternalLink className="w-3 h-3" />
                        <span>Tạo Học kỳ</span>
                      </Button>
                    </div>
                  </div>
                ) : (
                  <select
                    value={createForm.semesterId}
                    onChange={(e) => setCreateForm({ ...createForm, semesterId: e.target.value })}
                    className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface outline-none focus:border-primary"
                    required
                  >
                    <option value="">-- Chọn học kỳ & niên khóa --</option>
                    {semesters.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.name} ({s.code}){s.status === 'ACTIVE' ? ' — [Học kỳ hiện hành]' : ''}
                      </option>
                    ))}
                  </select>
                )}
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-on-surface">
                  Giảng viên giảng dạy
                </label>
                {isLookupsLoading ? (
                  <div className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container flex items-center text-xs text-on-surface-variant gap-2">
                    <div className="w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin" />
                    <span>Đang tải giảng viên...</span>
                  </div>
                ) : (
                  <>
                    <select
                      value={createForm.lecturerId}
                      onChange={(e) => setCreateForm({ ...createForm, lecturerId: e.target.value })}
                      className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface outline-none focus:border-primary"
                    >
                      <option value="">-- Chưa phân công (Để trống) --</option>
                      {lecturers.map((lec) => (
                        <option key={lec.id} value={lec.id}>
                          {lec.fullName} ({lec.code || lec.username}){lec.department ? ` — ${lec.department}` : ''}
                        </option>
                      ))}
                    </select>
                    {lecturers.length === 0 && (
                      <span className="text-[11px] text-on-surface-variant">
                        Chưa có tài khoản Giảng viên ACTIVE. Bạn có thể mở lớp trước và phân công giảng viên sau.
                      </span>
                    )}
                  </>
                )}
              </div>
            </div>

            {/* ClassName & MaxStudents Row */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-on-surface">
                  Mã Lớp học phần <span className="text-error">*</span>
                </label>
                <input
                  type="text"
                  value={createForm.className}
                  onChange={(e) => setCreateForm({ ...createForm, className: e.target.value.toUpperCase() })}
                  placeholder="Ví dụ: IT301.01"
                  className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface font-bold outline-none focus:border-primary"
                  required
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-on-surface">
                  Sĩ số tối đa <span className="text-error">*</span>
                </label>
                <input
                  type="number"
                  min="1"
                  value={createForm.maxStudents}
                  onChange={(e) => setCreateForm({ ...createForm, maxStudents: Number(e.target.value) })}
                  className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface outline-none focus:border-primary"
                  required
                />
              </div>
            </div>

            {/* Slots & Status Row */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-on-surface">
                  Số tiết học kế hoạch
                </label>
                <input
                  type="number"
                  min="1"
                  value={createForm.numberOfSlots}
                  onChange={(e) => setCreateForm({ ...createForm, numberOfSlots: Number(e.target.value) })}
                  className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface outline-none focus:border-primary"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-on-surface">
                  Trạng thái mở lớp
                </label>
                <select
                  value={createForm.status}
                  onChange={(e) => setCreateForm({ ...createForm, status: e.target.value as ClassSectionStatus })}
                  className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface outline-none focus:border-primary"
                >
                  <option value="OPEN">Mở đăng ký (OPEN)</option>
                  <option value="ACTIVE">Đang giảng dạy (ACTIVE)</option>
                </select>
              </div>
            </div>

            <div className="flex justify-end gap-3 pt-3 border-t border-surface-container">
              <Button
                type="button"
                variant="outline"
                onClick={() => setIsCreateModalOpen(false)}
                disabled={isSubmitting}
              >
                Hủy bỏ
              </Button>
              <Button
                type="submit"
                variant="primary"
                disabled={isSubmitting || courses.length === 0 || semesters.length === 0}
                className="bg-primary hover:bg-primary-container text-white disabled:opacity-50"
              >
                {isSubmitting ? 'Đang lưu...' : 'Lưu & Mở lớp'}
              </Button>
            </div>
          </form>
        </Modal>
      )}

      {/* Modal: Sửa Lớp học phần */}
      {isEditModalOpen && classToEdit && (
        <Modal
          isOpen={isEditModalOpen}
          onClose={() => setIsEditModalOpen(false)}
          title={`Cập nhật Lớp học phần: ${classToEdit.className}`}
          hideFooter={true}
        >
          <form onSubmit={handleEditSubmit} className="flex flex-col gap-4">
            {formError && (
              <div className="p-3 rounded-lg bg-error-container/40 border border-error/30 text-error text-xs flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{formError}</span>
              </div>
            )}

            <div className="p-3 rounded-lg bg-surface-container-low text-xs flex flex-col gap-1">
              <div><strong className="text-on-surface">Môn học:</strong> {classToEdit.courseName} ({classToEdit.courseCode})</div>
              <div><strong className="text-on-surface">Học kỳ:</strong> {classToEdit.semesterName}</div>
              <div><strong className="text-on-surface">Sĩ số hiện tại:</strong> {classToEdit.currentEnrollment} sinh viên</div>
            </div>

            {/* Lecturer Select */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-semibold text-on-surface">
                Giảng viên phụ trách
              </label>
              <select
                value={editForm.lecturerId}
                onChange={(e) => setEditForm({ ...editForm, lecturerId: e.target.value })}
                className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface outline-none focus:border-primary"
              >
                <option value="">-- Chưa phân công --</option>
                {lecturers.map((lec) => (
                  <option key={lec.id} value={lec.id}>
                    {lec.fullName} ({lec.code || lec.username}){lec.department ? ` — ${lec.department}` : ''}
                  </option>
                ))}
              </select>
            </div>

            {/* Max Students & Slots */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-on-surface">
                  Sĩ số tối đa <span className="text-error">*</span>
                </label>
                <input
                  type="number"
                  min={classToEdit.currentEnrollment || 1}
                  value={editForm.maxStudents}
                  onChange={(e) => setEditForm({ ...editForm, maxStudents: Number(e.target.value) })}
                  className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface outline-none focus:border-primary"
                  required
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-on-surface">
                  Số tiết học
                </label>
                <input
                  type="number"
                  min="1"
                  value={editForm.numberOfSlots}
                  onChange={(e) => setEditForm({ ...editForm, numberOfSlots: Number(e.target.value) })}
                  className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface outline-none focus:border-primary"
                />
              </div>
            </div>

            {/* Status Select */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-semibold text-on-surface">
                Trạng thái lớp học phần <span className="text-error">*</span>
              </label>
              <select
                value={editForm.status}
                onChange={(e) => setEditForm({ ...editForm, status: e.target.value as ClassSectionStatus })}
                className="h-10 px-3 rounded-lg bg-surface-container-low border border-surface-container text-sm text-on-surface outline-none focus:border-primary"
                required
              >
                <option value="OPEN">Mở đăng ký (OPEN)</option>
                <option value="ACTIVE">Đang giảng dạy (ACTIVE)</option>
                <option value="CLOSED">Đã khóa / Kết thúc (CLOSED)</option>
                <option value="CANCELLED">Tạm hủy / Chờ gộp (CANCELLED)</option>
              </select>
            </div>

            <div className="flex justify-end gap-3 pt-3 border-t border-surface-container">
              <Button
                type="button"
                variant="outline"
                onClick={() => setIsEditModalOpen(false)}
                disabled={isSubmitting}
              >
                Hủy bỏ
              </Button>
              <Button
                type="submit"
                variant="primary"
                disabled={isSubmitting}
                className="bg-primary hover:bg-primary-container text-white"
              >
                {isSubmitting ? 'Đang cập nhật...' : 'Lưu thay đổi'}
              </Button>
            </div>
          </form>
        </Modal>
      )}

      {/* Modal: Xác nhận Xóa Lớp học phần */}
      {isDeleteModalOpen && classToDelete && (
        <Modal
          isOpen={isDeleteModalOpen}
          onClose={() => setIsDeleteModalOpen(false)}
          title="Xác nhận Xóa Lớp học phần"
          hideFooter={true}
        >
          <div className="flex flex-col gap-4">
            <div className="flex items-start gap-3 p-4 bg-error-container/30 rounded-xl text-error">
              <AlertTriangle className="w-6 h-6 shrink-0 mt-0.5" />
              <div className="flex flex-col text-sm">
                <span className="font-bold">Hành động này không thể hoàn tác!</span>
                <span>
                  Bạn có chắc chắn muốn xóa lớp học phần{' '}
                  <strong className="font-bold">{classToDelete.className}</strong> ({classToDelete.courseName})?
                </span>
              </div>
            </div>

            {classToDelete.currentEnrollment > 0 && (
              <div className="p-3 bg-error-container/50 text-error text-xs rounded-lg font-semibold">
                Cảnh báo: Lớp này hiện có {classToDelete.currentEnrollment} sinh viên đã ghi danh. Hệ thống sẽ chặn xóa để bảo toàn dữ liệu học vụ.
              </div>
            )}

            {formError && (
              <div className="p-3 rounded-lg bg-error-container/40 border border-error/30 text-error text-xs flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{formError}</span>
              </div>
            )}

            <div className="flex justify-end gap-3 pt-2">
              <Button
                variant="outline"
                onClick={() => setIsDeleteModalOpen(false)}
                disabled={isSubmitting}
              >
                Giữ lại lớp
              </Button>
              <Button
                variant="danger"
                onClick={handleDeleteConfirm}
                disabled={isSubmitting}
              >
                {isSubmitting ? 'Đang xóa...' : 'Xác nhận Xóa lớp'}
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};

export default ClassSectionPage;
