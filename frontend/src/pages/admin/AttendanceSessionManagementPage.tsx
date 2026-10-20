// ==============================================================================
// UniCheck - Attendance Session Management Page (TASK-05)
// Stitch Screen ID: 4f83098c7b904d4389563c28f54e1c48
// Routes: /admin/attendance/sessions, /dashboard/attendance-sessions, /lecturer/attendance-session
// ==============================================================================

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Calendar,
  CheckCircle2,
  Clock,
  Download,
  Eye,
  Lock,
  Play,
  PlusCircle,
  RefreshCw,
  Search,
  ShieldAlert,
  Users,
  Video,
  AlertTriangle,
  X,
  ChevronLeft,
  ChevronRight,
  Filter,
  Check,
  Radio,
  FileSpreadsheet,
  AlertCircle,
  QrCode,
  ScanFace,
  Sliders,
  Settings,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../store/auth-store';
import {
  getAttendanceSessionsApi,
  getAttendanceSessionByIdApi,
  createAttendanceSessionApi,
  openAttendanceSessionApi,
  closeAttendanceSessionApi,
  getAttendanceSessionStatsApi,
  getAttendanceCheckInsApi,
} from '../../api/attendance.api';
import { getSemestersApi } from '../../api/semesters.api';
import { getTimetableSlotsApi } from '../../api/timetable.api';
import {
  AttendanceSessionResponse,
  AttendanceSessionStatus,
  AttendanceSessionStatsResponse,
  StudentAttendanceResponse,
  SemesterResponse,
  TimetableSlotResponse,
} from '../../types/api';

export const AttendanceSessionManagementPage: React.FC = () => {
  const navigate = useNavigate();
  const user = useAuthStore((state) => state.user);
  const isAdmin = user?.role === 'ADMIN';
  const isLecturer = user?.role === 'LECTURER';

  // 1. Core State
  const [sessions, setSessions] = useState<AttendanceSessionResponse[]>([]);
  const [selectedSession, setSelectedSession] = useState<AttendanceSessionResponse | null>(null);
  const [checkIns, setCheckIns] = useState<StudentAttendanceResponse[]>([]);
  const [stats, setStats] = useState<AttendanceSessionStatsResponse>({
    totalSessionsToday: 0,
    morningSessions: 0,
    afternoonSessions: 0,
    activeOpenSessions: 0,
    completedSessions: 0,
    onTimeRate: 100.0,
    abnormalSessions: 0,
  });

  const [semesters, setSemesters] = useState<SemesterResponse[]>([]);
  const [availableSlots, setAvailableSlots] = useState<TimetableSlotResponse[]>([]);

  // 2. Filters & Pagination
  const [search, setSearch] = useState('');
  const [selectedSemesterId, setSelectedSemesterId] = useState<number | undefined>(undefined);
  const [selectedStatus, setSelectedStatus] = useState<AttendanceSessionStatus | 'ALL'>('ALL');
  const [selectedDate, setSelectedDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const [totalElements, setTotalElements] = useState(0);
  const [totalPages, setTotalPages] = useState(1);

  // 3. UI Status State
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [drawerLoading, setDrawerLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [countdown, setCountdown] = useState(15);

  // 4. Modals State
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedSlotIdForCreate, setSelectedSlotIdForCreate] = useState<number | null>(null);
  const [autoOpenOnCreate, setAutoOpenOnCreate] = useState(false);
  const [createModalLoading, setCreateModalLoading] = useState(false);

  const [confirmDialog, setConfirmDialog] = useState<{
    open: boolean;
    type: 'OPEN' | 'CLOSE';
    session: AttendanceSessionResponse | null;
  }>({
    open: false,
    type: 'OPEN',
    session: null,
  });

  // ============================================================================
  // Data Fetching
  // ============================================================================

  const fetchSemesters = useCallback(async () => {
    try {
      const res = await getSemestersApi({ page: 0, size: 20 });
      if (res.success && res.data?.content) {
        setSemesters(res.data.content);
        const activeSem = res.data.content.find((s) => s.status === 'ACTIVE');
        if (activeSem) {
          setSelectedSemesterId(activeSem.id);
        }
      }
    } catch (err: any) {
      console.warn('Could not load semesters:', err?.message);
    }
  }, []);

  const fetchStats = useCallback(async () => {
    try {
      const res = await getAttendanceSessionStatsApi();
      if (res.success && res.data) {
        setStats(res.data);
      }
    } catch (err: any) {
      console.warn('Could not load stats:', err?.message);
    }
  }, []);

  const fetchSessions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await getAttendanceSessionsApi({
        search: search.trim() || undefined,
        semesterId: selectedSemesterId,
        lecturerId: isLecturer ? user?.id : undefined,
        date: selectedDate || undefined,
        status: selectedStatus,
        page,
        size: pageSize,
      });

      if (res.success && res.data) {
        const content = res.data.content || [];
        setSessions(content);
        setTotalElements(res.data.totalElements || 0);
        setTotalPages(res.data.totalPages || 1);

        // Keep or update selected session
        if (content.length > 0) {
          setSelectedSession((prev) => {
            if (!prev || !content.some((s) => s.id === prev.id)) {
              return content[0];
            }
            const fresh = content.find((s) => s.id === prev.id);
            return fresh || prev;
          });
        } else {
          setSelectedSession(null);
        }
      }
    } catch (err: any) {
      setError(err?.message || 'Không thể tải danh sách phiên điểm danh');
    } finally {
      setLoading(false);
    }
  }, [search, selectedSemesterId, isLecturer, user?.id, selectedDate, selectedStatus, page, pageSize]);

  const fetchCheckIns = useCallback(async (sessionId: number) => {
    setDrawerLoading(true);
    try {
      const res = await getAttendanceCheckInsApi(sessionId);
      if (res.success && res.data) {
        setCheckIns(res.data);
      } else {
        setCheckIns([]);
      }
    } catch {
      setCheckIns([]);
    } finally {
      setDrawerLoading(false);
    }
  }, []);

  // Initial loading
  useEffect(() => {
    fetchSemesters();
    fetchStats();
  }, [fetchSemesters, fetchStats]);

  useEffect(() => {
    fetchSessions();
  }, [fetchSessions]);

  // Load check-in activity whenever selected session changes
  useEffect(() => {
    if (selectedSession?.id) {
      fetchCheckIns(selectedSession.id);
    } else {
      setCheckIns([]);
    }
  }, [selectedSession?.id, fetchCheckIns]);

  // Auto-refresh timer (15 seconds countdown)
  useEffect(() => {
    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          fetchSessions();
          fetchStats();
          return 15;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [fetchSessions, fetchStats]);

  // Load slots for Create Modal
  const openCreateModal = async () => {
    setCreateModalLoading(true);
    setShowCreateModal(true);
    setSelectedSlotIdForCreate(null);
    setAutoOpenOnCreate(false);
    try {
      const res = await getTimetableSlotsApi({
        semesterId: selectedSemesterId,
        lecturerId: isLecturer ? user?.id : undefined,
        status: 'SCHEDULED',
        size: 50,
      });

      if (res.success && res.data) {
        const slots = Array.isArray(res.data) ? res.data : res.data.content || [];
        setAvailableSlots(slots);
        if (slots.length > 0) {
          setSelectedSlotIdForCreate(slots[0].id);
        }
      }
    } catch (err: any) {
      console.warn('Could not load slots:', err?.message);
    } finally {
      setCreateModalLoading(false);
    }
  };

  // ============================================================================
  // Action Handlers
  // ============================================================================

  const handleCreateSession = async () => {
    if (!selectedSlotIdForCreate) {
      setError('Vui lòng chọn một tiết học hợp lệ từ thời khóa biểu');
      return;
    }

    setActionLoading(true);
    setError(null);
    try {
      const res = await createAttendanceSessionApi({
        timetableSlotId: selectedSlotIdForCreate,
        autoOpen: autoOpenOnCreate,
      });

      if (res.success) {
        setSuccessMessage(`Đã khởi tạo phiên điểm danh thành công (#SES-${res.data.id})`);
        setShowCreateModal(false);
        fetchSessions();
        fetchStats();
        setTimeout(() => setSuccessMessage(null), 4000);
      }
    } catch (err: any) {
      setError(err?.message || 'Lỗi khi khởi tạo phiên điểm danh');
    } finally {
      setActionLoading(false);
    }
  };

  const executeOpenSession = async (session: AttendanceSessionResponse) => {
    setActionLoading(true);
    setError(null);
    try {
      const res = await openAttendanceSessionApi(session.id);
      if (res.success) {
        setSuccessMessage(`Đã mở phiên điểm danh thành công (#SES-${session.id}) cho lớp ${session.className}`);
        setConfirmDialog({ open: false, type: 'OPEN', session: null });
        fetchSessions();
        fetchStats();
        setTimeout(() => setSuccessMessage(null), 4000);
      }
    } catch (err: any) {
      setError(err?.message || 'Lỗi khi mở phiên điểm danh');
    } finally {
      setActionLoading(false);
    }
  };

  const executeCloseSession = async (session: AttendanceSessionResponse) => {
    setActionLoading(true);
    setError(null);
    try {
      const res = await closeAttendanceSessionApi(session.id);
      if (res.success) {
        setSuccessMessage(`Đã chốt sổ và đóng phiên điểm danh (#SES-${session.id})`);
        setConfirmDialog({ open: false, type: 'CLOSE', session: null });
        fetchSessions();
        fetchStats();
        setTimeout(() => setSuccessMessage(null), 4000);
      }
    } catch (err: any) {
      setError(err?.message || 'Lỗi khi đóng phiên điểm danh');
    } finally {
      setActionLoading(false);
    }
  };

  // Badge Helper
  const renderStatusBadge = (status: AttendanceSessionStatus) => {
    switch (status) {
      case 'OPEN':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-emerald-700 bg-emerald-50 border border-emerald-200 text-xs font-semibold">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
            Đang mở
          </span>
        );
      case 'CREATED':
        return (
          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-slate-700 bg-slate-100 border border-slate-200 text-xs font-medium">
            <Clock className="w-3.5 h-3.5 text-slate-500" />
            Sắp diễn ra
          </span>
        );
      case 'CLOSED':
        return (
          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-blue-700 bg-blue-50 border border-blue-200 text-xs font-semibold">
            <Lock className="w-3.5 h-3.5 text-blue-600" />
            Đã chốt sổ
          </span>
        );
      case 'CANCELLED':
        return (
          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-red-700 bg-red-50 border border-red-200 text-xs font-semibold">
            <AlertTriangle className="w-3.5 h-3.5 text-red-500" />
            Bất thường
          </span>
        );
      default:
        return null;
    }
  };

  return (
    <div className="flex flex-col w-full min-h-screen bg-[#faf8ff] p-6 lg:p-8">
      {/* 1. Header & Live Indicator Hub */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 mb-8">
        <div>
          <div className="flex items-center gap-2 text-xs text-slate-500 uppercase tracking-wider mb-1 font-medium">
            <span>Trang chủ</span>
            <span>/</span>
            <span>Quản lý điểm danh</span>
            <span>/</span>
            <span className="text-blue-700 font-bold">Phiên điểm danh giảng đường</span>
          </div>

          <div className="flex items-center gap-3">
            <h1 className="text-2xl lg:text-3xl font-bold text-slate-900 tracking-tight">
              Quản lý phiên điểm danh giảng đường
            </h1>
            <span className="hidden sm:inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-teal-50 border border-teal-200 text-teal-800 text-xs font-semibold">
              <span className="w-2 h-2 rounded-full bg-teal-500 animate-ping" />
              Live Sync Engine v3.4
            </span>
          </div>
          <p className="text-sm text-slate-600 max-w-3xl mt-1">
            {isLecturer
              ? 'Khởi tạo, kích hoạt và theo dõi trực tiếp các ca điểm danh thuộc những lớp học phần bạn được phân công giảng dạy.'
              : 'Theo dõi, điều phối và kiểm soát trạng thái các phiên điểm danh theo thời khóa biểu thực tế trên toàn cơ sở đào tạo thông qua hệ thống AI Kiosk và Dynamic QR.'}
          </p>
        </div>

        {/* Global Action Hub */}
        <div className="flex flex-wrap items-center gap-2 shrink-0">
          <button
            type="button"
            onClick={() => {
              fetchSessions();
              fetchStats();
              setCountdown(15);
            }}
            className="flex items-center gap-1.5 h-10 px-4 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 font-medium text-sm transition-all shadow-sm"
          >
            <RefreshCw className="w-4 h-4 text-blue-600" />
            <span>Đồng bộ TKB tự động</span>
          </button>

          {isAdmin && (
            <button
              type="button"
              onClick={() => navigate('/admin/attendance/configs')}
              className="flex items-center gap-1.5 h-10 px-4 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 font-medium text-sm transition-all shadow-sm"
            >
              <Sliders className="w-4 h-4 text-teal-600" />
              <span>Cấu hình cơ chế</span>
            </button>
          )}

          <button
            type="button"
            onClick={openCreateModal}
            className="flex items-center gap-1.5 h-10 px-5 rounded-lg bg-blue-600 hover:bg-blue-700 text-white font-medium text-sm transition-all shadow-md hover:shadow-lg"
          >
            <PlusCircle className="w-4 h-4" />
            <span>{isLecturer ? 'Tạo phiên lớp phụ trách' : 'Mở phiên thủ công / Khẩn cấp'}</span>
          </button>
        </div>
      </div>

      {/* Notifications */}
      {successMessage && (
        <div className="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 flex items-center justify-between shadow-sm animate-fadeIn">
          <div className="flex items-center gap-2 font-medium text-sm">
            <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
            <span>{successMessage}</span>
          </div>
          <button type="button" onClick={() => setSuccessMessage(null)}>
            <X className="w-4 h-4 text-emerald-600" />
          </button>
        </div>
      )}

      {error && (
        <div className="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-800 flex items-center justify-between shadow-sm animate-fadeIn">
          <div className="flex items-center gap-2 font-medium text-sm">
            <AlertCircle className="w-5 h-5 text-red-600 shrink-0" />
            <span>{error}</span>
          </div>
          <button type="button" onClick={() => setError(null)}>
            <X className="w-4 h-4 text-red-600" />
          </button>
        </div>
      )}

      {/* 2. KPI Metric Overview Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5 mb-8">
        {/* Card 1: Tổng phiên trong ngày */}
        <div className="bg-white rounded-xl p-5 border border-slate-200/80 shadow-sm flex flex-col justify-between hover:shadow-md transition-shadow">
          <div className="flex items-start justify-between">
            <div>
              <span className="text-xs font-semibold text-slate-500 uppercase tracking-wide">
                Tổng phiên trong ngày
              </span>
              <div className="text-3xl font-bold text-slate-900 mt-1">{stats.totalSessionsToday}</div>
            </div>
            <div className="w-12 h-12 rounded-xl bg-blue-50 flex items-center justify-center text-blue-600">
              <Calendar className="w-6 h-6" />
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-600">
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-blue-600" />
              <span>Ca sáng: <strong>{stats.morningSessions}</strong></span>
            </div>
            <span className="text-slate-300">/</span>
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-teal-600" />
              <span>Ca chiều: <strong>{stats.afternoonSessions}</strong></span>
            </div>
          </div>
        </div>

        {/* Card 2: Phiên đang mở trực tiếp */}
        <div className="bg-white rounded-xl p-5 border border-slate-200/80 shadow-sm flex flex-col justify-between hover:shadow-md transition-shadow">
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-1.5">
                <span className="text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Phiên đang mở trực tiếp
                </span>
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              </div>
              <div className="text-3xl font-bold text-emerald-600 mt-1">{stats.activeOpenSessions}</div>
            </div>
            <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600">
              <Radio className="w-6 h-6" />
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center gap-1.5 text-xs text-emerald-700 font-medium">
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            <span>Face-ID Kiosk & Dynamic QR hoạt động 100%</span>
          </div>
        </div>

        {/* Card 3: Phiên đã hoàn thành */}
        <div className="bg-white rounded-xl p-5 border border-slate-200/80 shadow-sm flex flex-col justify-between hover:shadow-md transition-shadow">
          <div className="flex items-start justify-between">
            <div>
              <span className="text-xs font-semibold text-slate-500 uppercase tracking-wide">
                Phiên đã hoàn thành
              </span>
              <div className="text-3xl font-bold text-blue-700 mt-1">{stats.completedSessions}</div>
            </div>
            <div className="w-12 h-12 rounded-xl bg-blue-50 flex items-center justify-center text-blue-700">
              <Check className="w-6 h-6" />
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-600">
            <span>Tỷ lệ khớp đúng giờ TKB</span>
            <span className="text-emerald-600 font-bold">{Number(stats?.onTimeRate ?? stats?.attendanceRatePercentage ?? 95.2).toFixed(1)}%</span>
          </div>
        </div>

        {/* Card 4: Bất thường / Xung đột */}
        <div className="bg-white rounded-xl p-5 border border-slate-200/80 shadow-sm flex flex-col justify-between hover:shadow-md transition-shadow">
          <div className="flex items-start justify-between">
            <div>
              <span className="text-xs font-semibold text-red-600 uppercase tracking-wide">
                Bất thường / Hủy ca
              </span>
              <div className="text-3xl font-bold text-red-600 mt-1">
                {String(stats.abnormalSessions ?? stats.abnormalCount ?? 0).padStart(2, '0')}
              </div>
            </div>
            <div className="w-12 h-12 rounded-xl bg-red-50 flex items-center justify-center text-red-600">
              <AlertTriangle className="w-6 h-6" />
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center gap-1.5 text-xs text-red-600 font-medium">
            <ShieldAlert className="w-4 h-4 text-red-500" />
            <span>{(stats.abnormalSessions ?? stats.abnormalCount ?? 0) > 0 ? 'Cần giảng viên / QTV kiểm tra ngay' : 'Không có xung đột ghi nhận'}</span>
          </div>
        </div>
      </div>

      {/* 3. Filter Toolbar Card */}
      <div className="bg-white rounded-xl p-5 border border-slate-200/80 shadow-sm mb-6 flex flex-col gap-4">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-12 gap-3 items-center">
          {/* Search Field */}
          <div className="lg:col-span-4 relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(0);
              }}
              placeholder="Tìm mã phiên (#SES-xxxx), mã lớp (IT301), môn, phòng..."
              className="w-full h-10 pl-9 pr-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-800 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all"
            />
          </div>

          {/* Semester Dropdown */}
          <div className="lg:col-span-3">
            <select
              value={selectedSemesterId || ''}
              onChange={(e) => {
                setSelectedSemesterId(e.target.value ? Number(e.target.value) : undefined);
                setPage(0);
              }}
              className="w-full h-10 px-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-800 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 cursor-pointer"
            >
              <option value="">Tất cả học kỳ</option>
              {semesters.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name} ({s.code})
                </option>
              ))}
            </select>
          </div>

          {/* Date Selector */}
          <div className="lg:col-span-3">
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => {
                setSelectedDate(e.target.value);
                setPage(0);
              }}
              className="w-full h-10 px-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-800 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 cursor-pointer"
            />
          </div>

          {/* Quick Clear Button */}
          <div className="lg:col-span-2 flex items-center justify-end">
            <button
              type="button"
              onClick={() => {
                setSearch('');
                setSelectedStatus('ALL');
                setSelectedDate(new Date().toISOString().split('T')[0]);
                setPage(0);
              }}
              className="w-full h-10 px-3 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600 text-sm font-medium transition-colors"
            >
              Đặt lại bộ lọc
            </button>
          </div>
        </div>

        {/* Status Tabs Segmented & Live ticker */}
        <div className="flex items-center justify-between gap-4 pt-2 border-t border-slate-100 flex-wrap">
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0">
            <button
              type="button"
              onClick={() => {
                setSelectedStatus('ALL');
                setPage(0);
              }}
              className={`px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all ${
                selectedStatus === 'ALL'
                  ? 'bg-blue-600 text-white shadow-sm'
                  : 'bg-slate-100 hover:bg-slate-200 text-slate-600'
              }`}
            >
              Tất cả
            </button>

            <button
              type="button"
              onClick={() => {
                setSelectedStatus('OPEN');
                setPage(0);
              }}
              className={`px-3.5 py-1.5 rounded-full text-xs font-semibold flex items-center gap-1.5 transition-all ${
                selectedStatus === 'OPEN'
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'bg-slate-100 hover:bg-slate-200 text-slate-600'
              }`}
            >
              <span className={`w-2 h-2 rounded-full ${selectedStatus === 'OPEN' ? 'bg-white' : 'bg-emerald-500'}`} />
              Đang mở
            </button>

            <button
              type="button"
              onClick={() => {
                setSelectedStatus('CREATED');
                setPage(0);
              }}
              className={`px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all ${
                selectedStatus === 'CREATED'
                  ? 'bg-slate-700 text-white shadow-sm'
                  : 'bg-slate-100 hover:bg-slate-200 text-slate-600'
              }`}
            >
              Sắp diễn ra
            </button>

            <button
              type="button"
              onClick={() => {
                setSelectedStatus('CLOSED');
                setPage(0);
              }}
              className={`px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all ${
                selectedStatus === 'CLOSED'
                  ? 'bg-blue-700 text-white shadow-sm'
                  : 'bg-slate-100 hover:bg-slate-200 text-slate-600'
              }`}
            >
              Đã chốt sổ
            </button>

            <button
              type="button"
              onClick={() => {
                setSelectedStatus('CANCELLED');
                setPage(0);
              }}
              className={`px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all ${
                selectedStatus === 'CANCELLED'
                  ? 'bg-red-600 text-white shadow-sm'
                  : 'bg-red-50 hover:bg-red-100 text-red-700'
              }`}
            >
              Bất thường
            </button>
          </div>

          <div className="flex items-center gap-2 text-xs text-slate-500">
            <span>Tự động cập nhật:</span>
            <span className="font-bold text-blue-700 font-mono">00:{String(countdown).padStart(2, '0')}s</span>
            <button
              type="button"
              onClick={() => {
                fetchSessions();
                fetchStats();
                setCountdown(15);
              }}
              className="w-7 h-7 rounded-lg hover:bg-slate-100 flex items-center justify-center text-slate-500"
              title="Làm mới ngay"
            >
              <RefreshCw className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      {/* 4. Main Content Layout: Data Grid + Real-time Drawer preview */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-start mb-8">
        {/* Session Table (Left/Center: 8 cols) */}
        <div className="xl:col-span-8 bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden flex flex-col">
          <div className="p-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
            <div className="flex items-center gap-2">
              <Calendar className="w-5 h-5 text-blue-600" />
              <span className="font-bold text-slate-900 text-base">Danh sách phiên giảng đường</span>
            </div>
            <span className="text-xs text-slate-500">
              Tổng số: <strong>{totalElements}</strong> phiên
            </span>
          </div>

          {loading ? (
            <div className="py-20 flex flex-col items-center justify-center text-slate-400 gap-3">
              <RefreshCw className="w-8 h-8 animate-spin text-blue-600" />
              <p className="text-sm">Đang tải dữ liệu phiên điểm danh...</p>
            </div>
          ) : sessions.length === 0 ? (
            <div className="py-20 flex flex-col items-center justify-center text-slate-400 gap-3 text-center px-4">
              <Calendar className="w-12 h-12 text-slate-300 stroke-[1.5]" />
              <div className="text-base font-semibold text-slate-700">Không tìm thấy phiên điểm danh nào</div>
              <p className="text-sm text-slate-500 max-w-md">
                Không có phiên phù hợp với bộ lọc hiện tại. Bạn có thể thay đổi ngày học hoặc tạo mới phiên từ lịch giảng dạy.
              </p>
              <button
                type="button"
                onClick={openCreateModal}
                className="mt-2 px-4 py-2 rounded-lg bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium"
              >
                Tạo phiên điểm danh mới
              </button>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50/80 text-slate-600 font-semibold text-xs border-b border-slate-200">
                    <th className="py-3 px-4">Mã phiên & Lớp</th>
                    <th className="py-3 px-4">Giảng đường / Phòng</th>
                    <th className="py-3 px-4">Khung giờ TKB</th>
                    <th className="py-3 px-4">Trạng thái phiên</th>
                    <th className="py-3 px-4">Tiến độ điểm danh</th>
                    <th className="py-3 px-4 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-sm">
                  {sessions.map((ses) => {
                    const isSelected = selectedSession?.id === ses.id;
                    return (
                      <tr
                        key={ses.id}
                        onClick={() => setSelectedSession(ses)}
                        className={`cursor-pointer transition-colors ${
                          isSelected ? 'bg-blue-50/60 font-medium' : 'hover:bg-slate-50/70'
                        }`}
                      >
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-2.5">
                            <div
                              className={`w-1.5 h-10 rounded-full shrink-0 ${
                                ses.status === 'OPEN'
                                  ? 'bg-emerald-500'
                                  : ses.status === 'CLOSED'
                                  ? 'bg-blue-600'
                                  : ses.status === 'CANCELLED'
                                  ? 'bg-red-500'
                                  : 'bg-slate-300'
                              }`}
                            />
                            <div className="min-w-0">
                              <div className="flex items-center gap-1.5">
                                <span className="font-mono text-xs font-bold text-blue-700">#SES-{ses.id}</span>
                                <span className="px-1.5 py-0.2 rounded bg-blue-100 text-blue-800 text-[10px] font-bold">
                                  Face-ID & QR
                                </span>
                              </div>
                              <div className="font-semibold text-slate-900 truncate">
                                {ses.className} - {ses.courseName}
                              </div>
                              <div className="text-xs text-slate-500">GV: {ses.lecturerName}</div>
                            </div>
                          </div>
                        </td>

                        <td className="py-3.5 px-4 whitespace-nowrap">
                          <div className="font-semibold text-slate-900">{ses.roomCode}</div>
                          <div className="text-xs text-slate-500">{ses.building || ses.roomName || 'Cơ sở chính'}</div>
                        </td>

                        <td className="py-3.5 px-4 whitespace-nowrap">
                          <div className="font-semibold text-slate-900">
                            {ses.slotName || `Tiết ${ses.slotNumber}`} ({ses.startTime?.substring(0, 5)} - {ses.endTime?.substring(0, 5)})
                          </div>
                          <div className="text-xs text-slate-500">
                            Ngày: {ses.date}
                            {ses.openedAt && (
                              <span className="text-emerald-600 ml-1">
                                • Mở: {new Date(ses.openedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                              </span>
                            )}
                          </div>
                        </td>

                        <td className="py-3.5 px-4 whitespace-nowrap">{renderStatusBadge(ses.status)}</td>

                        <td className="py-3.5 px-4 min-w-[140px]">
                          <div className="flex justify-between items-center mb-1 text-xs">
                            <span className="font-semibold text-slate-800">
                              {ses.totalAttendedStudents} / {ses.totalEnrolledStudents} SV
                            </span>
                            <span className="font-bold text-blue-600">{Number(ses.attendancePercentage ?? 0).toFixed(1)}%</span>
                          </div>
                          <div className="w-full h-2 rounded-full bg-slate-100 overflow-hidden">
                            <div
                              className={`h-full rounded-full ${
                                ses.attendancePercentage >= 80 ? 'bg-emerald-500' : 'bg-blue-600'
                              }`}
                              style={{ width: `${Math.min(100, ses.attendancePercentage)}%` }}
                            />
                          </div>
                        </td>

                        <td className="py-3.5 px-4 text-right whitespace-nowrap">
                          <div className="flex items-center justify-end gap-1.5" onClick={(e) => e.stopPropagation()}>
                            {ses.canOpen && (
                              <button
                                type="button"
                                onClick={() => setConfirmDialog({ open: true, type: 'OPEN', session: ses })}
                                className="px-2.5 py-1 rounded-md bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold flex items-center gap-1 shadow-xs"
                                title="Mở phiên điểm danh"
                              >
                                <Play className="w-3.5 h-3.5 fill-current" />
                                <span>Mở</span>
                              </button>
                            )}

                            {ses.canClose && (
                              <button
                                type="button"
                                onClick={() => setConfirmDialog({ open: true, type: 'CLOSE', session: ses })}
                                className="px-2.5 py-1 rounded-md bg-red-600 hover:bg-red-700 text-white text-xs font-semibold flex items-center gap-1 shadow-xs"
                                title="Đóng phiên / Chốt sổ"
                              >
                                <Lock className="w-3.5 h-3.5" />
                                <span>Chốt sổ</span>
                              </button>
                            )}

                            {ses.status === 'OPEN' && (
                              <button
                                type="button"
                                onClick={() => navigate(`/lecturer/session/qr?sessionId=${ses.id}`)}
                                className="px-2.5 py-1 rounded-md bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold flex items-center gap-1 shadow-xs"
                                title="Chiếu mã QR xoay vòng"
                              >
                                <QrCode className="w-3.5 h-3.5" />
                                <span>Hiển thị QR</span>
                              </button>
                            )}

                            <button
                              type="button"
                              onClick={() => setSelectedSession(ses)}
                              className="w-8 h-8 rounded-md hover:bg-slate-200 flex items-center justify-center text-slate-600 transition-colors"
                              title="Xem chi tiết phiên"
                            >
                              <Eye className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination Footer */}
          <div className="p-4 border-t border-slate-100 flex flex-col sm:flex-row items-center justify-between gap-3 bg-white text-xs text-slate-600">
            <div>
              Trang <strong>{page + 1}</strong> trên <strong>{totalPages || 1}</strong> (Tổng {totalElements} phiên)
            </div>

            <div className="flex items-center gap-1">
              <button
                type="button"
                disabled={page <= 0}
                onClick={() => setPage((p) => Math.max(0, p - 1))}
                className="w-8 h-8 rounded-lg border border-slate-200 hover:bg-slate-50 flex items-center justify-center disabled:opacity-40"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>

              {Array.from({ length: Math.min(5, totalPages) }, (_, idx) => {
                const pageNumber = idx;
                return (
                  <button
                    key={pageNumber}
                    type="button"
                    onClick={() => setPage(pageNumber)}
                    className={`w-8 h-8 rounded-lg font-semibold ${
                      page === pageNumber ? 'bg-blue-600 text-white' : 'border border-slate-200 hover:bg-slate-50 text-slate-700'
                    }`}
                  >
                    {pageNumber + 1}
                  </button>
                );
              })}

              <button
                type="button"
                disabled={page >= totalPages - 1}
                onClick={() => setPage((p) => p + 1)}
                className="w-8 h-8 rounded-lg border border-slate-200 hover:bg-slate-50 flex items-center justify-center disabled:opacity-40"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* Selected Session Detail Drawer (Right 4 cols) */}
        <div className="xl:col-span-4 bg-white rounded-xl border border-slate-200/80 shadow-sm p-5 flex flex-col gap-5 sticky top-20">
          {selectedSession ? (
            <>
              {/* Live Header */}
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2">
                  <div
                    className={`w-2.5 h-2.5 rounded-full ${
                      selectedSession.status === 'OPEN' ? 'bg-emerald-500 animate-ping' : 'bg-slate-400'
                    }`}
                  />
                  <span className="font-bold text-xs uppercase tracking-wider text-slate-700">
                    {selectedSession.status === 'OPEN' ? 'Phiên trực tiếp theo dõi' : 'Chi tiết phiên học'}
                  </span>
                </div>
                <span className="font-mono text-xs font-bold text-blue-700 px-2.5 py-0.5 rounded-full bg-blue-50 border border-blue-100">
                  ID: #SES-{selectedSession.id}
                </span>
              </div>

              {/* Lecture Room Video Mock or Overview */}
              <div className="relative w-full h-40 rounded-xl overflow-hidden bg-slate-800 shadow-inner group flex items-center justify-center text-white">
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent flex flex-col justify-between p-3.5">
                  <div className="flex items-center justify-between">
                    <span className="px-2 py-0.5 rounded bg-black/60 backdrop-blur-md text-[11px] font-semibold flex items-center gap-1.5">
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                      Phòng {selectedSession.roomCode}
                    </span>
                    <span className="px-2 py-0.5 rounded bg-blue-600/90 font-mono text-[10px] font-bold">
                      Kiosk K-{selectedSession.roomCode.replace(/[^A-Za-z0-9]/g, '')}
                    </span>
                  </div>

                  <div>
                    <div className="font-bold text-sm text-white">{selectedSession.className}</div>
                    <div className="text-xs text-slate-300">
                      {selectedSession.slotName || `Tiết ${selectedSession.slotNumber}`} ({selectedSession.startTime?.substring(0, 5)} - {selectedSession.endTime?.substring(0, 5)})
                    </div>
                  </div>
                </div>
              </div>

              {/* Specs */}
              <div className="grid grid-cols-2 gap-3 bg-slate-50 p-3.5 rounded-xl border border-slate-100 text-xs">
                <div>
                  <span className="text-slate-400 uppercase font-medium">Lớp học phần</span>
                  <div className="font-bold text-slate-900 mt-0.5 truncate">{selectedSession.className}</div>
                  <span className="text-slate-500 truncate block">{selectedSession.courseName}</span>
                </div>
                <div>
                  <span className="text-slate-400 uppercase font-medium">Giảng viên</span>
                  <div className="font-bold text-slate-900 mt-0.5 truncate">{selectedSession.lecturerName}</div>
                  <span className="text-emerald-600 font-semibold">Đã phân công</span>
                </div>
              </div>

              {/* Attendance Meter Gauge */}
              <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex items-center justify-between">
                <div>
                  <span className="text-xs text-slate-500 uppercase font-medium">Tỷ lệ tham gia thực tế</span>
                  <div className="flex items-baseline gap-1 mt-0.5">
                    <span className="text-2xl font-bold text-blue-700">{selectedSession.totalAttendedStudents}</span>
                    <span className="text-sm text-slate-500">/ {selectedSession.totalEnrolledStudents} SV</span>
                  </div>
                  <span className="text-xs text-emerald-600 font-semibold">
                    Đạt {Number(selectedSession.attendancePercentage ?? 0).toFixed(1)}% chuyên cần
                  </span>
                </div>

                {/* Circular Gauge */}
                <div className="relative w-14 h-14 flex items-center justify-center">
                  <svg className="w-full h-full -rotate-90" viewBox="0 0 36 36">
                    <path
                      className="text-slate-200"
                      d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="3.5"
                    />
                    <path
                      className="text-emerald-500"
                      d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      fill="none"
                      stroke="currentColor"
                      strokeDasharray={`${Number(selectedSession.attendancePercentage ?? 0)}, 100`}
                      strokeLinecap="round"
                      strokeWidth="3.5"
                    />
                  </svg>
                  <span className="absolute font-mono font-bold text-[10px] text-slate-800">
                    {Math.round(Number(selectedSession.attendancePercentage ?? 0))}%
                  </span>
                </div>
              </div>

              {/* Live Check-in Activity Feed */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="font-bold text-xs text-slate-700 uppercase">Nhật ký Check-in vừa nhận</span>
                  <span className="text-[11px] text-emerald-600 font-medium flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                    Dữ liệu thực tế
                  </span>
                </div>

                <div className="space-y-2 max-h-52 overflow-y-auto pr-1">
                  {drawerLoading ? (
                    <div className="py-6 text-center text-xs text-slate-400">Đang cập nhật lượt điểm danh...</div>
                  ) : checkIns.length === 0 ? (
                    <div className="py-6 text-center text-xs text-slate-400 bg-slate-50 rounded-lg border border-dashed border-slate-200">
                      Chưa có sinh viên nào thực hiện điểm danh trong phiên này.
                    </div>
                  ) : (
                    checkIns.map((ci) => (
                      <div
                        key={ci.id}
                        className="flex items-center justify-between p-2 rounded-lg bg-slate-50 border border-slate-100 text-xs"
                      >
                        <div className="flex items-center gap-2 min-w-0">
                          <div className="w-7 h-7 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-700 shrink-0 font-bold text-[10px]">
                            {ci.method === 'FACE' ? <ScanFace className="w-3.5 h-3.5" /> : <QrCode className="w-3.5 h-3.5" />}
                          </div>
                          <div className="truncate">
                            <div className="font-bold text-slate-900 truncate">{ci.studentName}</div>
                            <div className="text-[11px] text-slate-500 font-mono">
                              {ci.studentCode} • {ci.method}
                            </div>
                          </div>
                        </div>
                        <div className="text-right shrink-0">
                          <div className="font-mono font-semibold text-emerald-600 text-[11px]">
                            {ci.checkInTime ? new Date(ci.checkInTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }) : 'Vừa xong'}
                          </div>
                          {ci.faceConfidence != null && (
                            <span className="text-[10px] text-slate-400">Khớp {(Number(ci.faceConfidence) * 100).toFixed(1)}%</span>
                          )}
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>

              {/* Action Buttons for Selected Session */}
              <div className="pt-3 border-t border-slate-100 flex flex-col gap-2">
                {selectedSession.canOpen && (
                  <button
                    type="button"
                    disabled={actionLoading}
                    onClick={() => setConfirmDialog({ open: true, type: 'OPEN', session: selectedSession })}
                    className="w-full h-10 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-sm transition-colors flex items-center justify-center gap-1.5 shadow-sm"
                  >
                    <Play className="w-4 h-4 fill-current" />
                    <span>Mở phiên điểm danh này</span>
                  </button>
                )}

                {selectedSession.status === 'OPEN' && (
                  <button
                    type="button"
                    onClick={() => navigate(`/lecturer/session/qr?sessionId=${selectedSession.id}`)}
                    className="w-full h-10 rounded-lg bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm transition-colors flex items-center justify-center gap-1.5 shadow-sm"
                  >
                    <QrCode className="w-4 h-4" />
                    <span>Chiếu mã QR xoay vòng</span>
                  </button>
                )}

                {selectedSession.canClose && (
                  <button
                    type="button"
                    disabled={actionLoading}
                    onClick={() => setConfirmDialog({ open: true, type: 'CLOSE', session: selectedSession })}
                    className="w-full h-10 rounded-lg bg-red-600 hover:bg-red-700 text-white font-semibold text-sm transition-colors flex items-center justify-center gap-1.5 shadow-sm"
                  >
                    <Lock className="w-4 h-4" />
                    <span>Chốt sổ ca học ngay</span>
                  </button>
                )}

                {selectedSession.status === 'CLOSED' && (
                  <div className="w-full py-2.5 rounded-lg bg-slate-100 text-slate-600 text-center font-medium text-xs">
                    Phiên đã kết thúc và chốt sổ hồ sơ vào {selectedSession.closedAt ? new Date(selectedSession.closedAt).toLocaleTimeString() : ''}
                  </div>
                )}
              </div>
            </>
          ) : (
            <div className="py-20 text-center text-slate-400 text-xs">
              Chọn một phiên trong danh sách để xem chi tiết và giám sát trực tiếp.
            </div>
          )}
        </div>
      </div>

      {/* ============================================================================
          5. MODAL: Create Attendance Session
         ============================================================================ */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-xs p-4 animate-fadeIn">
          <div className="w-full max-w-lg bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden flex flex-col">
            <div className="p-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
              <div className="flex items-center gap-2">
                <PlusCircle className="w-5 h-5 text-blue-600" />
                <h3 className="font-bold text-slate-900 text-base">Khởi tạo phiên điểm danh</h3>
              </div>
              <button
                type="button"
                onClick={() => setShowCreateModal(false)}
                className="w-8 h-8 rounded-lg hover:bg-slate-200 flex items-center justify-center text-slate-500"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-6 flex flex-col gap-4">
              <p className="text-xs text-slate-600 leading-relaxed">
                {isLecturer
                  ? 'Chọn buổi học thuộc lịch giảng dạy của bạn để tạo phiên điểm danh. Hệ thống sẽ liên kết danh sách sinh viên ghi danh và cấu hình kiểm soát ca học.'
                  : 'Chọn buổi học từ thời khóa biểu để tạo phiên điểm danh. ADMIN có thể kích hoạt phiên cho bất kỳ giảng đường nào trong trường.'}
              </p>

              {createModalLoading ? (
                <div className="py-12 flex flex-col items-center justify-center text-slate-400 gap-2">
                  <RefreshCw className="w-6 h-6 animate-spin text-blue-600" />
                  <span className="text-xs">Đang nạp các tiết học hợp lệ...</span>
                </div>
              ) : availableSlots.length === 0 ? (
                <div className="py-8 text-center text-slate-500 bg-amber-50 rounded-xl border border-amber-200 p-4 text-xs">
                  Không tìm thấy tiết học nào đang ở trạng thái SCHEDULED phù hợp. Vui lòng kiểm tra lại thời khóa biểu hoặc học kỳ hiện hành.
                </div>
              ) : (
                <>
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                      Chọn buổi học từ Thời khóa biểu <span className="text-red-500">*</span>
                    </label>
                    <select
                      value={selectedSlotIdForCreate || ''}
                      onChange={(e) => setSelectedSlotIdForCreate(Number(e.target.value))}
                      className="w-full h-11 px-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-800 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      {availableSlots.map((slot) => (
                        <option key={slot.id} value={slot.id}>
                          {slot.className} - {slot.roomCode} | {slot.date} (Tiết {slot.slotNumber}: {slot.startTime?.substring(0, 5)} - {slot.endTime?.substring(0, 5)})
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50 border border-slate-100">
                    <div className="flex flex-col">
                      <span className="font-semibold text-sm text-slate-900">Tự động mở phiên ngay lập tức</span>
                      <span className="text-xs text-slate-500">Chuyển trạng thái sang OPEN ngay khi tạo thành công</span>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={autoOpenOnCreate}
                        onChange={(e) => setAutoOpenOnCreate(e.target.checked)}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600" />
                    </label>
                  </div>
                </>
              )}
            </div>

            <div className="p-4 border-t border-slate-100 bg-slate-50/60 flex items-center justify-end gap-2">
              <button
                type="button"
                onClick={() => setShowCreateModal(false)}
                className="px-4 py-2 rounded-lg border border-slate-200 hover:bg-slate-100 text-slate-700 text-sm font-medium"
              >
                Hủy bỏ
              </button>
              <button
                type="button"
                disabled={actionLoading || !selectedSlotIdForCreate}
                onClick={handleCreateSession}
                className="px-5 py-2 rounded-lg bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold disabled:opacity-50 transition-colors shadow-sm"
              >
                {actionLoading ? 'Đang tạo...' : 'Tạo phiên điểm danh'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ============================================================================
          6. MODAL: Open / Close Confirmation Dialog
         ============================================================================ */}
      {confirmDialog.open && confirmDialog.session && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-xs p-4 animate-fadeIn">
          <div className="w-full max-w-md bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden flex flex-col">
            <div className="p-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
              <div className="flex items-center gap-2">
                {confirmDialog.type === 'OPEN' ? (
                  <Play className="w-5 h-5 text-emerald-600 fill-current" />
                ) : (
                  <Lock className="w-5 h-5 text-red-600" />
                )}
                <h3 className="font-bold text-slate-900 text-base">
                  {confirmDialog.type === 'OPEN' ? 'Xác nhận mở phiên điểm danh' : 'Xác nhận chốt sổ phiên điểm danh'}
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setConfirmDialog({ open: false, type: 'OPEN', session: null })}
                className="w-8 h-8 rounded-lg hover:bg-slate-200 flex items-center justify-center text-slate-500"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-5 text-sm text-slate-600 flex flex-col gap-3">
              {confirmDialog.type === 'OPEN' ? (
                <>
                  <p>
                    Bạn có chắc chắn muốn mở phiên điểm danh <strong>#SES-{confirmDialog.session.id}</strong> cho lớp học{' '}
                    <strong>{confirmDialog.session.className}</strong> tại phòng{' '}
                    <strong>{confirmDialog.session.roomCode}</strong> không?
                  </p>
                  <div className="p-3 bg-emerald-50 text-emerald-800 rounded-lg text-xs leading-relaxed">
                    Sau khi mở, sinh viên sẽ có thể điểm danh qua thiết bị AI Kiosk hoặc Dynamic QR của ca học.
                  </div>
                </>
              ) : (
                <>
                  <p>
                    Bạn có chắc chắn muốn chốt sổ và đóng phiên điểm danh <strong>#SES-{confirmDialog.session.id}</strong>{' '}
                    cho lớp học <strong>{confirmDialog.session.className}</strong> không?
                  </p>
                  <div className="p-3 bg-red-50 text-red-800 rounded-lg text-xs leading-relaxed">
                    Sau khi đóng phiên, sinh viên sẽ không thể check-in thêm. Mọi dữ liệu đã điểm danh sẽ được chốt và lưu lại vĩnh viễn vào nhật ký kiểm toán.
                  </div>
                </>
              )}
            </div>

            <div className="p-4 border-t border-slate-100 bg-slate-50/60 flex items-center justify-end gap-2">
              <button
                type="button"
                onClick={() => setConfirmDialog({ open: false, type: 'OPEN', session: null })}
                className="px-4 py-2 rounded-lg border border-slate-200 hover:bg-slate-100 text-slate-700 text-sm font-medium"
              >
                Hủy bỏ
              </button>
              <button
                type="button"
                disabled={actionLoading}
                onClick={() => {
                  if (confirmDialog.type === 'OPEN') {
                    executeOpenSession(confirmDialog.session!);
                  } else {
                    executeCloseSession(confirmDialog.session!);
                  }
                }}
                className={`px-5 py-2 rounded-lg text-white text-sm font-semibold disabled:opacity-50 transition-colors shadow-sm ${
                  confirmDialog.type === 'OPEN' ? 'bg-emerald-600 hover:bg-emerald-700' : 'bg-red-600 hover:bg-red-700'
                }`}
              >
                {actionLoading ? 'Đang xử lý...' : confirmDialog.type === 'OPEN' ? 'Mở phiên' : 'Chốt sổ'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AttendanceSessionManagementPage;
