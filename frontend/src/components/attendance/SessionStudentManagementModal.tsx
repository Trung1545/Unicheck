// ==============================================================================
// UniCheck - Session Student Attendance & Re-check Management Modal
// Allows Lecturer to view all students, adjust attendance manually,
// issue re-check requests, and audit all adjustments in real time.
// ==============================================================================

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Users,
  Search,
  CheckCircle2,
  Clock,
  XCircle,
  AlertTriangle,
  RotateCcw,
  Edit3,
  History,
  X,
  RefreshCw,
  ShieldAlert,
  ArrowRight,
  Filter,
  Check,
  Calendar,
  AlertCircle,
  Info,
} from 'lucide-react';
import {
  getSessionStudentsApi,
  adjustStudentAttendanceApi,
  createRecheckRequestApi,
  getSessionAdjustmentHistoryApi,
} from '../../api/attendance.api';
import {
  AttendanceSessionResponse,
  SessionStudentAttendanceDto,
  AttendanceHistoryRecordDto,
} from '../../types/attendance';

interface SessionStudentManagementModalProps {
  session: AttendanceSessionResponse | null;
  isOpen: boolean;
  onClose: () => void;
  onSessionUpdated?: () => void;
}

export const SessionStudentManagementModal: React.FC<SessionStudentManagementModalProps> = ({
  session,
  isOpen,
  onClose,
  onSessionUpdated,
}) => {
  const [activeTab, setActiveTab] = useState<'STUDENTS' | 'HISTORY'>('STUDENTS');
  const [students, setStudents] = useState<SessionStudentAttendanceDto[]>([]);
  const [histories, setHistories] = useState<AttendanceHistoryRecordDto[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [actionLoading, setActionLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Filters & Search
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  // Modals for Actions
  const [adjustTarget, setAdjustTarget] = useState<SessionStudentAttendanceDto | null>(null);
  const [adjustStatus, setAdjustStatus] = useState<'PRESENT' | 'LATE' | 'ABSENT'>('PRESENT');
  const [adjustReason, setAdjustReason] = useState<string>('');

  const [recheckTarget, setRecheckTarget] = useState<SessionStudentAttendanceDto | null>(null);
  const [recheckReason, setRecheckReason] = useState<string>('');
  const [recheckMinutes, setRecheckMinutes] = useState<number>(15);

  // 1. Fetch Students & History
  const fetchData = useCallback(async () => {
    if (!session?.id) return;
    setLoading(true);
    setError(null);
    try {
      const [studentsRes, historyRes] = await Promise.all([
        getSessionStudentsApi(session.id),
        getSessionAdjustmentHistoryApi(session.id),
      ]);

      if (studentsRes.success && studentsRes.data) {
        setStudents(studentsRes.data);
      }
      if (historyRes.success && historyRes.data) {
        setHistories(historyRes.data);
      }
    } catch (err: any) {
      setError(err?.message || 'Không thể tải dữ liệu điểm danh phiên');
    } finally {
      setLoading(false);
    }
  }, [session?.id]);

  useEffect(() => {
    if (isOpen && session?.id) {
      fetchData();
      setError(null);
      setSuccessMessage(null);
    }
  }, [isOpen, session?.id, fetchData]);

  // Clear success message after 4s
  useEffect(() => {
    if (successMessage) {
      const timer = setTimeout(() => setSuccessMessage(null), 4000);
      return () => clearTimeout(timer);
    }
  }, [successMessage]);

  // 2. Computed Metrics
  const stats = useMemo(() => {
    const total = students.length;
    const present = students.filter((s) => s.status === 'PRESENT').length;
    const late = students.filter((s) => s.status === 'LATE').length;
    const absent = students.filter((s) => s.status === 'ABSENT').length;
    const pendingRecheck = students.filter((s) => s.recheckStatus === 'PENDING').length;
    return { total, present, late, absent, pendingRecheck };
  }, [students]);

  // 3. Filtered Students
  const filteredStudents = useMemo(() => {
    return students.filter((s) => {
      const matchSearch =
        s.studentCode.toLowerCase().includes(searchTerm.toLowerCase()) ||
        s.fullName.toLowerCase().includes(searchTerm.toLowerCase());

      if (!matchSearch) return false;

      if (statusFilter === 'ALL') return true;
      if (statusFilter === 'PENDING_RECHECK') return s.recheckStatus === 'PENDING';
      return s.status === statusFilter;
    });
  }, [students, searchTerm, statusFilter]);

  // 4. Handle Adjust Attendance
  const handleOpenAdjust = (student: SessionStudentAttendanceDto) => {
    setAdjustTarget(student);
    setAdjustStatus(
      student.status === 'LATE' || student.status === 'ABSENT' ? student.status : 'PRESENT'
    );
    setAdjustReason('');
    setError(null);
  };

  const handleSubmitAdjust = async () => {
    if (!session?.id || !adjustTarget) return;
    if (!adjustReason.trim() || adjustReason.trim().length < 5) {
      setError('Vui lòng nhập lý do điều chỉnh hợp lệ (tối thiểu 5 ký tự)');
      return;
    }

    setActionLoading(true);
    setError(null);
    try {
      const res = await adjustStudentAttendanceApi(session.id, adjustTarget.studentId, {
        newStatus: adjustStatus,
        reason: adjustReason.trim(),
      });

      if (res.success) {
        setSuccessMessage(
          `Đã cập nhật trạng thái điểm danh cho sinh viên ${adjustTarget.fullName} (${adjustTarget.studentCode}) thành "${adjustStatus}".`
        );
        setAdjustTarget(null);
        await fetchData();
        if (onSessionUpdated) onSessionUpdated();
      } else {
        setError(res.message || 'Điều chỉnh điểm danh thất bại');
      }
    } catch (err: any) {
      setError(err?.message || 'Có lỗi xảy ra khi điều chỉnh điểm danh');
    } finally {
      setActionLoading(false);
    }
  };

  // 5. Handle Recheck Request
  const handleOpenRecheck = (student: SessionStudentAttendanceDto) => {
    setRecheckTarget(student);
    setRecheckReason('Yêu cầu sinh viên xác thực lại Face-ID và QR trước mặt giảng viên');
    setRecheckMinutes(15);
    setError(null);
  };

  const handleSubmitRecheck = async () => {
    if (!session?.id || !recheckTarget) return;
    if (!recheckReason.trim() || recheckReason.trim().length < 5) {
      setError('Vui lòng nhập lý do yêu cầu điểm danh lại (tối thiểu 5 ký tự)');
      return;
    }

    setActionLoading(true);
    setError(null);
    try {
      const res = await createRecheckRequestApi(session.id, recheckTarget.studentId, {
        reason: recheckReason.trim(),
        expirationMinutes: recheckMinutes,
      });

      if (res.success) {
        setSuccessMessage(
          `Đã gửi yêu cầu điểm danh lại cho sinh viên ${recheckTarget.fullName} (${recheckTarget.studentCode}) thành công (Thời hạn: ${recheckMinutes} phút).`
        );
        setRecheckTarget(null);
        await fetchData();
        if (onSessionUpdated) onSessionUpdated();
      } else {
        setError(res.message || 'Không thể tạo yêu cầu điểm danh lại');
      }
    } catch (err: any) {
      setError(err?.message || 'Có lỗi xảy ra khi tạo yêu cầu điểm danh lại');
    } finally {
      setActionLoading(false);
    }
  };

  if (!isOpen || !session) return null;

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-3 sm:p-5 animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl shadow-2xl border border-slate-200 w-full max-w-6xl max-h-[92vh] flex flex-col overflow-hidden">
        {/* --- Header --- */}
        <div className="px-6 py-4 border-b border-slate-200 bg-slate-50 flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2">
              <span className="px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wider bg-blue-100 text-blue-700">
                Phiên #{session.id}
              </span>
              <span
                className={`px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                  session.status === 'OPEN'
                    ? 'bg-emerald-100 text-emerald-800'
                    : session.status === 'CLOSED'
                    ? 'bg-slate-200 text-slate-700'
                    : 'bg-amber-100 text-amber-800'
                }`}
              >
                {session.status === 'OPEN'
                  ? 'Đang mở tiếp nhận'
                  : session.status === 'CLOSED'
                  ? 'Đã chốt sổ'
                  : 'Đã tạo'}
              </span>
              <span className="text-slate-400">•</span>
              <span className="text-xs text-slate-500 font-medium">
                Phòng: {session.roomCode || session.roomName}
              </span>
              <span className="text-slate-400">•</span>
              <span className="text-xs text-slate-500 font-medium">
                Ca: {session.slotName || `Tiết #${session.slotNumber}`} ({session.startTime} - {session.endTime})
              </span>
            </div>
            <h2 className="text-lg font-bold text-slate-900 mt-1">
              Quản lý điểm danh: {session.courseName} ({session.className})
            </h2>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={fetchData}
              disabled={loading}
              className="p-2 text-slate-500 hover:text-slate-700 hover:bg-slate-200 rounded-lg transition-colors"
              title="Làm mới dữ liệu"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin text-blue-600' : ''}`} />
            </button>
            <button
              type="button"
              onClick={onClose}
              className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-200 rounded-lg transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* --- KPI Bar --- */}
        <div className="px-6 py-3 bg-white border-b border-slate-200 grid grid-cols-2 sm:grid-cols-5 gap-3 text-center">
          <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200/80">
            <div className="text-xs text-slate-500 font-medium">Tổng sĩ số</div>
            <div className="text-xl font-bold text-slate-800">{stats.total}</div>
          </div>
          <div className="p-2.5 rounded-xl bg-emerald-50/80 border border-emerald-200/80">
            <div className="text-xs text-emerald-700 font-medium">Có mặt (Present)</div>
            <div className="text-xl font-bold text-emerald-700">{stats.present}</div>
          </div>
          <div className="p-2.5 rounded-xl bg-amber-50/80 border border-amber-200/80">
            <div className="text-xs text-amber-700 font-medium">Đi muộn (Late)</div>
            <div className="text-xl font-bold text-amber-700">{stats.late}</div>
          </div>
          <div className="p-2.5 rounded-xl bg-rose-50/80 border border-rose-200/80">
            <div className="text-xs text-rose-700 font-medium">Vắng mặt (Absent)</div>
            <div className="text-xl font-bold text-rose-700">{stats.absent}</div>
          </div>
          <div className="p-2.5 rounded-xl bg-orange-50/80 border border-orange-200/80">
            <div className="text-xs text-orange-700 font-medium">Chờ Re-check</div>
            <div className="text-xl font-bold text-orange-700">{stats.pendingRecheck}</div>
          </div>
        </div>

        {/* --- Feedback Banners --- */}
        {error && (
          <div className="mx-6 mt-3 p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-sm flex items-center justify-between">
            <div className="flex items-center gap-2">
              <AlertCircle className="w-4 h-4 flex-shrink-0" />
              <span>{error}</span>
            </div>
            <button onClick={() => setError(null)} className="text-rose-500 hover:text-rose-700">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {successMessage && (
          <div className="mx-6 mt-3 p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm flex items-center justify-between">
            <div className="flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 flex-shrink-0 text-emerald-600" />
              <span>{successMessage}</span>
            </div>
            <button onClick={() => setSuccessMessage(null)} className="text-emerald-500 hover:text-emerald-700">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* --- Tabs Header --- */}
        <div className="px-6 pt-3 flex items-center justify-between border-b border-slate-200 bg-white">
          <div className="flex gap-4">
            <button
              type="button"
              onClick={() => setActiveTab('STUDENTS')}
              className={`pb-3 text-sm font-semibold flex items-center gap-2 border-b-2 transition-colors ${
                activeTab === 'STUDENTS'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <Users className="w-4 h-4" />
              <span>Danh sách sinh viên ({students.length})</span>
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('HISTORY')}
              className={`pb-3 text-sm font-semibold flex items-center gap-2 border-b-2 transition-colors ${
                activeTab === 'HISTORY'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <History className="w-4 h-4" />
              <span>Lịch sử điều chỉnh & Kiểm toán ({histories.length})</span>
            </button>
          </div>

          {activeTab === 'STUDENTS' && (
            <div className="flex items-center gap-2 pb-2">
              <div className="relative">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  placeholder="Tìm theo MSSV hoặc họ tên..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-9 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-lg w-56 focus:outline-none focus:ring-1 focus:ring-blue-500 focus:bg-white"
                />
              </div>

              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="py-1.5 px-2.5 text-xs bg-slate-50 border border-slate-200 rounded-lg text-slate-700 focus:outline-none focus:ring-1 focus:ring-blue-500"
              >
                <option value="ALL">Tất cả trạng thái</option>
                <option value="PRESENT">Có mặt (PRESENT)</option>
                <option value="LATE">Đi muộn (LATE)</option>
                <option value="ABSENT">Vắng mặt (ABSENT)</option>
                <option value="PENDING_RECHECK">Đang chờ Re-check</option>
              </select>
            </div>
          )}
        </div>

        {/* --- Main Content Body --- */}
        <div className="flex-1 overflow-y-auto p-6">
          {activeTab === 'STUDENTS' ? (
            <div>
              {loading && students.length === 0 ? (
                <div className="py-20 text-center text-slate-400 text-sm flex items-center justify-center gap-2">
                  <RefreshCw className="w-5 h-5 animate-spin text-blue-600" />
                  <span>Đang tải danh sách sinh viên...</span>
                </div>
              ) : filteredStudents.length === 0 ? (
                <div className="py-16 text-center text-slate-400 text-sm">
                  Không tìm thấy sinh viên nào phù hợp với bộ lọc.
                </div>
              ) : (
                <div className="overflow-x-auto border border-slate-200 rounded-xl shadow-sm">
                  <table className="w-full text-left border-collapse text-xs">
                    <thead>
                      <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold uppercase tracking-wider">
                        <th className="py-3 px-3 w-12 text-center">STT</th>
                        <th className="py-3 px-3">MSSV</th>
                        <th className="py-3 px-4">Họ và tên</th>
                        <th className="py-3 px-3">Trạng thái</th>
                        <th className="py-3 px-3">Thời gian</th>
                        <th className="py-3 px-3">Phương thức</th>
                        <th className="py-3 px-3">Yêu cầu Re-check</th>
                        <th className="py-3 px-3 text-right">Thao tác</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {filteredStudents.map((st, idx) => (
                        <tr key={st.studentId} className="hover:bg-slate-50/80 transition-colors">
                          <td className="py-3 px-3 text-center text-slate-400 font-medium">
                            {idx + 1}
                          </td>
                          <td className="py-3 px-3 font-semibold text-slate-900">
                            {st.studentCode}
                          </td>
                          <td className="py-3 px-4">
                            <div className="font-medium text-slate-800">{st.fullName}</div>
                            <div className="text-[11px] text-slate-400">{st.email}</div>
                          </td>
                          <td className="py-3 px-3">
                            {st.status === 'PRESENT' && (
                              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-emerald-100 text-emerald-800">
                                <CheckCircle2 className="w-3 h-3" />
                                Có mặt
                              </span>
                            )}
                            {st.status === 'LATE' && (
                              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-amber-100 text-amber-800">
                                <Clock className="w-3 h-3" />
                                Đi muộn
                              </span>
                            )}
                            {st.status === 'ABSENT' && (
                              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-rose-100 text-rose-800">
                                <XCircle className="w-3 h-3" />
                                Vắng mặt
                              </span>
                            )}
                            {!['PRESENT', 'LATE', 'ABSENT'].includes(st.status) && (
                              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-slate-100 text-slate-600">
                                Chưa điểm danh
                              </span>
                            )}
                          </td>
                          <td className="py-3 px-3 text-slate-600">
                            {st.checkInTime
                              ? new Date(st.checkInTime).toLocaleTimeString('vi-VN', {
                                  hour: '2-digit',
                                  minute: '2-digit',
                                  second: '2-digit',
                                })
                              : '--'}
                          </td>
                          <td className="py-3 px-3 text-slate-600">
                            {st.method === 'FACE_QR'
                              ? 'Face-ID & QR'
                              : st.method === 'MANUAL'
                              ? 'Thủ công'
                              : st.method || '--'}
                          </td>
                          <td className="py-3 px-3">
                            {st.recheckStatus === 'PENDING' ? (
                              <div className="inline-flex flex-col">
                                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-orange-100 text-orange-800 animate-pulse">
                                  <RotateCcw className="w-2.5 h-2.5" />
                                  Đang chờ sinh viên
                                </span>
                                {st.recheckExpiresAt && (
                                  <span className="text-[10px] text-orange-600 mt-0.5">
                                    Hạn:{' '}
                                    {new Date(st.recheckExpiresAt).toLocaleTimeString('vi-VN', {
                                      hour: '2-digit',
                                      minute: '2-digit',
                                    })}
                                  </span>
                                )}
                              </div>
                            ) : st.recheckStatus === 'COMPLETED' ? (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium bg-emerald-50 text-emerald-700">
                                <Check className="w-2.5 h-2.5" />
                                Đã Re-check
                              </span>
                            ) : st.recheckStatus === 'EXPIRED' ? (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium bg-slate-100 text-slate-500">
                                Hết hạn
                              </span>
                            ) : (
                              <span className="text-slate-300">--</span>
                            )}
                          </td>
                          <td className="py-3 px-3 text-right">
                            <div className="flex items-center justify-end gap-1.5">
                              <button
                                type="button"
                                onClick={() => handleOpenAdjust(st)}
                                className="px-2.5 py-1.5 rounded-lg text-xs font-semibold bg-slate-100 hover:bg-blue-50 text-slate-700 hover:text-blue-700 border border-slate-200 transition-colors flex items-center gap-1"
                                title="Điều chỉnh trạng thái điểm danh thủ công"
                              >
                                <Edit3 className="w-3.5 h-3.5" />
                                <span>Sửa</span>
                              </button>

                              <button
                                type="button"
                                onClick={() => handleOpenRecheck(st)}
                                disabled={st.recheckStatus === 'PENDING'}
                                className={`px-2.5 py-1.5 rounded-lg text-xs font-semibold border transition-colors flex items-center gap-1 ${
                                  st.recheckStatus === 'PENDING'
                                    ? 'bg-slate-50 text-slate-400 border-slate-200 cursor-not-allowed'
                                    : 'bg-orange-50 hover:bg-orange-100 text-orange-700 border-orange-200'
                                }`}
                                title="Yêu cầu sinh viên điểm danh lại qua QR & Face-ID"
                              >
                                <RotateCcw className="w-3.5 h-3.5" />
                                <span>Re-check</span>
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          ) : (
            <div>
              {loading && histories.length === 0 ? (
                <div className="py-20 text-center text-slate-400 text-sm flex items-center justify-center gap-2">
                  <RefreshCw className="w-5 h-5 animate-spin text-blue-600" />
                  <span>Đang tải lịch sử kiểm toán...</span>
                </div>
              ) : histories.length === 0 ? (
                <div className="py-16 text-center text-slate-400 text-sm">
                  Chưa có lịch sử điều chỉnh hoặc tái xác thực nào cho phiên học này.
                </div>
              ) : (
                <div className="overflow-x-auto border border-slate-200 rounded-xl shadow-sm">
                  <table className="w-full text-left border-collapse text-xs">
                    <thead>
                      <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold uppercase tracking-wider">
                        <th className="py-3 px-3">Thời gian</th>
                        <th className="py-3 px-3">Sinh viên</th>
                        <th className="py-3 px-3">Loại thay đổi</th>
                        <th className="py-3 px-3">Trạng thái</th>
                        <th className="py-3 px-3">Người thực hiện</th>
                        <th className="py-3 px-4">Lý do điều chỉnh</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {histories.map((h) => (
                        <tr key={h.id} className="hover:bg-slate-50/80 transition-colors">
                          <td className="py-3 px-3 text-slate-600 whitespace-nowrap">
                            {new Date(h.modifiedAt).toLocaleString('vi-VN')}
                          </td>
                          <td className="py-3 px-3">
                            <span className="font-semibold text-slate-900">{h.studentCode}</span>
                            <span className="text-slate-500 ml-1.5">({h.studentName})</span>
                          </td>
                          <td className="py-3 px-3">
                            {h.modificationType === 'MANUAL_ADJUSTMENT' ? (
                              <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-blue-50 text-blue-700">
                                Sửa thủ công
                              </span>
                            ) : h.modificationType === 'RECHECK_REQUESTED' ? (
                              <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-orange-50 text-orange-700">
                                Yêu cầu Re-check
                              </span>
                            ) : h.modificationType === 'RECHECK_COMPLETED' ? (
                              <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-emerald-50 text-emerald-700">
                                Re-check thành công
                              </span>
                            ) : (
                              <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-slate-100 text-slate-600">
                                {h.modificationType}
                              </span>
                            )}
                          </td>
                          <td className="py-3 px-3">
                            <div className="flex items-center gap-1.5 font-medium">
                              <span className="text-slate-400">{h.oldStatus}</span>
                              <ArrowRight className="w-3 h-3 text-slate-400" />
                              <span className="font-bold text-slate-900">{h.newStatus}</span>
                            </div>
                          </td>
                          <td className="py-3 px-3 text-slate-700 font-medium whitespace-nowrap">
                            {h.modifiedByName}
                          </td>
                          <td className="py-3 px-4 text-slate-600">
                            {h.reason}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </div>

        {/* --- Footer --- */}
        <div className="px-6 py-3 border-t border-slate-200 bg-slate-50 flex items-center justify-between text-xs text-slate-500">
          <div>
            Hệ thống tuân thủ Nghị định 13/2023/NĐ-CP & ISO 27001: Mọi thay đổi đều được ghi vết kiểm toán toàn vẹn.
          </div>
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-lg bg-slate-200 hover:bg-slate-300 text-slate-700 font-semibold transition-colors"
          >
            Đóng
          </button>
        </div>
      </div>

      {/* =========================================================================
          CHILD MODAL: Manual Adjust Attendance Status
          ========================================================================= */}
      {adjustTarget && (
        <div className="fixed inset-0 z-60 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-150">
          <div className="bg-white rounded-2xl shadow-xl border border-slate-200 w-full max-w-md p-6 overflow-hidden">
            <div className="flex items-center justify-between pb-3 border-b border-slate-200">
              <div className="flex items-center gap-2">
                <Edit3 className="w-5 h-5 text-blue-600" />
                <h3 className="font-bold text-slate-900 text-base">Điều chỉnh điểm danh</h3>
              </div>
              <button
                type="button"
                onClick={() => setAdjustTarget(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="mt-4 space-y-4">
              <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 text-xs">
                <div className="font-semibold text-slate-800 text-sm">
                  {adjustTarget.fullName}
                </div>
                <div className="text-slate-500 mt-0.5">
                  MSSV: <span className="font-medium text-slate-700">{adjustTarget.studentCode}</span>
                </div>
                <div className="text-slate-500 mt-0.5">
                  Trạng thái hiện tại:{' '}
                  <span className="font-bold text-slate-700">{adjustTarget.status}</span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Chọn trạng thái mới <span className="text-rose-500">*</span>
                </label>
                <div className="grid grid-cols-3 gap-2">
                  <button
                    type="button"
                    onClick={() => setAdjustStatus('PRESENT')}
                    className={`py-2 px-3 rounded-lg border text-xs font-bold transition-colors ${
                      adjustStatus === 'PRESENT'
                        ? 'bg-emerald-600 border-emerald-600 text-white shadow-sm'
                        : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
                    }`}
                  >
                    Có mặt
                  </button>
                  <button
                    type="button"
                    onClick={() => setAdjustStatus('LATE')}
                    className={`py-2 px-3 rounded-lg border text-xs font-bold transition-colors ${
                      adjustStatus === 'LATE'
                        ? 'bg-amber-500 border-amber-500 text-white shadow-sm'
                        : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
                    }`}
                  >
                    Đi muộn
                  </button>
                  <button
                    type="button"
                    onClick={() => setAdjustStatus('ABSENT')}
                    className={`py-2 px-3 rounded-lg border text-xs font-bold transition-colors ${
                      adjustStatus === 'ABSENT'
                        ? 'bg-rose-600 border-rose-600 text-white shadow-sm'
                        : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
                    }`}
                  >
                    Vắng mặt
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Lý do điều chỉnh (Bắt buộc) <span className="text-rose-500">*</span>
                </label>
                <textarea
                  rows={3}
                  value={adjustReason}
                  onChange={(e) => setAdjustReason(e.target.value)}
                  placeholder="Ví dụ: Sinh viên có mặt đúng giờ nhưng camera hỏng, giảng viên xác nhận trực tiếp..."
                  className="w-full text-xs p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-blue-500 focus:bg-white resize-none"
                />
                <div className="text-[11px] text-slate-400 mt-1">
                  Tối thiểu 5 ký tự. Nội dung sẽ được lưu vĩnh viễn vào nhật ký kiểm toán.
                </div>
              </div>
            </div>

            <div className="mt-6 flex items-center justify-end gap-2 pt-3 border-t border-slate-200">
              <button
                type="button"
                onClick={() => setAdjustTarget(null)}
                className="px-3.5 py-2 rounded-lg text-xs font-semibold text-slate-600 hover:bg-slate-100 transition-colors"
              >
                Hủy
              </button>
              <button
                type="button"
                onClick={handleSubmitAdjust}
                disabled={actionLoading || adjustReason.trim().length < 5}
                className="px-4 py-2 rounded-lg text-xs font-semibold bg-blue-600 hover:bg-blue-700 disabled:bg-slate-200 disabled:text-slate-400 text-white transition-colors flex items-center gap-1.5 shadow-sm"
              >
                {actionLoading && <RefreshCw className="w-3.5 h-3.5 animate-spin" />}
                <span>Lưu thay đổi</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* =========================================================================
          CHILD MODAL: Recheck Request Modal
          ========================================================================= */}
      {recheckTarget && (
        <div className="fixed inset-0 z-60 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-150">
          <div className="bg-white rounded-2xl shadow-xl border border-slate-200 w-full max-w-md p-6 overflow-hidden">
            <div className="flex items-center justify-between pb-3 border-b border-slate-200">
              <div className="flex items-center gap-2 text-orange-600">
                <RotateCcw className="w-5 h-5" />
                <h3 className="font-bold text-slate-900 text-base">Yêu cầu điểm danh lại</h3>
              </div>
              <button
                type="button"
                onClick={() => setRecheckTarget(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="mt-4 space-y-4">
              <div className="p-3 bg-orange-50/60 rounded-xl border border-orange-200 text-xs">
                <div className="font-semibold text-slate-800 text-sm">
                  {recheckTarget.fullName}
                </div>
                <div className="text-slate-600 mt-0.5">
                  MSSV: <span className="font-medium text-slate-800">{recheckTarget.studentCode}</span>
                </div>
                <div className="text-slate-600 mt-0.5">
                  Lớp: <span className="font-medium text-slate-800">{session.className}</span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Thời hạn thực hiện (Phút)
                </label>
                <select
                  value={recheckMinutes}
                  onChange={(e) => setRecheckMinutes(Number(e.target.value))}
                  className="w-full text-xs p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-orange-500"
                >
                  <option value={5}>5 phút</option>
                  <option value={10}>10 phút</option>
                  <option value={15}>15 phút (Khuyên dùng)</option>
                  <option value={30}>30 phút</option>
                  <option value={60}>60 phút</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Lý do yêu cầu điểm danh lại <span className="text-rose-500">*</span>
                </label>
                <textarea
                  rows={3}
                  value={recheckReason}
                  onChange={(e) => setRecheckReason(e.target.value)}
                  placeholder="Ví dụ: Nghi vấn điểm danh hộ, yêu cầu sinh viên quét lại QR và xác thực FaceID trước mặt giảng viên..."
                  className="w-full text-xs p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-orange-500 focus:bg-white resize-none"
                />
                <div className="text-[11px] text-slate-400 mt-1">
                  Thông báo sẽ hiển thị trực tiếp trên điện thoại của sinh viên này.
                </div>
              </div>
            </div>

            <div className="mt-6 flex items-center justify-end gap-2 pt-3 border-t border-slate-200">
              <button
                type="button"
                onClick={() => setRecheckTarget(null)}
                className="px-3.5 py-2 rounded-lg text-xs font-semibold text-slate-600 hover:bg-slate-100 transition-colors"
              >
                Hủy
              </button>
              <button
                type="button"
                onClick={handleSubmitRecheck}
                disabled={actionLoading || recheckReason.trim().length < 5}
                className="px-4 py-2 rounded-lg text-xs font-semibold bg-orange-600 hover:bg-orange-700 disabled:bg-slate-200 disabled:text-slate-400 text-white transition-colors flex items-center gap-1.5 shadow-sm"
              >
                {actionLoading && <RefreshCw className="w-3.5 h-3.5 animate-spin" />}
                <span>Gửi yêu cầu Re-check</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
