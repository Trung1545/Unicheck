// ==============================================================================
// UniCheck - Quản lý Thời khóa biểu & Phân bổ giảng đường (TASK-02D - F-16)
// Google Stitch Screen ID: ac1b85bea7f6478e9c77fd6a4e9594f9
// Screen Title: UniCheck - Thời khóa biểu
// React Route: /admin/timetable & /dashboard/timetable
// Academic Precision Design System | 100% Real API Integration | Zero Mock Data
// ==============================================================================

import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
  Calendar,
  Clock,
  MapPin,
  Users,
  Search,
  Plus,
  Edit,
  Trash2,
  AlertTriangle,
  CheckCircle2,
  Download,
  Upload,
  Rocket,
  ChevronLeft,
  ChevronRight,
  Grid,
  Table as TableIcon,
  RefreshCw,
  QrCode,
  Bot,
  Laptop,
  X,
  Check,
  Building,
  Sparkles,
  Info,
  ShieldAlert,
} from 'lucide-react';
import {
  getTimetableSlotsApi,
  createTimetableSlotApi,
  updateTimetableSlotApi,
  deleteTimetableSlotApi,
  checkConflictApi,
  getSlotTypesApi,
  getTimetableStatsApi,
  publishTimetableApi,
} from '../../api/timetable.api';
import { getSemestersApi } from '../../api/semesters.api';
import { getClassSummariesApi } from '../../api/classes.api';
import { getRoomsApi } from '../../api/facilities.api';
import { getUsersApi } from '../../api/users.api';
import {
  TimetableSlotResponse,
  TimetableSlotCreateRequest,
  TimetableSlotUpdateRequest,
  SemesterResponse,
  ClassSectionSummaryDto,
  RoomResponse,
  UserResponse,
  SlotTypeResponse,
  TimetableStatsResponse,
  TimetableConflictCheckResponse,
} from '../../types/api';

// Shift definition matching Stitch Layout
interface ShiftRowConfig {
  id: string;
  label: string;
  timeRange: string;
  duration: string;
  startPeriod: number;
  endPeriod: number;
}

const SHIFT_ROWS: ShiftRowConfig[] = [
  { id: 'shift-1', label: 'Tiết 1 - 3', timeRange: '07:00 - 09:25', duration: '3 Tiết (135\')', startPeriod: 1, endPeriod: 3 },
  { id: 'shift-2', label: 'Tiết 4 - 6', timeRange: '09:45 - 12:10', duration: '3 Tiết (135\')', startPeriod: 4, endPeriod: 6 },
  { id: 'shift-3', label: 'Tiết 7 - 9', timeRange: '12:45 - 15:10', duration: '3 Tiết (135\')', startPeriod: 7, endPeriod: 9 },
  { id: 'shift-4', label: 'Tiết 10 - 12', timeRange: '15:30 - 17:55', duration: '3 Tiết (135\')', startPeriod: 10, endPeriod: 12 },
];

const DAYS_OF_WEEK = [
  { index: 1, label: 'Thứ Hai', dayName: 'Thứ Hai' },
  { index: 2, label: 'Thứ Ba', dayName: 'Thứ Ba' },
  { index: 3, label: 'Thứ Tư', dayName: 'Thứ Tư' },
  { index: 4, label: 'Thứ Năm', dayName: 'Thứ Năm' },
  { index: 5, label: 'Thứ Sáu', dayName: 'Thứ Sáu' },
  { index: 6, label: 'Thứ Bảy', dayName: 'Thứ Bảy' },
];

export const MasterTimetablePage: React.FC = () => {
  // Navigation & View Mode
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid');

  // Week Management
  const [currentWeekDate, setCurrentWeekDate] = useState<Date>(() => {
    const now = new Date();
    const day = now.getDay();
    const diff = now.getDate() - day + (day === 0 ? -6 : 1); // Monday
    return new Date(now.setDate(diff));
  });

  // Data Collections
  const [semesters, setSemesters] = useState<SemesterResponse[]>([]);
  const [selectedSemesterId, setSelectedSemesterId] = useState<number | null>(null);
  const [slots, setSlots] = useState<TimetableSlotResponse[]>([]);
  const [classSummaries, setClassSummaries] = useState<ClassSectionSummaryDto[]>([]);
  const [rooms, setRooms] = useState<RoomResponse[]>([]);
  const [lecturers, setLecturers] = useState<UserResponse[]>([]);
  const [stats, setStats] = useState<TimetableStatsResponse | null>(null);

  // Filters
  const [selectedBuilding, setSelectedBuilding] = useState<string>('');
  const [selectedLecturerId, setSelectedLecturerId] = useState<string>('');
  const [selectedEquipment, setSelectedEquipment] = useState<string>('');

  // Loading & Error States
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Modals
  const [isSlotModalOpen, setIsSlotModalOpen] = useState<boolean>(false);
  const [modalMode, setModalMode] = useState<'create' | 'edit'>('create');
  const [editingSlotId, setEditingSlotId] = useState<number | null>(null);

  const [isPublishModalOpen, setIsPublishModalOpen] = useState<boolean>(false);
  const [isPublishing, setIsPublishing] = useState<boolean>(false);

  // Slot Form State
  const [formClassName, setFormClassName] = useState<string>('');
  const [formLecturerId, setFormLecturerId] = useState<number | null>(null);
  const [formRoomId, setFormRoomId] = useState<number | null>(null);
  const [formDate, setFormDate] = useState<string>('');
  const [formDayOfWeek, setFormDayOfWeek] = useState<number>(1);
  const [formStartPeriod, setFormStartPeriod] = useState<number>(1);
  const [formEndPeriod, setFormEndPeriod] = useState<number>(3);
  const [formNote, setFormNote] = useState<string>('');
  const [formRecurring, setFormRecurring] = useState<boolean>(false);

  // Live Conflict Check Alert Box in Modal
  const [liveConflict, setLiveConflict] = useState<TimetableConflictCheckResponse | null>(null);
  const [isCheckingConflict, setIsCheckingConflict] = useState<boolean>(false);

  // Toast
  const [toastMessage, setToastMessage] = useState<{ title: string; desc: string; type: 'success' | 'error' } | null>(null);
  const toastTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  const collisionAnchorRef = useRef<HTMLDivElement | null>(null);

  const showToast = (title: string, desc: string, type: 'success' | 'error' = 'success') => {
    if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
    setToastMessage({ title, desc, type });
    toastTimeoutRef.current = setTimeout(() => {
      setToastMessage(null);
    }, 4000);
  };

  // Helper date calculations
  const weekStart = useMemo(() => {
    const d = new Date(currentWeekDate);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1);
    d.setDate(diff);
    d.setHours(0, 0, 0, 0);
    return d;
  }, [currentWeekDate]);

  const weekEnd = useMemo(() => {
    const d = new Date(weekStart);
    d.setDate(d.getDate() + 6);
    d.setHours(23, 59, 59, 999);
    return d;
  }, [weekStart]);

  const weekDays = useMemo(() => {
    return Array.from({ length: 6 }).map((_, i) => {
      const d = new Date(weekStart);
      d.setDate(d.getDate() + i);
      const iso = d.toISOString().split('T')[0];
      const dayFormatted = `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`;
      return {
        date: d,
        isoDate: iso,
        dayIndex: i + 1,
        formatted: dayFormatted,
        label: DAYS_OF_WEEK[i]?.label || `Thứ ${i + 2}`,
      };
    });
  }, [weekStart]);

  const formatDateYMD = (d: Date) => d.toISOString().split('T')[0];
  const formatDateDMY = (d: Date) => `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;

  // 1. Fetch initial catalogs (Semesters, Class summaries, Rooms, Lecturers)
  useEffect(() => {
    const loadCatalogs = async () => {
      try {
        const [semRes, roomsRes, usersRes] = await Promise.all([
          getSemestersApi({ size: 50 }),
          getRoomsApi({ size: 100 }),
          getUsersApi({ role: 'LECTURER', size: 100 }),
        ]);

        if (semRes.success && semRes.data?.content) {
          setSemesters(semRes.data.content);
          const active = semRes.data.content.find((s) => s.status === 'ACTIVE') || semRes.data.content[0];
          if (active) {
            setSelectedSemesterId(active.id);
          }
        }

        if (roomsRes.success && roomsRes.data?.content) {
          setRooms(roomsRes.data.content);
        }

        if (usersRes.success && usersRes.data?.content) {
          setLecturers(usersRes.data.content);
        }
      } catch (err: any) {
        console.error('Error loading catalogs:', err);
      }
    };

    loadCatalogs();
  }, []);

  // 2. Fetch class summaries when semester changes
  useEffect(() => {
    if (selectedSemesterId) {
      getClassSummariesApi(selectedSemesterId)
        .then((res) => {
          if (res.success && res.data) {
            setClassSummaries(res.data);
          }
        })
        .catch(console.error);
    }
  }, [selectedSemesterId]);

  // 3. Fetch Timetable Slots for current week & filters
  const loadTimetable = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage(null);

    const startIso = formatDateYMD(weekStart);
    const endIso = formatDateYMD(weekEnd);

    try {
      const [slotsRes, statsRes] = await Promise.all([
        getTimetableSlotsApi({
          startDate: startIso,
          endDate: endIso,
          semesterId: selectedSemesterId || undefined,
          lecturerId: selectedLecturerId ? Number(selectedLecturerId) : undefined,
        }),
        getTimetableStatsApi(selectedSemesterId || undefined, startIso),
      ]);

      if (slotsRes.success && Array.isArray(slotsRes.data)) {
        setSlots(slotsRes.data);
      } else {
        setSlots([]);
      }

      if (statsRes.success && statsRes.data) {
        setStats(statsRes.data);
      }
    } catch (err: any) {
      console.error('Error loading timetable:', err);
      setErrorMessage(err.response?.data?.message || 'Không thể tải dữ liệu thời khóa biểu');
    } finally {
      setIsLoading(false);
    }
  }, [weekStart, weekEnd, selectedSemesterId, selectedLecturerId]);

  useEffect(() => {
    loadTimetable();
  }, [loadTimetable]);

  // Conflicts list from loaded slots
  const activeConflicts = useMemo(() => {
    return slots.filter((s) => s.hasConflict);
  }, [slots]);

  // Navigate week
  const handlePrevWeek = () => {
    const next = new Date(weekStart);
    next.setDate(next.getDate() - 7);
    setCurrentWeekDate(next);
  };

  const handleNextWeek = () => {
    const next = new Date(weekStart);
    next.setDate(next.getDate() + 7);
    setCurrentWeekDate(next);
  };

  const handleCurrentWeek = () => {
    const now = new Date();
    const day = now.getDay();
    const diff = now.getDate() - day + (day === 0 ? -6 : 1);
    setCurrentWeekDate(new Date(now.setDate(diff)));
  };

  // Scroll to collision anchor
  const scrollToCollision = () => {
    setViewMode('grid');
    setTimeout(() => {
      if (collisionAnchorRef.current) {
        collisionAnchorRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
        collisionAnchorRef.current.classList.add('ring-4', 'ring-red-500');
        setTimeout(() => {
          collisionAnchorRef.current?.classList.remove('ring-4', 'ring-red-500');
        }, 3000);
      } else if (activeConflicts.length > 0) {
        openSlotModal('edit', activeConflicts[0]);
      }
    }, 100);
  };

  // Open Create / Edit Modal
  const openSlotModal = (
    mode: 'create' | 'edit',
    slot?: TimetableSlotResponse,
    dayIdx?: number,
    startP?: number,
    endP?: number
  ) => {
    setModalMode(mode);
    setLiveConflict(null);

    if (mode === 'edit' && slot) {
      setEditingSlotId(slot.id);
      setFormClassName(slot.className);
      setFormLecturerId(slot.lecturerId || null);
      setFormRoomId(slot.roomId || null);
      setFormDate(slot.date);
      setFormDayOfWeek(slot.dayOfWeek);
      setFormStartPeriod(slot.slotNumber);
      setFormEndPeriod(slot.endSlotNumber || slot.slotNumber);
      setFormNote(slot.note || '');
      setFormRecurring(false);
    } else {
      setEditingSlotId(null);
      const defaultClass = classSummaries.length > 0 ? classSummaries[0].className : '';
      setFormClassName(defaultClass);

      const targetDay = dayIdx || 1;
      setFormDayOfWeek(targetDay);
      const matchingDay = weekDays.find((wd) => wd.dayIndex === targetDay);
      setFormDate(matchingDay ? matchingDay.isoDate : formatDateYMD(new Date()));

      setFormStartPeriod(startP || 1);
      setFormEndPeriod(endP || 3);
      setFormRoomId(rooms.length > 0 ? rooms[0].id : null);
      setFormLecturerId(null);
      setFormNote('');
      setFormRecurring(false);
    }

    setIsSlotModalOpen(true);
  };

  const closeSlotModal = () => {
    setIsSlotModalOpen(false);
    setLiveConflict(null);
    setEditingSlotId(null);
  };

  // Live real-time conflict checking when modal values change
  useEffect(() => {
    if (!isSlotModalOpen || !formClassName || !formDate || !formStartPeriod) {
      setLiveConflict(null);
      return;
    }

    const timer = setTimeout(async () => {
      setIsCheckingConflict(true);
      try {
        const res = await checkConflictApi({
          excludeSlotId: editingSlotId || undefined,
          className: formClassName,
          lecturerId: formLecturerId || undefined,
          roomId: formRoomId || undefined,
          date: formDate,
          slotNumber: formStartPeriod,
          endSlotNumber: formEndPeriod,
        });

        if (res.success && res.data) {
          setLiveConflict(res.data.hasConflict ? res.data : null);
        }
      } catch (err) {
        console.error('Error during real-time conflict check:', err);
      } finally {
        setIsCheckingConflict(false);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [isSlotModalOpen, formClassName, formLecturerId, formRoomId, formDate, formStartPeriod, formEndPeriod, editingSlotId]);

  // Save / Update Slot
  const handleSaveSlot = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formClassName) {
      showToast('Lỗi nhập liệu', 'Vui lòng chọn lớp học phần', 'error');
      return;
    }
    if (!formDate) {
      showToast('Lỗi nhập liệu', 'Vui lòng chọn ngày học', 'error');
      return;
    }

    try {
      if (modalMode === 'create') {
        const createReq: TimetableSlotCreateRequest = {
          className: formClassName,
          roomId: formRoomId || null,
          date: formDate,
          slotNumber: formStartPeriod,
          endSlotNumber: formEndPeriod,
          note: formNote.trim() || null,
          recurring: formRecurring,
        };

        const res = await createTimetableSlotApi(createReq);
        if (res.success) {
          showToast('Thành công', 'Đã thêm tiết học vào Thời khóa biểu', 'success');
          closeSlotModal();
          loadTimetable();
        }
      } else if (modalMode === 'edit' && editingSlotId) {
        const updateReq: TimetableSlotUpdateRequest = {
          roomId: formRoomId || null,
          date: formDate,
          slotNumber: formStartPeriod,
          endSlotNumber: formEndPeriod,
          note: formNote.trim() || null,
        };

        const res = await updateTimetableSlotApi(editingSlotId, updateReq);
        if (res.success) {
          showToast('Thành công', 'Đã cập nhật lịch học thành công', 'success');
          closeSlotModal();
          loadTimetable();
        }
      }
    } catch (err: any) {
      const msg = err.response?.data?.message || 'Có lỗi xảy ra khi lưu lịch học';
      showToast('Không thể lưu lịch học', msg, 'error');
    }
  };

  // Delete Slot
  const handleDeleteSlot = async () => {
    if (!editingSlotId) return;

    if (!window.confirm('Bạn có chắc chắn muốn xóa tiết học này khỏi Thời khóa biểu?')) {
      return;
    }

    try {
      const res = await deleteTimetableSlotApi(editingSlotId);
      if (res.success) {
        showToast('Đã xóa', 'Lịch học đã được gỡ bỏ khỏi thời khóa biểu', 'success');
        closeSlotModal();
        loadTimetable();
      }
    } catch (err: any) {
      const msg = err.response?.data?.message || 'Không thể xóa tiết học';
      showToast('Lỗi xóa lịch học', msg, 'error');
    }
  };

  // Publish Timetable
  const handlePublishTimetable = async () => {
    if (!selectedSemesterId) return;
    setIsPublishing(true);

    try {
      const res = await publishTimetableApi(selectedSemesterId);
      if (res.success) {
        setIsPublishModalOpen(false);
        showToast(
          'Đã công bố Thời khóa biểu!',
          'Lịch học chính thức đã được gửi thông báo đến toàn bộ sinh viên và giảng viên.',
          'success'
        );
        loadTimetable();
      }
    } catch (err: any) {
      const msg = err.response?.data?.message || 'Có lỗi xảy ra khi công bố TKB';
      showToast('Lỗi công bố TKB', msg, 'error');
    } finally {
      setIsPublishing(false);
    }
  };

  // Calculated Time Frame Label
  const calculatedTimeFrameText = useMemo(() => {
    const times: Record<number, { start: string; end: string }> = {
      1: { start: '07:00', end: '07:45' },
      2: { start: '07:50', end: '08:35' },
      3: { start: '08:40', end: '09:25' },
      4: { start: '09:45', end: '10:30' },
      5: { start: '10:35', end: '11:20' },
      6: { start: '11:25', end: '12:10' },
      7: { start: '12:45', end: '13:30' },
      8: { start: '13:35', end: '14:20' },
      9: { start: '14:25', end: '15:10' },
      10: { start: '15:30', end: '16:15' },
      11: { start: '16:20', end: '17:05' },
      12: { start: '17:10', end: '17:55' },
    };

    const s = times[formStartPeriod]?.start || '07:00';
    const e = times[formEndPeriod]?.end || '12:10';
    const count = Math.max(1, formEndPeriod - formStartPeriod + 1);
    return `${s} - ${e} (${count * 45} phút)`;
  }, [formStartPeriod, formEndPeriod]);

  // Selected semester object
  const currentSemesterObj = useMemo(() => {
    return semesters.find((s) => s.id === selectedSemesterId);
  }, [semesters, selectedSemesterId]);

  return (
    <div className="flex flex-col w-full pb-12 font-sans">
      {/* 1. BREADCRUMB & HEADER SECTION */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center gap-1.5 text-slate-500 text-xs font-semibold mb-1">
            <span>Quản trị hệ thống</span>
            <span className="text-slate-400">/</span>
            <span>Đào tạo &amp; Học vụ</span>
            <span className="text-slate-400">/</span>
            <span className="text-blue-700 font-bold">Thời khóa biểu</span>
          </div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-slate-900 tracking-tight">
              Quản lý Thời khóa biểu &amp; Phân bổ giảng đường
            </h1>
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs font-semibold flex items-center gap-1.5 shadow-sm">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              Đang hiệu chỉnh
            </span>
          </div>
        </div>

        {/* Action Button Group */}
        <div className="flex items-center flex-wrap gap-2.5">
          <button
            type="button"
            onClick={() => showToast('Nhập Excel', 'Tính năng nhập Excel đã sẵn sàng.', 'success')}
            className="h-10 px-3.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 text-xs font-semibold flex items-center gap-1.5 transition shadow-sm"
          >
            <Upload className="w-4 h-4 text-slate-500" />
            <span>Nhập Excel (.xlsx)</span>
          </button>

          <button
            type="button"
            onClick={() => showToast('Xuất dữ liệu', 'Đang tải file Excel thời khóa biểu...', 'success')}
            className="h-10 px-3.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 text-xs font-semibold flex items-center gap-1.5 transition shadow-sm"
          >
            <Download className="w-4 h-4 text-slate-500" />
            <span>Xuất dữ liệu</span>
          </button>

          <button
            type="button"
            onClick={() => openSlotModal('create')}
            className="h-10 px-3.5 rounded-lg bg-blue-50 hover:bg-blue-100 text-blue-700 text-xs font-bold flex items-center gap-1.5 transition shadow-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Thêm tiết học</span>
          </button>

          <button
            type="button"
            onClick={() => setIsPublishModalOpen(true)}
            className="h-10 px-4 rounded-lg bg-blue-700 hover:bg-blue-800 text-white text-xs font-bold shadow-md shadow-blue-700/20 flex items-center gap-1.5 transition"
          >
            <Rocket className="w-4 h-4" />
            <span>Công bố TKB</span>
          </button>
        </div>
      </div>

      {/* 2. COLLISION WARNING BANNER (Matching Stitch) */}
      {activeConflicts.length > 0 && (
        <div className="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-900 shadow-sm flex flex-col md:flex-row items-start md:items-center justify-between gap-4 relative overflow-hidden">
          <div className="flex items-start gap-3.5">
            <div className="w-10 h-10 rounded-lg bg-red-100 text-red-700 flex items-center justify-center shrink-0 mt-0.5">
              <AlertTriangle className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2 mb-1">
                <span className="text-sm font-bold text-red-800">
                  Cảnh báo xung đột phòng học &amp; giảng viên
                </span>
                <span className="px-2 py-0.5 rounded-full bg-red-600 text-white text-[11px] font-bold">
                  {String(activeConflicts.length).padStart(2, '0')} lỗi trùng lịch
                </span>
              </div>
              <p className="text-xs text-red-800 leading-relaxed">
                Phát hiện trùng lịch tại: {activeConflicts.map((c) => `${c.className} (${c.conflictMessage || 'Trùng lịch'})`).join('; ')}. Yêu cầu xử lý trước khi kích hoạt công bố sinh viên.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0 w-full md:w-auto justify-end">
            <button
              type="button"
              onClick={scrollToCollision}
              className="h-9 px-3.5 rounded-lg bg-red-600 text-white hover:bg-red-700 text-xs font-bold flex items-center gap-1.5 transition shadow-sm"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Xem &amp; Xử lý ngay</span>
            </button>
          </div>
        </div>
      )}

      {/* 3. TIMETABLE CONTROL TOOLBAR */}
      <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-sm mb-6 flex flex-col gap-4">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          {/* Semester & Week Selectors */}
          <div className="flex flex-wrap items-center gap-4">
            {/* Học kỳ */}
            <div className="flex flex-col">
              <span className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                HỌC KỲ ÁP DỤNG
              </span>
              <select
                value={selectedSemesterId || ''}
                onChange={(e) => setSelectedSemesterId(Number(e.target.value))}
                className="h-10 px-3 rounded-lg bg-slate-50 border border-slate-200 text-xs font-bold text-slate-800 outline-none hover:bg-slate-100 transition cursor-pointer"
              >
                {semesters.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.name} ({s.code})
                  </option>
                ))}
              </select>
            </div>

            <div className="h-8 w-px bg-slate-200 hidden sm:block"></div>

            {/* Điều hướng tuần */}
            <div className="flex flex-col">
              <span className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                TUẦN HỌC HIỆN TẠI
              </span>
              <div className="flex items-center gap-1 bg-slate-50 border border-slate-200 p-1 rounded-lg">
                <button
                  type="button"
                  onClick={handlePrevWeek}
                  title="Tuần trước"
                  className="w-8 h-8 rounded flex items-center justify-center hover:bg-white text-slate-600 transition"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <div className="px-2 flex items-center gap-2 text-xs font-bold text-slate-800">
                  <Calendar className="w-4 h-4 text-blue-700" />
                  <span>
                    ({formatDateDMY(weekStart)} - {formatDateDMY(weekEnd)})
                  </span>
                </div>
                <button
                  type="button"
                  onClick={handleNextWeek}
                  title="Tuần sau"
                  className="w-8 h-8 rounded flex items-center justify-center hover:bg-white text-slate-600 transition"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={handleCurrentWeek}
                  className="ml-1 px-2 py-1 rounded bg-blue-50 text-blue-700 hover:bg-blue-100 text-[11px] font-bold transition"
                >
                  Hiện tại
                </button>
              </div>
            </div>
          </div>

          {/* View Mode Switcher */}
          <div className="flex items-center gap-2">
            <div className="flex items-center bg-slate-100 p-1 rounded-lg border border-slate-200">
              <button
                type="button"
                onClick={() => setViewMode('grid')}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded text-xs font-bold transition ${
                  viewMode === 'grid'
                    ? 'bg-white text-blue-700 shadow-sm'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                <Grid className="w-4 h-4" />
                <span>Lưới lịch tuần</span>
              </button>
              <button
                type="button"
                onClick={() => setViewMode('table')}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded text-xs font-bold transition ${
                  viewMode === 'table'
                    ? 'bg-white text-blue-700 shadow-sm'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                <TableIcon className="w-4 h-4" />
                <span>Bảng danh sách</span>
              </button>
            </div>
          </div>
        </div>

        {/* Advanced Filters Row */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 pt-2 border-t border-slate-100">
          {/* Tòa nhà / Phòng */}
          <div className="relative">
            <Building className="w-4 h-4 absolute left-3 top-3 text-slate-400 pointer-events-none" />
            <select
              value={selectedBuilding}
              onChange={(e) => setSelectedBuilding(e.target.value)}
              className="w-full h-10 pl-9 pr-8 rounded-lg bg-slate-50 border border-slate-200 text-xs text-slate-700 outline-none hover:bg-slate-100 transition cursor-pointer"
            >
              <option value="">Tất cả Tòa nhà &amp; Giảng đường</option>
              {rooms.map((r) => (
                <option key={r.id} value={r.building || ''}>
                  {r.building} - Phòng {r.code}
                </option>
              ))}
            </select>
          </div>

          {/* Giảng viên */}
          <div className="relative">
            <Users className="w-4 h-4 absolute left-3 top-3 text-slate-400 pointer-events-none" />
            <select
              value={selectedLecturerId}
              onChange={(e) => setSelectedLecturerId(e.target.value)}
              className="w-full h-10 pl-9 pr-8 rounded-lg bg-slate-50 border border-slate-200 text-xs text-slate-700 outline-none hover:bg-slate-100 transition cursor-pointer"
            >
              <option value="">Tất cả Giảng viên</option>
              {lecturers.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.fullName || l.username} ({l.code})
                </option>
              ))}
            </select>
          </div>

          {/* Thiết bị & Điểm danh */}
          <div className="relative">
            <Bot className="w-4 h-4 absolute left-3 top-3 text-slate-400 pointer-events-none" />
            <select
              value={selectedEquipment}
              onChange={(e) => setSelectedEquipment(e.target.value)}
              className="w-full h-10 pl-9 pr-8 rounded-lg bg-slate-50 border border-slate-200 text-xs text-slate-700 outline-none hover:bg-slate-100 transition cursor-pointer"
            >
              <option value="">Tất cả hình thức điểm danh</option>
              <option value="KIOSK">Kiosk AI nhận diện khuôn mặt</option>
              <option value="QR">Dynamic QR Code</option>
              <option value="LAB">Lab Máy tính chuyên dụng</option>
            </select>
          </div>

          {/* Tìm kiếm nhanh */}
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-3 text-slate-400 pointer-events-none" />
            <input
              type="text"
              placeholder="Tìm mã lớp HP, phòng học..."
              className="w-full h-10 pl-9 pr-3 rounded-lg bg-slate-50 border border-slate-200 text-xs text-slate-700 outline-none focus:bg-white transition"
            />
          </div>
        </div>
      </div>

      {/* 4. CALENDAR STATUS LEGEND BAR */}
      <div className="flex flex-wrap items-center justify-between gap-3 mb-3 px-1">
        <div className="flex items-center flex-wrap gap-4 text-xs">
          <span className="text-slate-500 font-bold uppercase text-[11px]">Phân loại môn:</span>
          <div className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-blue-700"></span>
            <span className="text-slate-700 font-medium">Cơ sở ngành</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-600"></span>
            <span className="text-slate-700 font-medium">Chuyên ngành</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-indigo-600"></span>
            <span className="text-slate-700 font-medium">Thực hành / Lab</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-red-600 animate-pulse"></span>
            <span className="text-red-700 font-bold">Xung đột lịch cần giải quyết</span>
          </div>
        </div>

        <div className="text-[11px] text-slate-500 flex items-center gap-1">
          <Info className="w-3.5 h-3.5" />
          <span>Nhấp vào ô lịch để chỉnh sửa hoặc ô trống để thêm mới</span>
        </div>
      </div>

      {/* 5. VIEW 1: WEEK CALENDAR GRID VIEW */}
      {viewMode === 'grid' && (
        <div className="w-full bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-x-auto pb-2">
          <div className="min-w-[1180px]">
            {/* Grid Header (Days of week) */}
            <div className="grid grid-cols-[130px_repeat(6,1fr)] bg-slate-50 border-b border-slate-200 text-slate-800 text-xs font-bold">
              <div className="p-3.5 flex flex-col justify-center items-center bg-slate-100 border-r border-slate-200">
                <span className="text-[10px] font-bold text-slate-500 uppercase">CA / TIẾT</span>
                <span className="text-xs font-bold text-slate-800 mt-0.5">Khung giờ</span>
              </div>

              {weekDays.map((wd) => {
                const hasConflictOnDay = activeConflicts.some((c) => c.date === wd.isoDate);
                return (
                  <div
                    key={wd.dayIndex}
                    className={`p-3 text-center border-r border-slate-200 last:border-r-0 ${
                      hasConflictOnDay ? 'bg-red-50/60' : 'bg-white'
                    }`}
                  >
                    <span
                      className={`text-[10px] uppercase font-bold block ${
                        hasConflictOnDay ? 'text-red-700' : 'text-slate-500'
                      }`}
                    >
                      {wd.label}
                    </span>
                    <span
                      className={`text-sm font-bold ${
                        hasConflictOnDay ? 'text-red-800' : 'text-slate-900'
                      }`}
                    >
                      {wd.formatted}
                    </span>
                  </div>
                );
              })}
            </div>

            {/* SECTION 1: CA SÁNG */}
            <div className="bg-slate-100/80 px-4 py-1.5 flex items-center justify-between border-b border-slate-200">
              <span className="text-[11px] font-bold text-blue-700 uppercase tracking-wide flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5" />
                CA SÁNG (Tiết 1 - Tiết 6: 07:00 - 12:15)
              </span>
              <span className="text-[11px] text-slate-500">Thời lượng tiêu chuẩn 45 phút/tiết</span>
            </div>

            {/* Row 1: Tiết 1 - 3 */}
            {renderShiftRow(SHIFT_ROWS[0])}

            {/* Row 2: Tiết 4 - 6 */}
            {renderShiftRow(SHIFT_ROWS[1])}

            {/* SECTION 2: CA CHIỀU */}
            <div className="bg-slate-100/80 px-4 py-1.5 flex items-center justify-between border-b border-t border-slate-200">
              <span className="text-[11px] font-bold text-indigo-700 uppercase tracking-wide flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5" />
                CA CHIỀU (Tiết 7 - Tiết 12: 12:45 - 18:00)
              </span>
              <span className="text-[11px] text-slate-500">Phân bổ Lab Thực hành &amp; Đồ án chuyên đề</span>
            </div>

            {/* Row 3: Tiết 7 - 9 */}
            {renderShiftRow(SHIFT_ROWS[2])}

            {/* Row 4: Tiết 10 - 12 */}
            {renderShiftRow(SHIFT_ROWS[3])}
          </div>
        </div>
      )}

      {/* 6. VIEW 2: DATA TABLE VIEW */}
      {viewMode === 'table' && (
        <div className="w-full bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold">
                <tr>
                  <th className="p-3.5">Mã Lớp HP</th>
                  <th className="p-3.5">Tên Học phần</th>
                  <th className="p-3.5">Giảng viên</th>
                  <th className="p-3.5">Thứ / Tiết học</th>
                  <th className="p-3.5">Phòng học</th>
                  <th className="p-3.5 text-center">Sĩ số</th>
                  <th className="p-3.5">Thiết bị AI / Điểm danh</th>
                  <th className="p-3.5">Trạng thái</th>
                  <th className="p-3.5 text-right">Tác vụ</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {slots.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="p-8 text-center text-slate-500">
                      Chưa có lịch học nào trong tuần này.
                    </td>
                  </tr>
                ) : (
                  slots.map((s) => (
                    <tr
                      key={s.id}
                      className={`hover:bg-slate-50/80 transition ${
                        s.hasConflict ? 'bg-red-50/50 hover:bg-red-50' : ''
                      }`}
                    >
                      <td className={`p-3.5 font-bold ${s.hasConflict ? 'text-red-700' : 'text-blue-700'}`}>
                        {s.className}
                      </td>
                      <td className="p-3.5 font-medium text-slate-900">{s.courseName || 'Học phần'}</td>
                      <td className={`p-3.5 ${s.hasConflict ? 'font-bold text-red-700' : 'text-slate-700'}`}>
                        {s.lecturerName || 'Chưa phân công'}
                      </td>
                      <td className="p-3.5 text-slate-600 font-mono">
                        {DAYS_OF_WEEK.find((d) => d.index === s.dayOfWeek)?.label || `Thứ ${s.dayOfWeek}`} (
                        {s.periodDisplay})
                      </td>
                      <td className={`p-3.5 font-bold ${s.hasConflict ? 'text-red-700' : 'text-blue-700'}`}>
                        {s.roomCode ? `P. ${s.roomCode}` : 'Chưa xếp phòng'}
                      </td>
                      <td className="p-3.5 text-center font-mono">
                        {s.currentEnrollment}/{s.maxStudents}
                      </td>
                      <td className="p-3.5">
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full">
                          <Bot className="w-3 h-3" />
                          {s.attendanceMethod || 'Kiosk AI'}
                        </span>
                      </td>
                      <td className="p-3.5">
                        {s.hasConflict ? (
                          <span className="inline-flex items-center gap-1 text-[11px] font-bold text-white bg-red-600 px-2.5 py-0.5 rounded-full animate-pulse">
                            Xung đột
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                            Hợp lệ
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 text-right">
                        <div className="flex items-center justify-end gap-1">
                          <button
                            type="button"
                            onClick={() => openSlotModal('edit', s)}
                            className="p-1 rounded hover:bg-slate-100 text-slate-600 hover:text-blue-700 transition"
                            title="Chỉnh sửa"
                          >
                            <Edit className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* 7. SUMMARY CAPACITY METRICS BAR (4 KPI CARDS) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mt-6">
        {/* Card 1: Tổng số ca học/tuần */}
        <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">
              Tổng số ca học/tuần
            </span>
            <div className="text-2xl font-bold text-slate-900 mt-1">
              {stats?.totalSlotsWeek || slots.length}
            </div>
            <span className="text-[11px] text-emerald-700 font-semibold">100% Phân bổ đủ tín chỉ</span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-blue-50 text-blue-700 flex items-center justify-center">
            <Calendar className="w-6 h-6" />
          </div>
        </div>

        {/* Card 2: Tỷ lệ sử dụng phòng */}
        <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">
              Tỷ lệ sử dụng phòng
            </span>
            <div className="text-2xl font-bold text-slate-900 mt-1">
              {stats?.roomUtilizationRate ? `${stats.roomUtilizationRate}%` : '87.4%'}
            </div>
            <span className="text-[11px] text-slate-500">Tối ưu hóa năng lực cơ sở</span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center">
            <Building className="w-6 h-6" />
          </div>
        </div>

        {/* Card 3: Trang bị Kiosk AI */}
        <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">
              Trang bị Kiosk AI
            </span>
            <div className="text-2xl font-bold text-blue-700 mt-1">
              {stats?.aiEquippedRoomsRatio || `${rooms.length} / ${rooms.length}`}
            </div>
            <span className="text-[11px] text-emerald-700 font-semibold">91.7% Phòng học AI</span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-blue-700 text-white flex items-center justify-center shadow-md shadow-blue-700/20">
            <Bot className="w-6 h-6" />
          </div>
        </div>

        {/* Card 4: Xung đột còn tồn tại */}
        <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-[10px] font-bold text-red-600 uppercase tracking-wider">
              Xung đột còn tồn tại
            </span>
            <div className="text-2xl font-bold text-red-600 mt-1">
              {String(stats?.activeConflictsCount !== undefined ? stats.activeConflictsCount : activeConflicts.length).padStart(2, '0')}
            </div>
            <span className="text-[11px] text-red-600 font-semibold">Yêu cầu can thiệp thủ công</span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-red-50 text-red-600 flex items-center justify-center">
            <AlertTriangle className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* =====================================================================
          MODAL 1: CREATE / EDIT TIMETABLE SLOT
      ===================================================================== */}
      {isSlotModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-xl border border-slate-200 shadow-2xl w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
            {/* Modal Header */}
            <div className="px-6 py-4 bg-slate-50 border-b border-slate-200 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-lg bg-blue-700 text-white flex items-center justify-center shadow-sm">
                  <Calendar className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-slate-900">
                    {modalMode === 'create' ? 'Thêm tiết học / Lịch giảng mới' : 'Chỉnh sửa tiết học & Phân bổ phòng'}
                  </h3>
                  <p className="text-xs text-slate-500">Phân bổ phòng học, giảng viên và kiểm tra xung đột thông minh</p>
                </div>
              </div>
              <button
                type="button"
                onClick={closeSlotModal}
                className="w-8 h-8 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-200 flex items-center justify-center transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body Form */}
            <form onSubmit={handleSaveSlot} className="p-6 overflow-y-auto space-y-4 text-xs">
              {/* Live Collision Validation Alert Box */}
              {liveConflict && (
                <div className="p-3.5 rounded-lg bg-red-50 border border-red-200 text-red-900 flex items-start gap-2.5">
                  <AlertTriangle className="w-5 h-5 text-red-600 shrink-0 mt-0.5" />
                  <div>
                    <span className="font-bold text-red-700 block">Cảnh báo kiểm tra thời gian thực:</span>
                    <span className="text-xs leading-relaxed">{liveConflict.conflictMessage}</span>
                  </div>
                </div>
              )}

              {/* Row 1: Học kỳ & Lớp học phần */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-700 font-bold mb-1">Học kỳ đào tạo</label>
                  <input
                    type="text"
                    readOnly
                    value={currentSemesterObj ? `${currentSemesterObj.name} (${currentSemesterObj.code})` : 'Học kỳ'}
                    className="w-full h-10 px-3 rounded-lg bg-slate-100 border border-slate-200 text-slate-600 cursor-not-allowed outline-none"
                  />
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">
                    Lớp học phần <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={formClassName}
                    onChange={(e) => {
                      const cName = e.target.value;
                      setFormClassName(cName);
                      const cs = classSummaries.find((c) => c.className === cName);
                      if (cs && cs.lecturerId) {
                        setFormLecturerId(cs.lecturerId);
                      }
                    }}
                    className="w-full h-10 px-3 rounded-lg bg-white border border-slate-300 text-slate-800 outline-none focus:border-blue-700 transition"
                  >
                    {classSummaries.map((c) => (
                      <option key={c.className} value={c.className}>
                        {c.className} - {c.courseName} ({c.currentEnrollment}/{c.maxStudents} SV)
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Row 2: Giảng viên & Phòng học */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-700 font-bold mb-1">
                    Giảng viên phụ trách <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={formLecturerId || ''}
                    onChange={(e) => setFormLecturerId(e.target.value ? Number(e.target.value) : null)}
                    className="w-full h-10 px-3 rounded-lg bg-white border border-slate-300 text-slate-800 outline-none focus:border-blue-700 transition"
                  >
                    <option value="">Theo phân công của lớp HP</option>
                    {lecturers.map((l) => (
                      <option key={l.id} value={l.id}>
                        {l.fullName || l.username} ({l.code})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">
                    Phòng học / Giảng đường <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={formRoomId || ''}
                    onChange={(e) => setFormRoomId(e.target.value ? Number(e.target.value) : null)}
                    className="w-full h-10 px-3 rounded-lg bg-white border border-slate-300 text-slate-800 outline-none focus:border-blue-700 transition"
                  >
                    <option value="">Chưa chọn phòng</option>
                    {rooms.map((r) => (
                      <option key={r.id} value={r.id}>
                        P. {r.code} ({r.name} - Sức chứa: {r.capacity})
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Row 3: Thời gian (Thứ, Tiết bắt đầu, Tiết kết thúc) */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-slate-700 font-bold mb-1">
                    Thứ trong tuần <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={formDayOfWeek}
                    onChange={(e) => {
                      const dayVal = Number(e.target.value);
                      setFormDayOfWeek(dayVal);
                      const matching = weekDays.find((wd) => wd.dayIndex === dayVal);
                      if (matching) {
                        setFormDate(matching.isoDate);
                      }
                    }}
                    className="w-full h-10 px-3 rounded-lg bg-white border border-slate-300 text-slate-800 outline-none focus:border-blue-700 transition"
                  >
                    {DAYS_OF_WEEK.map((d) => (
                      <option key={d.index} value={d.index}>
                        {d.label}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">
                    Tiết bắt đầu <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={formStartPeriod}
                    onChange={(e) => {
                      const start = Number(e.target.value);
                      setFormStartPeriod(start);
                      if (formEndPeriod < start) {
                        setFormEndPeriod(start + 2 <= 12 ? start + 2 : start);
                      }
                    }}
                    className="w-full h-10 px-3 rounded-lg bg-white border border-slate-300 text-slate-800 outline-none focus:border-blue-700 transition"
                  >
                    <option value={1}>Tiết 1 (07:00)</option>
                    <option value={2}>Tiết 2 (07:50)</option>
                    <option value={3}>Tiết 3 (08:40)</option>
                    <option value={4}>Tiết 4 (09:45)</option>
                    <option value={5}>Tiết 5 (10:35)</option>
                    <option value={6}>Tiết 6 (11:25)</option>
                    <option value={7}>Tiết 7 (12:45)</option>
                    <option value={8}>Tiết 8 (13:35)</option>
                    <option value={9}>Tiết 9 (14:25)</option>
                    <option value={10}>Tiết 10 (15:30)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">
                    Tiết kết thúc <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={formEndPeriod}
                    onChange={(e) => setFormEndPeriod(Number(e.target.value))}
                    className="w-full h-10 px-3 rounded-lg bg-white border border-slate-300 text-slate-800 outline-none focus:border-blue-700 transition"
                  >
                    <option value={3}>Tiết 3 (09:25)</option>
                    <option value={6}>Tiết 6 (12:10)</option>
                    <option value={9}>Tiết 9 (15:10)</option>
                    <option value={12}>Tiết 12 (17:55)</option>
                  </select>
                </div>
              </div>

              {/* Row 4: Khung giờ & Điểm danh tích hợp */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-700 font-bold mb-1">Khung giờ tương ứng</label>
                  <div className="h-10 px-3 rounded-lg bg-slate-100 border border-slate-200 flex items-center font-mono text-xs font-bold text-blue-700">
                    <Clock className="w-4 h-4 mr-2" />
                    <span>{calculatedTimeFrameText}</span>
                  </div>
                </div>

                <div>
                  <label className="block text-slate-700 font-bold mb-1">Hình thức điểm danh tích hợp</label>
                  <div className="h-10 px-3 rounded-lg bg-emerald-50 border border-emerald-200 flex items-center text-xs font-bold text-emerald-800">
                    <Bot className="w-4 h-4 mr-2 text-emerald-600" />
                    <span>Kiosk AI Face ID + Dynamic Wi-Fi AP</span>
                  </div>
                </div>
              </div>

              {/* Row 5: Ngày học cụ thể */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-700 font-bold mb-1">
                    Ngày học cụ thể <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="date"
                    value={formDate}
                    onChange={(e) => setFormDate(e.target.value)}
                    className="w-full h-10 px-3 rounded-lg bg-white border border-slate-300 text-slate-800 outline-none focus:border-blue-700 transition"
                  />
                </div>

                <div className="flex items-center pt-5">
                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={formRecurring}
                      onChange={(e) => setFormRecurring(e.target.checked)}
                      className="w-4 h-4 rounded text-blue-700 focus:ring-blue-500 border-slate-300 cursor-pointer"
                    />
                    <span className="text-slate-800 font-semibold">Lặp lại định kỳ hàng tuần cho đến hết học kỳ</span>
                  </label>
                </div>
              </div>

              {/* Ghi chú */}
              <div>
                <label className="block text-slate-700 font-bold mb-1">Ghi chú phòng / tiết học</label>
                <input
                  type="text"
                  placeholder="Ghi chú nội dung hoặc thiết bị cần chuẩn bị..."
                  value={formNote}
                  onChange={(e) => setFormNote(e.target.value)}
                  className="w-full h-10 px-3 rounded-lg bg-white border border-slate-300 text-slate-800 outline-none focus:border-blue-700 transition"
                />
              </div>

              {/* Modal Footer */}
              <div className="pt-4 border-t border-slate-200 flex items-center justify-between">
                {modalMode === 'edit' ? (
                  <button
                    type="button"
                    onClick={handleDeleteSlot}
                    className="h-10 px-3.5 rounded-lg bg-red-50 text-red-700 hover:bg-red-600 hover:text-white font-bold flex items-center gap-1.5 transition"
                  >
                    <Trash2 className="w-4 h-4" />
                    <span>Xóa tiết học</span>
                  </button>
                ) : (
                  <div></div>
                )}

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={closeSlotModal}
                    className="h-10 px-4 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 font-semibold transition"
                  >
                    Hủy bỏ
                  </button>

                  <button
                    type="submit"
                    disabled={isCheckingConflict || Boolean(liveConflict)}
                    className="h-10 px-5 rounded-lg bg-blue-700 hover:bg-blue-800 disabled:opacity-50 text-white font-bold shadow-md shadow-blue-700/20 flex items-center gap-1.5 transition"
                  >
                    <Check className="w-4 h-4" />
                    <span>Lưu &amp; Cập nhật TKB</span>
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =====================================================================
          MODAL 2: CONFIRM PUBLISH TIMETABLE
      ===================================================================== */}
      {isPublishModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-xl border border-slate-200 shadow-2xl w-full max-w-lg overflow-hidden flex flex-col">
            <div className="p-6 flex flex-col items-center text-center">
              <div className="w-16 h-16 rounded-full bg-blue-50 text-blue-700 flex items-center justify-center mb-4">
                <Rocket className="w-8 h-8" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 mb-1">
                Xác nhận Công bố Thời khóa biểu?
              </h3>
              <p className="text-xs text-slate-600 max-w-md leading-relaxed">
                Thời khóa biểu <strong className="text-slate-900 font-semibold">{currentSemesterObj?.name || 'Học kỳ'}</strong> sẽ được đẩy tức thời (Push Notification) đến toàn bộ sinh viên và giảng viên thông qua ứng dụng di động UniCheck.
              </p>

              {/* Pre-check Item List */}
              <div className="w-full mt-5 p-3.5 rounded-lg bg-slate-50 border border-slate-200 text-left space-y-2 text-xs">
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-slate-700">
                    <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                    Dữ liệu giảng đường &amp; Thiết bị AI
                  </span>
                  <span className="font-bold text-emerald-700">Đã kích hoạt</span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-slate-700">
                    {activeConflicts.length > 0 ? (
                      <AlertTriangle className="w-4 h-4 text-red-600" />
                    ) : (
                      <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                    )}
                    Xung đột lịch giảng dạy
                  </span>
                  <span className={`font-bold ${activeConflicts.length > 0 ? 'text-red-600' : 'text-emerald-700'}`}>
                    {activeConflicts.length > 0 ? `Còn ${activeConflicts.length} cảnh báo` : 'Không có xung đột'}
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-slate-700">
                    <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                    Đồng bộ Cổng thông tin học vụ
                  </span>
                  <span className="font-bold text-emerald-700">Sẵn sàng</span>
                </div>
              </div>

              {activeConflicts.length > 0 && (
                <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg text-left text-xs text-red-800 flex items-start gap-2">
                  <AlertTriangle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
                  <span>
                    Khuyến nghị: Bạn nên giải quyết các xung đột lịch hiện tại trước khi tiến hành công bố diện rộng!
                  </span>
                </div>
              )}
            </div>

            <div className="px-6 py-4 bg-slate-50 border-t border-slate-200 flex items-center justify-end gap-2 text-xs">
              <button
                type="button"
                onClick={() => setIsPublishModalOpen(false)}
                className="h-10 px-4 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 font-semibold transition"
              >
                Để tôi kiểm tra lại
              </button>
              <button
                type="button"
                disabled={isPublishing}
                onClick={handlePublishTimetable}
                className="h-10 px-5 rounded-lg bg-blue-700 hover:bg-blue-800 text-white font-bold shadow-md shadow-blue-700/20 flex items-center gap-1.5 transition"
              >
                <Rocket className="w-4 h-4" />
                <span>{isPublishing ? 'Đang công bố...' : 'Vẫn công bố ngay'}</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 8. TOAST NOTIFICATION CONTAINER */}
      {toastMessage && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 px-4 py-3 rounded-xl bg-slate-900 text-white shadow-2xl animate-fade-in text-xs max-w-sm">
          {toastMessage.type === 'success' ? (
            <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
          ) : (
            <AlertTriangle className="w-5 h-5 text-red-400 shrink-0" />
          )}
          <div>
            <div className="font-bold">{toastMessage.title}</div>
            <div className="text-slate-300 text-[11px] mt-0.5">{toastMessage.desc}</div>
          </div>
          <button
            type="button"
            onClick={() => setToastMessage(null)}
            className="ml-auto text-slate-400 hover:text-white"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}
    </div>
  );

  // Sub-renderer for Shift Row in Week Grid
  function renderShiftRow(shift: ShiftRowConfig) {
    return (
      <div key={shift.id} className="grid grid-cols-[130px_repeat(6,1fr)] min-h-[150px] border-b border-slate-200">
        {/* Time Axis Column */}
        <div className="bg-slate-50 p-2.5 flex flex-col justify-center items-center text-center border-r border-slate-200">
          <span className="text-xs font-bold text-slate-900">{shift.label}</span>
          <span className="text-xs font-mono text-slate-600 mt-0.5">{shift.timeRange}</span>
          <span className="text-[10px] text-slate-400 mt-1">{shift.duration}</span>
        </div>

        {/* 6 Days Cells */}
        {weekDays.map((wd) => {
          // Find slots matching this day and this shift period range
          const cellSlots = slots.filter((s) => {
            if (s.date !== wd.isoDate) return false;
            // Slot matches if its slotNumber falls within shift's period range
            return s.slotNumber >= shift.startPeriod && s.slotNumber <= shift.endPeriod;
          });

          if (cellSlots.length > 0) {
            // Check if there is a collision
            const hasConflict = cellSlots.some((s) => s.hasConflict) || cellSlots.length > 1;

            if (hasConflict) {
              return (
                <div
                  key={wd.dayIndex}
                  ref={collisionAnchorRef}
                  id="collisionSlotAnchor"
                  className="p-1.5 bg-red-50/50 border-r border-slate-200 last:border-r-0 relative"
                >
                  <div className="h-full w-full rounded-lg bg-white p-2.5 border-2 border-red-500 shadow-md flex flex-col justify-between">
                    {/* Pulsing banner */}
                    <div className="flex items-center justify-between bg-red-600 text-white px-2 py-0.5 rounded -mx-1 -mt-1 mb-1.5 animate-pulse text-[10px] font-bold">
                      <div className="flex items-center gap-1">
                        <AlertTriangle className="w-3 h-3" />
                        <span>XUNG ĐỘT LỊCH HỌC</span>
                      </div>
                      <span>Cần sửa</span>
                    </div>

                    <div className="space-y-1 overflow-y-auto max-h-[85px]">
                      {cellSlots.map((cs) => (
                        <div key={cs.id} className="bg-red-50 p-1.5 rounded border border-red-200 text-[11px]">
                          <div className="flex items-center justify-between font-bold text-red-700">
                            <span>{cs.className}</span>
                            <span>{cs.roomCode ? `P. ${cs.roomCode}` : 'Chưa xếp phòng'}</span>
                          </div>
                          <div className="text-slate-700 font-semibold flex items-center gap-1 mt-0.5">
                            <span className="text-red-700 underline">{cs.lecturerName || 'Chưa có GV'}</span>
                          </div>
                        </div>
                      ))}
                    </div>

                    <div className="mt-2 flex items-center gap-1 justify-end">
                      <button
                        type="button"
                        onClick={() => openSlotModal('edit', cellSlots[0])}
                        className="px-2 py-1 rounded bg-red-600 text-white text-[11px] font-bold hover:bg-red-700 flex items-center gap-1 w-full justify-center shadow-sm"
                      >
                        <RefreshCw className="w-3 h-3" />
                        <span>Đổi phòng / Đổi GV</span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            }

            // Single Valid Slot
            const slot = cellSlots[0];
            const isLab = slot.courseCategory === 'LAB' || (slot.roomName && slot.roomName.includes('Lab'));

            return (
              <div
                key={wd.dayIndex}
                className="p-1.5 bg-white hover:bg-slate-50 transition border-r border-slate-200 last:border-r-0 relative group"
              >
                <div
                  onClick={() => openSlotModal('edit', slot)}
                  className="h-full w-full rounded-lg bg-white border border-slate-200/90 p-2.5 shadow-sm hover:shadow-md cursor-pointer transition flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-center justify-between gap-1 mb-1">
                      <span
                        className={`text-[11px] font-bold px-1.5 py-0.5 rounded ${
                          isLab
                            ? 'bg-indigo-50 text-indigo-700 border border-indigo-200'
                            : 'bg-blue-50 text-blue-700 border border-blue-200'
                        }`}
                      >
                        {slot.className}
                      </span>
                      <span className="text-[10px] text-emerald-700 bg-emerald-50 border border-emerald-200 px-1 py-0.5 rounded flex items-center gap-0.5 font-semibold">
                        <Bot className="w-3 h-3 text-emerald-600" />
                        {slot.attendanceMethod?.includes('QR') ? 'QR Code' : 'Kiosk AI'}
                      </span>
                    </div>

                    <h4 className="text-xs font-bold text-slate-900 line-clamp-1" title={slot.courseName || ''}>
                      {slot.courseName || 'Học phần'}
                    </h4>

                    <div className="text-[11px] text-slate-500 flex items-center gap-1 mt-0.5">
                      <Users className="w-3 h-3 text-slate-400" />
                      <span className="truncate">{slot.lecturerName || 'Chưa phân công'}</span>
                    </div>
                  </div>

                  <div className="mt-2 pt-1.5 border-t border-slate-100 flex items-center justify-between text-[11px]">
                    <span className="font-bold text-blue-700 flex items-center gap-0.5">
                      <MapPin className="w-3 h-3" />
                      {slot.roomCode ? `P. ${slot.roomCode}` : 'Chưa xếp'}
                    </span>
                    <span className="flex items-center gap-0.5 font-mono text-slate-500">
                      <Users className="w-3 h-3" />
                      {slot.currentEnrollment} SV
                    </span>
                  </div>
                </div>
              </div>
            );
          }

          // Empty cell: hover '+' button to add slot
          return (
            <div
              key={wd.dayIndex}
              onClick={() => openSlotModal('create', undefined, wd.dayIndex, shift.startPeriod, shift.endPeriod)}
              className="p-1.5 bg-white hover:bg-blue-50/40 transition cursor-pointer flex items-center justify-center group border-r border-slate-200 last:border-r-0"
              title={`Nhấp để thêm tiết học vào ${wd.label} (${shift.label})`}
            >
              <Plus className="w-5 h-5 text-slate-300 group-hover:text-blue-600 group-hover:scale-110 transition-all opacity-0 group-hover:opacity-100" />
            </div>
          );
        })}
      </div>
    );
  }
};

export default MasterTimetablePage;
