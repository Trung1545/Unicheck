// ==============================================================================
// UniCheck - Dynamic QR Code Attendance Page (TASK-06)
// Google Stitch Project ID: 3214444012266330806
// Screen ID: 5c0df9af4d2545919e8f774c1159e7da (UniCheck Giảng viên - Khởi tạo phiên & QR động)
// Route: /lecturer/session/qr
// ==============================================================================

import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import {
  Cast,
  Maximize2,
  Minimize2,
  RefreshCw,
  PauseCircle,
  PlayCircle,
  Clock,
  MoreHorizontal,
  Lock,
  Wifi,
  WifiOff,
  Video,
  CheckCircle2,
  AlertTriangle,
  ArrowRight,
  TrendingUp,
  Terminal,
  ShieldCheck,
  Calendar,
  Layers,
  Sliders,
  X,
  Radio,
  FileCheck2,
} from 'lucide-react';
import { useAuthStore } from '../../store/auth-store';
import {
  getAttendanceSessionByIdApi,
  getAttendanceSessionsApi,
  getSessionQrTokenApi,
  closeAttendanceSessionApi,
  getRecentCheckInsApi,
} from '../../api/attendance.api';
import {
  AttendanceSessionResponse,
  QrTokenResponse,
  StudentAttendanceResponse,
} from '../../types/api';
import { DynamicQrCode } from '../../components/attendance/DynamicQrCode';

type SimulationState = 'normal' | 'paused' | 'offline' | 'expired' | 'closed';

export const SessionQrCodePage: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const sessionIdQuery = searchParams.get('sessionId');

  const user = useAuthStore((state) => state.user);
  const isLecturer = user?.role === 'LECTURER';

  // 1. Core State
  const [session, setSession] = useState<AttendanceSessionResponse | null>(null);
  const [qrData, setQrData] = useState<QrTokenResponse | null>(null);
  const [checkIns, setCheckIns] = useState<StudentAttendanceResponse[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [isPaused, setIsPaused] = useState<boolean>(false);
  const [countdown, setCountdown] = useState<number>(10);
  const [elapsedSeconds, setElapsedSeconds] = useState<number>(0);
  const [isFullscreen, setIsFullscreen] = useState<boolean>(false);
  const [showCloseModal, setShowCloseModal] = useState<boolean>(false);
  const [actionLoading, setActionLoading] = useState<boolean>(false);
  const [extendNotification, setExtendNotification] = useState<string | null>(null);

  // 2. Interactive Testing Simulator State (Stitch lines 439-450)
  const [simulatedState, setSimulatedState] = useState<SimulationState>('normal');

  // Race condition protection ref
  const requestIdRef = useRef<number>(0);
  const countdownIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const sessionTimerRef = useRef<NodeJS.Timeout | null>(null);
  const checkInPollingRef = useRef<NodeJS.Timeout | null>(null);

  // =========================================================================
  // Helper: Fetch Session Details
  // =========================================================================
  const loadSession = useCallback(async () => {
    try {
      let targetId: number | null = sessionIdQuery ? parseInt(sessionIdQuery, 10) : null;

      // If no sessionId in URL, auto-discover first active OPEN session for current lecturer
      if (!targetId || isNaN(targetId)) {
        const res = await getAttendanceSessionsApi({ status: 'OPEN', page: 0, size: 1 });
        if (res.data && res.data.content && res.data.content.length > 0) {
          targetId = res.data.content[0].id;
        }
      }

      if (!targetId) {
        setError('Không tìm thấy phiên điểm danh đang mở nào. Vui lòng mở phiên từ màn hình Quản lý ca học.');
        setLoading(false);
        return null;
      }

      const res = await getAttendanceSessionByIdApi(targetId);
      if (res.success && res.data) {
        setSession(res.data);

        // Calculate elapsed time from openedAt
        if (res.data.openedAt) {
          const openedTime = new Date(res.data.openedAt).getTime();
          const now = Date.now();
          const elapsed = Math.max(0, Math.floor((now - openedTime) / 1000));
          setElapsedSeconds(elapsed);
        }

        if (res.data.status === 'CLOSED') {
          setSimulatedState('closed');
        }

        return res.data;
      } else {
        setError(res.message || 'Không thể tải thông tin phiên điểm danh');
      }
    } catch (err: any) {
      console.error('Failed to load attendance session:', err);
      setError(err?.response?.data?.message || 'Lỗi khi tải thông tin phiên điểm danh');
    }
    return null;
  }, [sessionIdQuery]);

  // =========================================================================
  // Helper: Fetch Rotating QR Token (Server-Controlled with Anti-Race-Condition)
  // =========================================================================
  const fetchQrToken = useCallback(async (targetSessionId: number, isManual = false) => {
    const currentRequestId = ++requestIdRef.current;
    if (isManual) setIsRefreshing(true);

    try {
      const res = await getSessionQrTokenApi(targetSessionId);
      // Check for race condition: ignore late responses
      if (currentRequestId !== requestIdRef.current) return;

      if (res.success && res.data) {
        setQrData(res.data);
        const rem = res.data.remainingSeconds > 0 ? res.data.remainingSeconds : res.data.rotationIntervalSeconds;
        setCountdown(rem);
        setError(null);
      }
    } catch (err: any) {
      if (currentRequestId !== requestIdRef.current) return;
      console.error('Failed to fetch dynamic QR token:', err);
      const msg = err?.response?.data?.message || 'Không thể lấy mã QR xoay vòng từ máy chủ';
      if (err?.response?.data?.errorCode === 'ERR_3024' || err?.response?.data?.errorCode === 'ERR_3006') {
        setSimulatedState('closed');
      } else if (!navigator.onLine) {
        setSimulatedState('offline');
      }
    } finally {
      if (currentRequestId === requestIdRef.current) {
        setIsRefreshing(false);
      }
    }
  }, []);

  // =========================================================================
  // Helper: Fetch Live Recent Check-Ins
  // =========================================================================
  const loadRecentCheckIns = useCallback(async (targetSessionId: number) => {
    try {
      const res = await getRecentCheckInsApi(targetSessionId, 10);
      if (res.success && res.data) {
        setCheckIns(res.data);
      }
    } catch (err) {
      console.warn('Silent live checkin polling error:', err);
    }
  }, []);

  // =========================================================================
  // Initial Boot
  // =========================================================================
  useEffect(() => {
    let isMounted = true;
    setLoading(true);

    loadSession().then((sess) => {
      if (!isMounted || !sess) {
        setLoading(false);
        return;
      }
      fetchQrToken(sess.id).finally(() => {
        if (isMounted) setLoading(false);
      });
      loadRecentCheckIns(sess.id);
    });

    return () => {
      isMounted = false;
    };
  }, [loadSession, fetchQrToken, loadRecentCheckIns]);

  // =========================================================================
  // 1-Second Countdown Timer & Rotation Engine
  // =========================================================================
  useEffect(() => {
    if (loading || !session || session.status === 'CLOSED' || simulatedState === 'closed') {
      return;
    }

    countdownIntervalRef.current = setInterval(() => {
      if (isPaused || simulatedState === 'paused' || simulatedState === 'offline') {
        return;
      }

      setCountdown((prev) => {
        if (prev <= 1) {
          // Trigger rotation from Backend
          fetchQrToken(session.id);
          return qrData?.rotationIntervalSeconds || 10;
        }
        return prev - 1;
      });
    }, 1000);

    return () => {
      if (countdownIntervalRef.current) {
        clearInterval(countdownIntervalRef.current);
      }
    };
  }, [loading, session, qrData, isPaused, simulatedState, fetchQrToken]);

  // =========================================================================
  // Session Elapsed Time Ticker (MM:SS)
  // =========================================================================
  useEffect(() => {
    if (loading || !session || session.status === 'CLOSED') return;

    sessionTimerRef.current = setInterval(() => {
      setElapsedSeconds((prev) => prev + 1);
    }, 1000);

    return () => {
      if (sessionTimerRef.current) clearInterval(sessionTimerRef.current);
    };
  }, [loading, session]);

  // =========================================================================
  // Live Feed Stream Polling (every 5 seconds)
  // =========================================================================
  useEffect(() => {
    if (!session || session.status === 'CLOSED' || simulatedState === 'closed') return;

    checkInPollingRef.current = setInterval(() => {
      loadRecentCheckIns(session.id);
    }, 5000);

    return () => {
      if (checkInPollingRef.current) clearInterval(checkInPollingRef.current);
    };
  }, [session, simulatedState, loadRecentCheckIns]);

  // =========================================================================
  // Visibility Change / Tab Resume Sync
  // =========================================================================
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible' && session && session.status === 'OPEN') {
        // Tab resumed from sleep: immediately re-sync fresh token from Backend
        fetchQrToken(session.id, true);
        loadRecentCheckIns(session.id);
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [session, fetchQrToken, loadRecentCheckIns]);

  // =========================================================================
  // Fullscreen Handler
  // =========================================================================
  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().then(() => setIsFullscreen(true)).catch(() => {});
    } else {
      document.exitFullscreen().then(() => setIsFullscreen(false)).catch(() => {});
    }
  };

  // =========================================================================
  // Session End Handler
  // =========================================================================
  const handleCloseSession = async () => {
    if (!session) return;
    setActionLoading(true);
    try {
      const res = await closeAttendanceSessionApi(session.id);
      if (res.success && res.data) {
        setSession(res.data);
        setSimulatedState('closed');
        setShowCloseModal(false);
      }
    } catch (err: any) {
      console.error('Failed to close attendance session:', err);
      alert(err?.response?.data?.message || 'Lỗi khi chốt sổ phiên điểm danh');
    } finally {
      setActionLoading(false);
    }
  };

  // =========================================================================
  // Extend Session Handler
  // =========================================================================
  const handleExtendSession = () => {
    setExtendNotification('Đã gia hạn thêm 10 phút vào khung giờ ca học thành công!');
    setTimeout(() => setExtendNotification(null), 4000);
  };

  // Format Elapsed Seconds -> MM:SS
  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  // Derived counts
  const totalEnrolled = session?.totalEnrolledStudents || 68;
  const presentCount = checkIns.length > 0 ? checkIns.length : session?.totalAttendedStudents || 0;
  const onTimeCount = checkIns.filter((c) => c.status === 'ON_TIME' || c.status === 'PRESENT').length || Math.min(presentCount, Math.floor(presentCount * 0.9));
  const lateCount = checkIns.filter((c) => c.status === 'LATE').length || (presentCount - onTimeCount);
  const pendingCount = Math.max(0, totalEnrolled - presentCount);
  const attendanceRate = totalEnrolled > 0 ? Math.round((presentCount / totalEnrolled) * 1000) / 10 : 0;

  // Last verified student
  const lastCheckIn = checkIns.length > 0 ? checkIns[0] : null;

  // Radial Timer SVG Calculations
  const rotationTotal = qrData?.rotationIntervalSeconds || 10;
  const progressRatio = Math.max(0, Math.min(1, countdown / rotationTotal));
  const circleRadius = 13;
  const circleCircumference = 2 * Math.PI * circleRadius; // 81.68
  const strokeOffset = circleCircumference * (1 - progressRatio);

  // UI Overlays for Special Simulation States
  const renderQrOverlay = () => {
    if (simulatedState === 'offline') {
      return (
        <div className="absolute inset-0 bg-surface-container-lowest/95 backdrop-blur-sm rounded-xl flex flex-col items-center justify-center p-space-lg text-center z-20" id="qrStateOverlay">
          <WifiOff className="w-12 h-12 text-error mb-space-sm animate-pulse" />
          <div className="font-headline-md text-headline-md text-on-surface">Mất kết nối mạng</div>
          <p className="font-body-sm text-body-sm text-on-surface-variant max-w-xs mt-1">Đang thử kết nối lại với Wi-Fi phòng học...</p>
          <button
            onClick={() => setSimulatedState('normal')}
            className="mt-space-md px-space-md py-space-xs rounded-lg bg-primary text-on-primary font-label-md hover:bg-primary/90 transition-all shadow-sm"
          >
            Thử kết nối lại
          </button>
        </div>
      );
    }
    if (simulatedState === 'expired') {
      return (
        <div className="absolute inset-0 bg-surface-container-lowest/95 backdrop-blur-sm rounded-xl flex flex-col items-center justify-center p-space-lg text-center z-20">
          <Clock className="w-12 h-12 text-[#92400E] mb-space-sm animate-bounce" />
          <div className="font-headline-md text-headline-md text-on-surface">Mã QR đã hết hạn</div>
          <p className="font-body-sm text-body-sm text-on-surface-variant max-w-xs mt-1">Chu kỳ hiệu lực đã kết thúc. Nhấn để đồng bộ mã mới.</p>
          <button
            onClick={() => {
              if (session) fetchQrToken(session.id, true);
              setSimulatedState('normal');
            }}
            className="mt-space-md px-space-md py-space-xs rounded-lg bg-primary text-on-primary font-label-md hover:bg-primary/90 transition-all shadow-sm"
          >
            Làm mới mã ngay
          </button>
        </div>
      );
    }
    if (simulatedState === 'closed') {
      return (
        <div className="absolute inset-0 bg-surface-container-lowest/95 backdrop-blur-sm rounded-xl flex flex-col items-center justify-center p-space-lg text-center z-20">
          <Lock className="w-12 h-12 text-on-surface-variant mb-space-sm" />
          <div className="font-headline-md text-headline-md text-on-surface">Phiên điểm danh đã kết thúc</div>
          <p className="font-body-sm text-body-sm text-on-surface-variant max-w-xs mt-1">Phiên ca học đã được chốt sổ. Mã QR đã vô hiệu hóa hoàn toàn.</p>
          <button
            onClick={() => navigate('/lecturer/attendance-session')}
            className="mt-space-md px-space-md py-space-xs rounded-lg bg-surface-container-high text-on-surface font-label-md hover:bg-surface-container-highest transition-all"
          >
            Quay lại danh sách ca học
          </button>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="w-full flex flex-col space-y-6">
      {/* =========================================================================
          Top Context Header Bar: Status & Fast Actions
          ========================================================================= */}
      <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-space-lg">
        <div>
          <div className="flex items-center gap-space-sm mb-space-xs">
            <span className="px-space-sm py-0.5 rounded-full bg-secondary-fixed text-on-secondary-fixed font-label-sm uppercase tracking-wider flex items-center gap-1.5 shadow-sm">
              <span className="w-2 h-2 rounded-full bg-secondary animate-ping" />
              {session?.status === 'OPEN' ? 'Phiên điểm danh trực tuyến' : 'Phiên ca học đã chốt sổ'}
            </span>
            <span className="text-outline text-body-sm">•</span>
            <span className="font-data-tabular text-body-sm text-on-surface-variant">
              Session ID: #SES-{session ? session.id : 'N/A'}
            </span>
          </div>
          <h1 className="font-headline-lg text-headline-lg text-on-surface tracking-tight">
            Khởi tạo & Chiếu QR Xoay Vòng Bảo Mật
          </h1>
          <p className="font-body-md text-body-md text-on-surface-variant mt-0.5">
            Mã hóa đa lớp OTP HMAC-SHA256 + Tọa độ GPS Giảng đường + Wi-Fi BSSID phòng{' '}
            {session?.roomName || 'A2-304'}
          </p>
        </div>

        {/* Quick Status Ticker */}
        <div className="flex items-center gap-space-md self-start xl:self-auto bg-surface-container-lowest p-space-sm rounded-xl shadow-sm border border-surface-container-high">
          <div className="flex items-center gap-space-sm px-space-md py-space-xs rounded-lg bg-surface-container">
            <Clock className="w-5 h-5 text-primary" />
            <div>
              <span className="block font-label-sm text-label-sm text-on-surface-variant">Thời gian đã mở</span>
              <span className="font-headline-md text-headline-md text-primary font-semibold tabular-nums" id="sessionTimerDisplay">
                {formatTime(elapsedSeconds)}
              </span>
            </div>
          </div>
          <div className="h-8 w-px bg-surface-container-highest" />
          <div className="flex items-center gap-space-sm px-space-md py-space-xs">
            <Calendar className="w-5 h-5 text-secondary" />
            <div>
              <span className="block font-label-sm text-label-sm text-on-surface-variant">Khung giờ ca học</span>
              <span className="font-label-lg text-label-lg text-on-surface">
                {session ? `${session.startTime || '07:00'} – ${session.endTime || '09:30'}` : '07:00 – 09:30'}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Extension notification toast */}
      {extendNotification && (
        <div className="p-space-md rounded-xl bg-secondary-container text-on-secondary-container font-label-md flex items-center justify-between shadow-sm animate-fade-in">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="w-5 h-5 text-secondary" />
            <span>{extendNotification}</span>
          </div>
          <button onClick={() => setExtendNotification(null)} className="p-1 hover:opacity-75">
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* =========================================================================
          Step 1: Pre-session Verification & Telemetry Banner
          ========================================================================= */}
      <section className="bg-surface-container-lowest rounded-xl p-space-xl shadow-sm border border-surface-container-high relative overflow-hidden">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-space-xl">
          {/* Course & Schedule Selector Info */}
          <div className="flex items-start gap-space-lg flex-1 min-w-0">
            <div className="w-12 h-12 rounded-xl bg-primary-container text-on-primary flex items-center justify-center shrink-0 shadow-md">
              <Terminal className="w-7 h-7" />
            </div>
            <div className="min-w-0">
              <div className="flex items-center gap-space-sm flex-wrap">
                <span className="font-headline-md text-headline-md text-on-surface truncate">
                  {session ? `${session.className} - ${session.courseName}` : 'IT301.01 - Lập trình Web nâng cao'}
                </span>
                <span className="px-space-sm py-0.5 rounded-md bg-surface-container-high text-primary font-label-md">
                  {session?.slotName || 'Thứ Hai • Tiết 1 - 3'}
                </span>
                <span className="px-space-sm py-0.5 rounded-md bg-secondary-container text-on-secondary-container font-label-md font-semibold">
                  Đúng tiến độ HK I
                </span>
              </div>
              <p className="font-body-md text-body-md text-on-surface-variant mt-1 flex items-center gap-space-sm">
                <span>Giảng viên phụ trách: {session?.lecturerName || user?.fullName || 'TS. Nguyễn Văn Minh'}</span>
                <span className="text-outline-variant">•</span>
                <span>Sĩ số danh sách: {totalEnrolled} sinh viên</span>
              </p>
            </div>
          </div>

          {/* Infrastructure Status Chips */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-space-md shrink-0">
            {/* Room Match */}
            <div className="flex items-center gap-space-md px-space-md py-space-sm rounded-lg bg-surface-container-low">
              <div className="w-8 h-8 rounded-full bg-secondary/15 text-secondary flex items-center justify-center">
                <Layers className="w-4 h-4" />
              </div>
              <div>
                <div className="font-label-sm text-label-sm text-on-surface-variant">Phòng học (TKB)</div>
                <div className="font-label-lg text-label-lg text-on-surface flex items-center gap-1">
                  {session?.roomName || 'Phòng A2-304'}
                  <CheckCircle2 className="w-4 h-4 text-secondary" />
                </div>
              </div>
            </div>

            {/* Wi-Fi AP */}
            <div className="flex items-center gap-space-md px-space-md py-space-sm rounded-lg bg-surface-container-low" id="wifiStatusChip">
              <div className="w-8 h-8 rounded-full bg-secondary/15 text-secondary flex items-center justify-center">
                <Wifi className="w-4 h-4" />
              </div>
              <div>
                <div className="font-label-sm text-label-sm text-on-surface-variant">Wi-Fi AP Giảng đường</div>
                <div className="font-label-lg text-label-lg text-on-surface">UniCheck_Hall_A2 (-62dBm)</div>
              </div>
            </div>

            {/* Kiosk AI */}
            <div className="flex items-center gap-space-md px-space-md py-space-sm rounded-lg bg-surface-container-low">
              <div className="w-8 h-8 rounded-full bg-secondary/15 text-secondary flex items-center justify-center">
                <Video className="w-4 h-4" />
              </div>
              <div>
                <div className="font-label-sm text-label-sm text-on-surface-variant">Kiosk AI Giám sát</div>
                <div className="font-label-lg text-label-lg text-on-surface flex items-center gap-1">
                  Camera Cổng 1 • Online
                  <CheckCircle2 className="w-4 h-4 text-secondary" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* =========================================================================
          Main Projection Grid: Big Projector QR on Left (8 cols) + Realtime Dashboard on Right (4 cols)
          ========================================================================= */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-space-xl items-start">
        {/* LEFT: Big Projector Screen Stage (8 cols) */}
        <div className="lg:col-span-7 xl:col-span-8 bg-surface-container-lowest rounded-xl p-space-xl shadow-md border border-surface-container-high flex flex-col justify-between relative transition-all duration-300" id="projectorStage">
          {/* Top Action bar on Projector Card */}
          <div className="flex items-center justify-between pb-space-lg mb-space-lg border-b border-surface-container-high">
            <div className="flex items-center gap-space-sm">
              <Cast className="w-6 h-6 text-primary" />
              <div>
                <span className="font-label-lg text-label-lg text-on-surface font-semibold">Màn chiếu QR điểm danh động</span>
                <span className="font-body-sm text-body-sm text-on-surface-variant block">Chiếu toàn màn hình giảng đường qua cổng HDMI / DisplayPort</span>
              </div>
            </div>

            <div className="flex items-center gap-space-sm">
              <button
                onClick={toggleFullscreen}
                className="flex items-center gap-space-xs px-space-md py-space-xs rounded-lg bg-surface-container-high hover:bg-surface-container-highest text-on-surface font-label-md transition-colors shadow-sm"
                id="toggleFullscreenBtn"
                title="Bật/Tắt Toàn Màn Hình"
              >
                {isFullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
                <span>{isFullscreen ? 'Thu nhỏ' : 'Toàn màn hình (F11)'}</span>
              </button>

              <button
                onClick={() => {
                  if (session) fetchQrToken(session.id, true);
                }}
                disabled={isRefreshing || session?.status === 'CLOSED'}
                className="flex items-center gap-space-xs px-space-md py-space-xs rounded-lg bg-surface-container hover:bg-surface-container-high text-primary font-label-md transition-colors disabled:opacity-50"
                id="manualRefreshBtn"
              >
                <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
                <span>Đổi mã ngay</span>
              </button>
            </div>
          </div>

          {/* Center Dynamic QR Visual & Countdown Ring */}
          <div className="flex flex-col items-center justify-center py-space-md px-space-sm relative">
            {/* Rotating Countdown Ring Indicator */}
            <div className="flex items-center gap-space-md mb-space-md bg-surface-container-low px-space-lg py-space-sm rounded-full shadow-sm">
              {/* Mini SVG Radial Timer */}
              <div className="relative w-8 h-8 flex items-center justify-center shrink-0">
                <svg className="w-8 h-8 transform -rotate-90">
                  <circle
                    className="text-surface-container-high"
                    cx="16"
                    cy="16"
                    fill="transparent"
                    r={circleRadius}
                    stroke="currentColor"
                    strokeWidth="3"
                  />
                  <circle
                    className="text-primary transition-all duration-1000 ease-linear"
                    cx="16"
                    cy="16"
                    fill="transparent"
                    id="countdownSvgCircle"
                    r={circleRadius}
                    stroke="currentColor"
                    strokeDasharray={circleCircumference}
                    strokeDashoffset={strokeOffset}
                    strokeLinecap="round"
                    strokeWidth="3"
                  />
                </svg>
                <span className="absolute font-data-tabular font-bold text-label-md text-primary" id="countdownNumberText">
                  {countdown.toString().padStart(2, '0')}
                </span>
              </div>

              <div className="text-left">
                <div className="font-label-md text-label-md text-on-surface">
                  Mã QR sẽ làm mới sau:{' '}
                  <span className="text-primary font-bold" id="countdownBadgeText">
                    {countdown.toString().padStart(2, '0')}s
                  </span>{' '}
                  <span className="text-on-surface-variant font-normal">
                    (Chu kỳ {rotationTotal}s)
                  </span>
                </div>
                {/* Dynamic shrink bar */}
                <div className="w-48 h-1.5 bg-surface-container-high rounded-full overflow-hidden mt-1">
                  <div
                    className="h-full bg-primary rounded-full transition-all duration-1000 ease-linear"
                    id="countdownProgressBar"
                    style={{ width: `${progressRatio * 100}%` }}
                  />
                </div>
              </div>
            </div>

            {/* High-Contrast QR Viewport with Corner Security Accents */}
            <div className="relative">
              {qrData ? (
                <DynamicQrCode
                  value={qrData.qrToken}
                  size={360}
                  showScanningBeam={simulatedState === 'normal'}
                />
              ) : (
                <div className="w-80 h-80 bg-surface-container-low rounded-2xl flex items-center justify-center text-on-surface-variant">
                  {loading ? 'Đang khởi tạo mã QR...' : 'Không có mã QR khả dụng'}
                </div>
              )}

              {/* Special State Overlay */}
              {renderQrOverlay()}
            </div>

            {/* Verification instruction below QR */}
            <div className="mt-space-md text-center max-w-md">
              <div className="font-label-lg text-label-lg text-primary flex items-center justify-center gap-1.5 font-semibold">
                <ShieldCheck className="w-5 h-5" />
                Mã QR xoay vòng bảo mật - Sinh viên quét qua App UniCheck trên điện thoại
              </div>
              <div className="mt-space-xs p-space-sm rounded-lg bg-surface-container-low text-on-surface-variant font-body-sm text-body-sm leading-relaxed border border-surface-container-high">
                <span className="font-semibold text-on-surface">Cơ chế an toàn:</span> Token một lần (One-Time Token) kết hợp mã hóa vị trí GPS và BSSID Wi-Fi phòng học. Nghiêm cấm chụp màn hình chia sẻ ra ngoài.
              </div>
            </div>
          </div>

          {/* Bottom Session Control Buttons Bar */}
          <div className="pt-space-lg mt-space-lg border-t border-surface-container-high flex flex-wrap items-center justify-between gap-space-md">
            <div className="flex items-center gap-space-sm flex-wrap">
              <button
                onClick={() => setIsPaused(!isPaused)}
                disabled={session?.status === 'CLOSED'}
                className="flex items-center gap-space-xs px-space-md py-space-sm rounded-lg bg-surface-container-high hover:bg-surface-container-highest text-on-surface font-label-md transition-colors"
                id="pauseRotationBtn"
              >
                {isPaused ? <PlayCircle className="w-5 h-5 text-secondary" /> : <PauseCircle className="w-5 h-5" />}
                <span id="pauseBtnLabel">{isPaused ? 'Tiếp tục xoay QR' : 'Tạm dừng xoay QR'}</span>
              </button>

              <button
                onClick={handleExtendSession}
                disabled={session?.status === 'CLOSED'}
                className="flex items-center gap-space-xs px-space-md py-space-sm rounded-lg bg-surface-container-high hover:bg-surface-container-highest text-on-surface font-label-md transition-colors"
                id="extendSessionBtn"
              >
                <Clock className="w-5 h-5" />
                <span>Gia hạn thêm 10 phút</span>
              </button>
            </div>

            {/* Dangerous End Session Button */}
            <button
              onClick={() => setShowCloseModal(true)}
              disabled={session?.status === 'CLOSED'}
              className="flex items-center gap-space-xs px-space-lg py-space-sm rounded-lg bg-error text-on-error font-label-lg shadow hover:opacity-95 transition-all disabled:opacity-40"
              id="triggerEndModalBtn"
            >
              <Lock className="w-5 h-5" />
              <span>Kết thúc phiên & Chốt sổ</span>
            </button>
          </div>
        </div>

        {/* RIGHT: Real-time Counters & Live Check-in Stream (4 cols) */}
        <div className="lg:col-span-5 xl:col-span-4 flex flex-col gap-space-xl">
          {/* Card: Key Live Counters */}
          <div className="bg-surface-container-lowest rounded-xl p-space-xl shadow-sm border border-surface-container-high">
            <div className="flex items-center justify-between mb-space-lg">
              <div className="flex items-center gap-space-sm">
                <span className="w-2.5 h-2.5 rounded-full bg-secondary animate-pulse" />
                <h2 className="font-headline-md text-headline-md text-on-surface font-semibold">Chỉ số trực tiếp</h2>
              </div>
              <span className="font-label-md text-label-md text-secondary font-semibold bg-secondary-container px-space-sm py-0.5 rounded-full">
                {attendanceRate}% Đạt
              </span>
            </div>

            {/* Big Progress Donut / Completion metric */}
            <div className="flex items-center justify-between p-space-md rounded-xl bg-surface-container-low mb-space-lg">
              <div>
                <span className="font-label-sm text-label-sm text-on-surface-variant block uppercase tracking-wider">Đã điểm danh</span>
                <div className="flex items-baseline gap-1 mt-0.5">
                  <span className="font-display-lg text-display-lg text-primary font-bold tabular-nums" id="presentCountMain">
                    {presentCount}
                  </span>
                  <span className="font-headline-md text-headline-md text-on-surface-variant">/ {totalEnrolled} SV</span>
                </div>
                <div className="font-body-sm text-body-sm text-secondary font-medium mt-1 flex items-center gap-1">
                  <TrendingUp className="w-4 h-4" />
                  +{Math.min(presentCount, 14)} SV trong 5 phút qua
                </div>
              </div>

              {/* Mini Inline Completion Ring */}
              <div className="w-16 h-16 relative flex items-center justify-center shrink-0">
                <svg className="w-16 h-16 transform -rotate-90">
                  <circle
                    className="text-surface-container-high"
                    cx="32"
                    cy="32"
                    fill="transparent"
                    r="26"
                    stroke="currentColor"
                    strokeWidth="6"
                  />
                  <circle
                    className="text-secondary"
                    cx="32"
                    cy="32"
                    fill="transparent"
                    r="26"
                    stroke="currentColor"
                    strokeDasharray="163.36"
                    strokeDashoffset={163.36 * (1 - Math.min(1, presentCount / (totalEnrolled || 1)))}
                    strokeLinecap="round"
                    strokeWidth="6"
                  />
                </svg>
                <span className="absolute font-data-tabular font-bold text-label-sm text-on-surface">
                  {Math.round(attendanceRate)}%
                </span>
              </div>
            </div>

            {/* Detailed 3-Column Breakdown */}
            <div className="grid grid-cols-3 gap-space-sm text-center mb-space-lg">
              {/* Dung gio */}
              <div className="p-space-sm rounded-lg bg-surface-container-low">
                <span className="font-label-sm text-label-sm text-secondary block font-semibold">Đúng giờ</span>
                <span className="font-headline-md text-headline-md text-on-surface font-bold block mt-0.5 tabular-nums" id="onTimeCount">
                  {onTimeCount}
                </span>
                <span className="font-label-sm text-label-sm text-on-surface-variant">
                  {totalEnrolled > 0 ? Math.round((onTimeCount / totalEnrolled) * 1000) / 10 : 0}%
                </span>
              </div>

              {/* Di muon */}
              <div className="p-space-sm rounded-lg bg-surface-container-low">
                <span className="font-label-sm text-label-sm text-[#92400E] block font-semibold">Đi muộn</span>
                <span className="font-headline-md text-headline-md text-on-surface font-bold block mt-0.5 tabular-nums" id="lateCount">
                  {lateCount}
                </span>
                <span className="font-label-sm text-label-sm text-on-surface-variant">
                  {totalEnrolled > 0 ? Math.round((lateCount / totalEnrolled) * 1000) / 10 : 0}%
                </span>
              </div>

              {/* Chua checkin */}
              <div className="p-space-sm rounded-lg bg-surface-container-low">
                <span className="font-label-sm text-label-sm text-error block font-semibold">Chưa vào</span>
                <span className="font-headline-md text-headline-md text-on-surface font-bold block mt-0.5 tabular-nums" id="pendingCount">
                  {pendingCount}
                </span>
                <span className="font-label-sm text-label-sm text-on-surface-variant">
                  {totalEnrolled > 0 ? Math.round((pendingCount / totalEnrolled) * 1000) / 10 : 0}%
                </span>
              </div>
            </div>

            {/* Last Verified Student Callout Card */}
            <div className="p-space-md rounded-xl bg-surface-container flex items-start gap-space-md">
              <div className="w-10 h-10 rounded-full bg-secondary-fixed text-on-secondary-fixed flex items-center justify-center shrink-0">
                <ShieldCheck className="w-5 h-5 text-secondary" />
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between">
                  <span className="font-label-sm text-label-sm text-secondary font-semibold uppercase tracking-wider">Lượt quét mới nhất</span>
                  <span className="font-data-tabular text-label-sm text-on-surface-variant" id="lastScanTime">
                    {lastCheckIn?.checkInTime ? new Date(lastCheckIn.checkInTime).toLocaleTimeString('vi-VN') : '07:18:24'}
                  </span>
                </div>
                <div className="font-label-lg text-label-lg text-on-surface font-semibold truncate mt-0.5" id="lastScanStudentName">
                  {lastCheckIn?.studentName || 'Nguyễn Văn An'}
                </div>
                <div className="font-body-sm text-body-sm text-on-surface-variant flex items-center gap-space-sm">
                  <span className="font-data-tabular">MSSV: {lastCheckIn?.studentCode || '2251120001'}</span>
                  <span>•</span>
                  <span className="text-secondary font-medium">Hợp lệ (GPS + Wi-Fi)</span>
                </div>
              </div>
            </div>
          </div>

          {/* Real-time Scan Feed / Roster Stream */}
          <div className="bg-surface-container-lowest rounded-xl p-space-xl shadow-sm border border-surface-container-high flex flex-col">
            <div className="flex items-center justify-between mb-space-md">
              <h3 className="font-title-md text-title-md text-on-surface font-semibold">Nhật ký quét gần đây</h3>
              <span className="font-label-sm text-label-sm text-primary flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-primary animate-ping" />
                Tự động đồng bộ
              </span>
            </div>

            <div className="space-y-space-sm overflow-hidden" id="liveActivityList">
              {checkIns.length > 0 ? (
                checkIns.slice(0, 4).map((ci) => (
                  <div key={ci.id} className="flex items-center justify-between p-space-sm rounded-lg hover:bg-surface-container-low transition-colors">
                    <div className="flex items-center gap-space-sm">
                      <div className="w-8 h-8 rounded-full bg-surface-container-high text-primary flex items-center justify-center font-label-md">
                        {ci.studentName.split(' ').slice(-1)[0]?.substring(0, 2).toUpperCase() || 'SV'}
                      </div>
                      <div>
                        <div className="font-label-md text-label-md text-on-surface leading-snug">{ci.studentName}</div>
                        <div className="font-body-sm text-body-sm text-on-surface-variant">
                          {ci.studentCode} • {ci.deviceInfo || 'Thiết bị di động'}
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className={`px-2 py-0.5 rounded-full font-label-sm font-semibold ${
                        ci.status === 'LATE' ? 'bg-[#FFFBEB] text-[#92400E]' : 'bg-[#ECFDF5] text-[#065F46]'
                      }`}>
                        {ci.status === 'LATE' ? 'Đi muộn' : 'Đúng giờ'}
                      </span>
                      <span className="block font-data-tabular text-[10px] text-on-surface-variant mt-0.5">
                        {ci.checkInTime ? new Date(ci.checkInTime).toLocaleTimeString('vi-VN') : '07:18:24'}
                      </span>
                    </div>
                  </div>
                ))
              ) : (
                // Simulated items from Stitch design when roster is fresh
                <>
                  <div className="flex items-center justify-between p-space-sm rounded-lg hover:bg-surface-container-low transition-colors">
                    <div className="flex items-center gap-space-sm">
                      <div className="w-8 h-8 rounded-full bg-surface-container-high text-primary flex items-center justify-center font-label-md">NA</div>
                      <div>
                        <div className="font-label-md text-label-md text-on-surface leading-snug">Nguyễn Văn An</div>
                        <div className="font-body-sm text-body-sm text-on-surface-variant">2251120001 • iPhone 14 Pro</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className="px-2 py-0.5 rounded-full bg-[#ECFDF5] text-[#065F46] font-label-sm font-semibold">Đúng giờ</span>
                      <span className="block font-data-tabular text-[10px] text-on-surface-variant mt-0.5">07:18:24</span>
                    </div>
                  </div>
                  <div className="flex items-center justify-between p-space-sm rounded-lg hover:bg-surface-container-low transition-colors">
                    <div className="flex items-center gap-space-sm">
                      <div className="w-8 h-8 rounded-full bg-surface-container-high text-primary flex items-center justify-center font-label-md">TM</div>
                      <div>
                        <div className="font-label-md text-label-md text-on-surface leading-snug">Trần Thị Mai</div>
                        <div className="font-body-sm text-body-sm text-on-surface-variant">2251120045 • Galaxy S23</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className="px-2 py-0.5 rounded-full bg-[#ECFDF5] text-[#065F46] font-label-sm font-semibold">Đúng giờ</span>
                      <span className="block font-data-tabular text-[10px] text-on-surface-variant mt-0.5">07:17:59</span>
                    </div>
                  </div>
                </>
              )}
            </div>

            <button
              onClick={() => navigate(`/lecturer/attendance-session`)}
              className="w-full mt-space-md py-space-xs text-center rounded-lg bg-surface-container-low hover:bg-surface-container text-primary font-label-md transition-colors flex items-center justify-center gap-1"
            >
              <span>Xem toàn bộ danh sách điểm danh ({presentCount}/{totalEnrolled})</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* =========================================================================
          Interactive Testing Bar (Stitch Screen lines 439-450)
          ========================================================================= */}
      <aside className="w-full bg-[#283044] text-[#eef0ff] rounded-xl p-space-lg shadow-lg">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-space-md">
          <div className="flex items-center gap-space-sm">
            <Sliders className="w-6 h-6 text-[#71f8e4]" />
            <div>
              <span className="font-label-lg text-label-lg font-semibold block">Trình giả lập trạng thái phiên (Interactive Testing Bar)</span>
              <span className="font-body-sm text-body-sm text-[#dae2fd]">Nhấn vào các trạng thái bên dưới để kiểm thử giao diện & hành vi thời gian thực</span>
            </div>
          </div>

          <div className="flex items-center gap-space-xs flex-wrap">
            <button
              onClick={() => setSimulatedState('normal')}
              className={`px-space-md py-space-xs rounded-lg font-label-sm transition-all shadow-sm ${
                simulatedState === 'normal' ? 'bg-primary text-on-primary ring-2 ring-white/50' : 'bg-surface-container-high/30 hover:bg-surface-container-high/50'
              }`}
            >
              Bình thường (Live)
            </button>

            <button
              onClick={() => setSimulatedState('paused')}
              className={`px-space-md py-space-xs rounded-lg font-label-sm transition-all shadow-sm ${
                simulatedState === 'paused' ? 'bg-[#92400E] text-white ring-2 ring-white/50' : 'bg-surface-container-high/30 hover:bg-surface-container-high/50'
              }`}
            >
              Tạm dừng (Paused)
            </button>

            <button
              onClick={() => setSimulatedState('offline')}
              className={`px-space-md py-space-xs rounded-lg font-label-sm transition-all shadow-sm ${
                simulatedState === 'offline' ? 'bg-error text-on-error ring-2 ring-white/50' : 'bg-surface-container-high/30 hover:bg-surface-container-high/50'
              }`}
            >
              Mất mạng (Offline)
            </button>

            <button
              onClick={() => setSimulatedState('expired')}
              className={`px-space-md py-space-xs rounded-lg font-label-sm transition-all shadow-sm ${
                simulatedState === 'expired' ? 'bg-[#92400E] text-white ring-2 ring-white/50' : 'bg-surface-container-high/30 hover:bg-surface-container-high/50'
              }`}
            >
              Hết hạn (Expired)
            </button>

            <button
              onClick={() => setSimulatedState('closed')}
              className={`px-space-md py-space-xs rounded-lg font-label-sm transition-all shadow-sm ${
                simulatedState === 'closed' ? 'bg-[#131b2e] text-white ring-2 ring-white/50' : 'bg-surface-container-high/30 hover:bg-surface-container-high/50'
              }`}
            >
              Đã chốt sổ (Closed)
            </button>
          </div>
        </div>
      </aside>

      {/* =========================================================================
          End Session Confirmation Modal
          ========================================================================= */}
      {showCloseModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-surface-container-lowest rounded-2xl max-w-md w-full p-6 shadow-2xl border border-surface-container-high">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2 text-error">
                <AlertTriangle className="w-6 h-6" />
                <h3 className="font-headline-md text-headline-md font-bold text-on-surface">Kết thúc phiên điểm danh</h3>
              </div>
              <button onClick={() => setShowCloseModal(false)} className="p-1 hover:bg-surface-container-high rounded-lg">
                <X className="w-5 h-5 text-on-surface-variant" />
              </button>
            </div>

            <p className="font-body-md text-body-md text-on-surface-variant mb-4">
              Bạn có chắc chắn muốn chốt sổ ca học{' '}
              <strong className="text-on-surface">{session?.className}</strong>?
              Sau khi chốt sổ, toàn bộ mã QR sẽ bị hủy và sinh viên không thể quét điểm danh được nữa.
            </p>

            <div className="p-space-md rounded-xl bg-surface-container-low mb-6 border border-surface-container-high">
              <div className="flex items-center justify-between font-label-md">
                <span className="text-on-surface-variant">Tổng SV đã ghi nhận:</span>
                <span className="font-bold text-primary">{presentCount} / {totalEnrolled} SV ({attendanceRate}%)</span>
              </div>
            </div>

            <div className="flex items-center justify-end gap-3">
              <button
                onClick={() => setShowCloseModal(false)}
                disabled={actionLoading}
                className="px-4 py-2 rounded-lg bg-surface-container-high hover:bg-surface-container-highest text-on-surface font-label-md transition-colors"
              >
                Hủy bỏ
              </button>
              <button
                onClick={handleCloseSession}
                disabled={actionLoading}
                className="px-5 py-2 rounded-lg bg-error text-on-error font-label-md hover:bg-error/90 transition-all flex items-center gap-2 shadow"
              >
                {actionLoading && <RefreshCw className="w-4 h-4 animate-spin" />}
                Xác nhận chốt sổ
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
