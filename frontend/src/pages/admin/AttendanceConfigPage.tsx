// ==============================================================================
// UniCheck - Attendance Configuration Page (TASK-05)
// Stitch Screen ID: 300c3071598340e5981a9a5f5097f909
// Route: /admin/attendance/configs & /dashboard/attendance-configs
// ==============================================================================

import React, { useState, useEffect, useCallback } from 'react';
import {
  CheckCircle2,
  Clock,
  RotateCcw,
  Save,
  ShieldCheck,
  Sliders,
  Sparkles,
  Wifi,
  QrCode,
  ScanFace,
  AlertTriangle,
  X,
  Lock,
  RefreshCw,
  HelpCircle,
  AlertCircle,
} from 'lucide-react';
import { useAuthStore } from '../../store/auth-store';
import { getAttendanceConfigApi, updateAttendanceConfigApi } from '../../api/attendance.api';
import { AttendanceConfigDto } from '../../types/api';

const DEFAULT_ATTENDANCE_CONFIG: AttendanceConfigDto = {
  configKey: 'DEFAULT',
  qrRotationIntervalSeconds: 5,
  ticketTtlSeconds: 90,
  faceThresholdPercent: 85,
  livenessEnabled: true,
  kioskScanMode: 'CONTINUOUS',
  absentThresholdMinutes: 30,
  lateThresholdMinutes: 15,
  minAttendancePercentage: 80.0,
  manualEnabled: true,
  faceRecognitionEnabled: true,
  qrCodeEnabled: true,
  wifiLocationEnabled: true,
  allowedIpSubnet: '10.20.0.0/16',
  maxAttempts: 3,
};

export const AttendanceConfigPage: React.FC = () => {
  const user = useAuthStore((state) => state.user);
  const [config, setConfig] = useState<AttendanceConfigDto>(DEFAULT_ATTENDANCE_CONFIG);
  const [initialConfig, setInitialConfig] = useState<AttendanceConfigDto>(DEFAULT_ATTENDANCE_CONFIG);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [isDirty, setIsDirty] = useState(false);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fetchConfig = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await getAttendanceConfigApi();
      if (res.success && res.data) {
        setConfig(res.data);
        setInitialConfig(res.data);
        setIsDirty(false);
      }
    } catch (err: any) {
      setError(err?.message || 'Không thể tải cấu hình cơ chế điểm danh');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchConfig();
  }, [fetchConfig]);

  const updateField = <K extends keyof AttendanceConfigDto>(field: K, value: AttendanceConfigDto[K]) => {
    setConfig((prev) => ({ ...prev, [field]: value }));
    setIsDirty(true);
  };

  const handleResetToStandard = () => {
    setConfig(DEFAULT_ATTENDANCE_CONFIG);
    setIsDirty(true);
  };

  const handleDiscard = () => {
    setConfig(initialConfig);
    setIsDirty(false);
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      const res = await updateAttendanceConfigApi(config);
      if (res.success && res.data) {
        setConfig(res.data);
        setInitialConfig(res.data);
        setIsDirty(false);
        setShowConfirmModal(false);
        setSuccessMessage('Đã cập nhật và ký số cấu hình cơ chế điểm danh hệ thống thành công');
        setTimeout(() => setSuccessMessage(null), 5000);
      }
    } catch (err: any) {
      setError(err?.message || 'Lỗi khi lưu cấu hình điểm danh');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="flex flex-col w-full min-h-screen bg-[#faf8ff] p-6 lg:p-8">
      {/* 1. Header & Live Status */}
      <div className="flex flex-col gap-4 mb-6">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-3 flex-wrap">
              <h1 className="text-2xl lg:text-3xl font-bold text-slate-900 tracking-tight">
                Thiết lập & Cấu hình Cơ chế Điểm danh Động
              </h1>
              <span
                className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold border shadow-sm transition-all ${
                  isDirty
                    ? 'bg-amber-50 text-amber-700 border-amber-200'
                    : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                }`}
              >
                <span
                  className={`w-2 h-2 rounded-full ${isDirty ? 'bg-amber-500 animate-pulse' : 'bg-emerald-500'}`}
                />
                {isDirty ? 'Có thay đổi chưa lưu' : 'Chế độ: Đã lưu (Đồng bộ)'}
              </span>
            </div>
            <p className="text-sm text-slate-600 max-w-4xl mt-1">
              Tùy biến tham số thuật toán nhận diện khuôn mặt AI, chu kỳ xoay vòng mã QR bảo mật cao cấp, chính sách ràng buộc định vị mạng phòng học và quy chuẩn tính giờ chuyên cần theo quy chế đào tạo tín chỉ.
            </p>
          </div>

          {/* Action Group */}
          <div className="flex items-center gap-2 shrink-0 flex-wrap">
            <button
              type="button"
              onClick={handleResetToStandard}
              className="h-10 px-4 rounded-lg bg-white border border-slate-200 text-slate-700 font-medium text-sm hover:bg-slate-50 transition-colors flex items-center gap-2 shadow-sm"
            >
              <RotateCcw className="w-4 h-4 text-slate-500" />
              <span>Khôi phục mặc định</span>
            </button>

            {isDirty && (
              <button
                type="button"
                onClick={handleDiscard}
                className="h-10 px-4 rounded-lg bg-white border border-slate-200 text-slate-600 hover:text-red-600 hover:bg-red-50 text-sm font-medium transition-colors shadow-sm flex items-center gap-1.5"
              >
                <X className="w-4 h-4" />
                <span>Hủy bỏ</span>
              </button>
            )}

            <button
              type="button"
              onClick={() => setShowConfirmModal(true)}
              className="h-10 px-5 rounded-lg bg-blue-600 text-white font-semibold text-sm hover:bg-blue-700 transition-all flex items-center gap-2 shadow-md hover:shadow-lg"
            >
              <ShieldCheck className="w-4 h-4" />
              <span>Lưu cấu hình hệ thống</span>
            </button>
          </div>
        </div>

        {/* Notifications */}
        {successMessage && (
          <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 flex items-center justify-between shadow-sm animate-fadeIn">
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
          <div className="p-4 rounded-xl bg-red-50 border border-red-200 text-red-800 flex items-center justify-between shadow-sm animate-fadeIn">
            <div className="flex items-center gap-2 font-medium text-sm">
              <AlertCircle className="w-5 h-5 text-red-600 shrink-0" />
              <span>{error}</span>
            </div>
            <button type="button" onClick={() => setError(null)}>
              <X className="w-4 h-4 text-red-600" />
            </button>
          </div>
        )}

        {/* Security Audit Warning Banner */}
        <div className="rounded-xl bg-white p-4 shadow-sm border-l-4 border-l-blue-600 border border-slate-200/80 flex items-start gap-4">
          <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center shrink-0 text-blue-600">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-0.5">
              <span className="font-semibold text-slate-900 text-sm">Quy chuẩn Bảo mật & Kiểm toán Học vụ</span>
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-blue-600 text-white uppercase tracking-wider">
                Level 3 Audit
              </span>
            </div>
            <p className="text-xs text-slate-600 leading-relaxed">
              Lưu ý: Mọi thay đổi tham số bảo mật hệ thống sẽ được ký số và ghi lại trực tiếp vào{' '}
              <span className="font-semibold text-blue-700">Nhật ký kiểm toán (Audit Log)</span> theo định danh tài khoản quản trị{' '}
              <span className="font-mono text-slate-900 font-semibold">{user?.email || 'admin@unicheck.edu.vn'}</span>. Cấu hình sẽ tự động kích hoạt có hiệu lực ngay trong phiên học tiếp theo của toàn bộ giảng đường.
            </p>
          </div>
          <div className="hidden sm:flex items-center gap-1 text-slate-400 text-xs shrink-0 font-mono">
            <Lock className="w-3.5 h-3.5" />
            <span>Hash SHA-256</span>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="py-24 flex flex-col items-center justify-center text-slate-400 gap-3">
          <RefreshCw className="w-8 h-8 animate-spin text-blue-600" />
          <p className="text-sm">Đang tải cấu hình hệ thống...</p>
        </div>
      ) : (
        /* 2. Main Settings Bento Grid */
        <div className="grid grid-cols-1 xl:grid-cols-12 gap-6">
          {/* LEFT COLUMN: Security Mechanisms (Groups 1 & 2) */}
          <div className="xl:col-span-7 flex flex-col gap-6">
            {/* CARD 1: Dynamic QR Code Security */}
            <div className="rounded-xl bg-white p-6 shadow-sm border border-slate-200/80 flex flex-col gap-5 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-teal-50 flex items-center justify-center text-teal-600">
                    <QrCode className="w-6 h-6" />
                  </div>
                  <div>
                    <span className="text-xs text-teal-600 uppercase tracking-wider font-semibold">
                      Phân khu Bảo mật 01
                    </span>
                    <h2 className="text-base font-bold text-slate-900">
                      Cơ chế Mã QR Động & Chống Gian Lận (Dynamic QR)
                    </h2>
                  </div>
                </div>

                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={config.qrCodeEnabled}
                    onChange={(e) => updateField('qrCodeEnabled', e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-teal-600" />
                </label>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                {/* QR Rotation Slider */}
                <div className="flex flex-col justify-between bg-slate-50 p-4 rounded-lg gap-2 border border-slate-100">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="font-semibold text-slate-900 text-sm">Chu kỳ xoay vòng QR</span>
                      <span className="text-xs text-slate-500 block">Tần suất làm mới mã hash sinh học</span>
                    </div>
                    <div className="flex items-center gap-1 bg-white px-2.5 py-1 rounded-md shadow-xs border border-slate-200 font-mono font-bold text-blue-700 text-sm">
                      <span>{config.qrRotationIntervalSeconds}</span>
                      <span className="text-xs text-slate-500 font-normal">giây</span>
                    </div>
                  </div>
                  <input
                    type="range"
                    min="3"
                    max="20"
                    step="1"
                    value={config.qrRotationIntervalSeconds}
                    onChange={(e) => updateField('qrRotationIntervalSeconds', Number(e.target.value))}
                    className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-teal-600"
                  />
                  <div className="flex justify-between text-[11px] text-slate-500 font-mono pt-1">
                    <span>3s (Cực cao)</span>
                    <span className="text-teal-700 font-semibold">Khuyến nghị: 5s - 10s</span>
                    <span>20s</span>
                  </div>
                  <p className="text-xs text-slate-500 pt-2 border-t border-slate-200/80">
                    <span className="font-semibold text-teal-700">Ngăn chặn triệt để:</span> Triệt tiêu khả năng chụp ảnh chia sẻ vào nhóm ngoài giảng đường.
                  </p>
                </div>

                {/* Ticket Expiry */}
                <div className="flex flex-col justify-between bg-slate-50 p-4 rounded-lg gap-2 border border-slate-100">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="font-semibold text-slate-900 text-sm">Thời gian sống vé (Ticket TTL)</span>
                      <span className="text-xs text-slate-500 block">Hiệu lực token điểm danh đơn kỳ</span>
                    </div>
                    <div className="flex items-center gap-1 bg-white px-2.5 py-1 rounded-md shadow-xs border border-slate-200 font-mono font-bold text-blue-700 text-sm">
                      <span>{config.ticketTtlSeconds}</span>
                      <span className="text-xs text-slate-500 font-normal">giây</span>
                    </div>
                  </div>
                  <input
                    type="range"
                    min="30"
                    max="300"
                    step="15"
                    value={config.ticketTtlSeconds}
                    onChange={(e) => updateField('ticketTtlSeconds', Number(e.target.value))}
                    className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-blue-600"
                  />
                  <div className="flex justify-between text-[11px] text-slate-500 font-mono pt-1">
                    <span>30s</span>
                    <span className="text-blue-700 font-semibold">Mặc định: 90s</span>
                    <span>300s</span>
                  </div>
                  <p className="text-xs text-slate-500 pt-2 border-t border-slate-200/80">
                    Token 1-Time Nonce kết hợp Timestamp thiết bị. Quá hạn tự hủy không thể tái sử dụng.
                  </p>
                </div>
              </div>

              {/* Encryption Info */}
              <div className="rounded-lg bg-slate-50 p-3.5 border border-slate-100 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 text-xs">
                <div className="flex items-center gap-2.5">
                  <Lock className="w-5 h-5 text-blue-600 shrink-0" />
                  <div>
                    <span className="font-semibold text-slate-900">
                      Giao thức mật mã: QR Token Payload Signing
                    </span>
                    <span className="text-slate-500 block">Khóa xoay vòng 24h. Payload chống dịch ngược.</span>
                  </div>
                </div>
                <span className="px-2.5 py-1 rounded-md bg-white border border-slate-200 font-mono font-bold text-slate-700 text-[11px]">
                  Bảo mật cao
                </span>
              </div>
            </div>

            {/* CARD 2: AI FaceMatch & Liveness Detection */}
            <div className="rounded-xl bg-white p-6 shadow-sm border border-slate-200/80 flex flex-col gap-5 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center text-blue-600">
                    <ScanFace className="w-6 h-6" />
                  </div>
                  <div>
                    <span className="text-xs text-blue-600 uppercase tracking-wider font-semibold">
                      Phân khu Trí tuệ Nhân tạo 02
                    </span>
                    <h2 className="text-base font-bold text-slate-900">
                      Thuật toán Nhận diện Khuôn mặt (FaceMatch & Liveness)
                    </h2>
                  </div>
                </div>

                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={config.faceRecognitionEnabled}
                    onChange={(e) => updateField('faceRecognitionEnabled', e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600" />
                </label>
              </div>

              {/* Face Threshold */}
              <div className="bg-slate-50 p-4 rounded-lg space-y-3 border border-slate-100">
                <div className="flex items-center justify-between">
                  <div>
                    <span className="font-semibold text-slate-900 text-sm">Ngưỡng tương đồng khuôn mặt</span>
                    <p className="text-xs text-slate-500">Độ khắt khe khi so khớp vector khuôn mặt (ArcFace MobileFaceNet)</p>
                  </div>
                  <div className="flex items-baseline gap-1 bg-white px-3 py-1 rounded-md shadow-xs border border-slate-200 font-mono font-bold text-blue-700 text-lg">
                    <span>{config.faceThresholdPercent}</span>
                    <span className="text-xs text-slate-500 font-normal">%</span>
                  </div>
                </div>

                <input
                  type="range"
                  min="70"
                  max="99"
                  step="1"
                  value={config.faceThresholdPercent}
                  onChange={(e) => updateField('faceThresholdPercent', Number(e.target.value))}
                  className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-blue-600"
                />

                <div className="flex justify-between font-mono text-[11px] text-slate-500">
                  <span>70% (Lỏng lẻo)</span>
                  <span className="text-blue-700 font-bold">85% (Khuyến nghị)</span>
                  <span>99% (Cực đoan)</span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
                  <div className="p-2.5 rounded bg-white border border-slate-200 flex items-center justify-between text-xs">
                    <span className="text-slate-500">Tỷ lệ nhận nhầm (FAR):</span>
                    <span className="font-mono font-bold text-slate-900">&lt; 0.001% (An toàn)</span>
                  </div>
                  <div className="p-2.5 rounded bg-white border border-slate-200 flex items-center justify-between text-xs">
                    <span className="text-slate-500">Tỷ lệ từ chối nhầm (FRR):</span>
                    <span className="font-mono font-bold text-slate-900">~ 1.12% (Ổn định)</span>
                  </div>
                </div>
              </div>

              {/* Liveness & Scan mode */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-4 rounded-lg bg-slate-50 border border-slate-100 flex items-start justify-between gap-3">
                  <div>
                    <span className="font-semibold text-slate-900 text-sm">Chống giả mạo sinh trắc học</span>
                    <p className="text-xs text-slate-500 mt-1">
                      AI Active Liveness: Ngăn chặn ảnh chụp, video phát lại và mặt nạ silicon.
                    </p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer shrink-0">
                    <input
                      type="checkbox"
                      checked={config.livenessEnabled}
                      onChange={(e) => updateField('livenessEnabled', e.target.checked)}
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600" />
                  </label>
                </div>

                <div className="p-4 rounded-lg bg-slate-50 border border-slate-100 flex flex-col justify-between gap-2">
                  <span className="font-semibold text-slate-900 text-sm">Chế độ quét Kiosk tại cửa phòng</span>
                  <select
                    value={config.kioskScanMode}
                    onChange={(e) => updateField('kioskScanMode', e.target.value)}
                    className="w-full h-9 px-3 rounded-lg bg-white border border-slate-200 text-slate-800 text-xs focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="CONTINUOUS">Quét liên tục (Continuous auto-detect)</option>
                    <option value="TRIGGERED">Chạm màn hình để quét (Triggered on-tap)</option>
                  </select>
                </div>
              </div>
            </div>
          </div>

          {/* RIGHT COLUMN: Physical Geofencing & Academic Policy (Groups 3 & 4) */}
          <div className="xl:col-span-5 flex flex-col gap-6">
            {/* CARD 3: Network & Physical Room Geofencing */}
            <div className="rounded-xl bg-white p-6 shadow-sm border border-slate-200/80 flex flex-col gap-5 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-indigo-50 flex items-center justify-center text-indigo-600">
                    <Wifi className="w-6 h-6" />
                  </div>
                  <div>
                    <span className="text-xs text-indigo-600 uppercase tracking-wider font-semibold">
                      Phân khu Hạ tầng 03
                    </span>
                    <h2 className="text-base font-bold text-slate-900">Ràng buộc Định vị Wi-Fi & Mạng</h2>
                  </div>
                </div>

                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={config.wifiLocationEnabled}
                    onChange={(e) => updateField('wifiLocationEnabled', e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600" />
                </label>
              </div>

              <div className="flex flex-col gap-4 text-xs">
                <div>
                  <label className="block font-semibold text-slate-700 uppercase mb-1">
                    Dải mạng Wi-Fi hợp lệ (Allowed Subnet)
                  </label>
                  <input
                    type="text"
                    value={config.allowedIpSubnet || ''}
                    onChange={(e) => updateField('allowedIpSubnet', e.target.value)}
                    placeholder="10.20.0.0/16"
                    className="w-full h-10 px-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-800 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <span className="text-slate-400 mt-1 block">
                    Chỉ cho phép sinh viên kết nối Wi-Fi giảng đường thực hiện điểm danh.
                  </span>
                </div>

                <div>
                  <label className="block font-semibold text-slate-700 uppercase mb-1">
                    Số lần thử tối đa trước khi khóa ca (Max Attempts)
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="10"
                    value={config.maxAttempts}
                    onChange={(e) => updateField('maxAttempts', Number(e.target.value))}
                    className="w-full h-10 px-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-800 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
            </div>

            {/* CARD 4: Credit Regulation & Absence Thresholds */}
            <div className="rounded-xl bg-white p-6 shadow-sm border border-slate-200/80 flex flex-col gap-5 hover:shadow-md transition-shadow">
              <div className="flex items-center gap-3 pb-3 border-b border-slate-100">
                <div className="w-10 h-10 rounded-lg bg-amber-50 flex items-center justify-center text-amber-600">
                  <Clock className="w-6 h-6" />
                </div>
                <div>
                  <span className="text-xs text-amber-600 uppercase tracking-wider font-semibold">
                    Quy chế Đào tạo 04
                  </span>
                  <h2 className="text-base font-bold text-slate-900">Quy chuẩn Chuyên cần Tín chỉ</h2>
                </div>
              </div>

              <div className="flex flex-col gap-4 text-xs">
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <label className="font-semibold text-slate-700 uppercase">
                      Tỷ lệ chuyên cần tối thiểu dự thi
                    </label>
                    <span className="font-mono font-bold text-blue-700 text-sm">
                      {config.minAttendancePercentage}%
                    </span>
                  </div>
                  <input
                    type="range"
                    min="50"
                    max="90"
                    step="5"
                    value={config.minAttendancePercentage}
                    onChange={(e) => updateField('minAttendancePercentage', Number(e.target.value))}
                    className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-amber-600"
                  />
                  <span className="text-slate-400 mt-1 block">
                    Vắng quá 20% số tiết học phần sẽ tự động bị đình chỉ tư cách thi cuối kỳ.
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block font-semibold text-slate-700 uppercase mb-1">
                      Giới hạn trễ (phút)
                    </label>
                    <input
                      type="number"
                      min="5"
                      max="60"
                      value={config.lateThresholdMinutes}
                      onChange={(e) => updateField('lateThresholdMinutes', Number(e.target.value))}
                      className="w-full h-10 px-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-800 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block font-semibold text-slate-700 uppercase mb-1">
                      Tính vắng mặt sau (phút)
                    </label>
                    <input
                      type="number"
                      min="10"
                      max="120"
                      value={config.absentThresholdMinutes}
                      onChange={(e) => updateField('absentThresholdMinutes', Number(e.target.value))}
                      className="w-full h-10 px-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-800 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>

                <div className="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-slate-100">
                  <div>
                    <span className="font-semibold text-slate-900">Cho phép giảng viên điểm danh thủ công</span>
                    <span className="text-slate-500 block">Dành cho trường hợp miễn giảm hoặc lỗi thiết bị</span>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={config.manualEnabled}
                      onChange={(e) => updateField('manualEnabled', e.target.checked)}
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600" />
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      {showConfirmModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-xs p-4 animate-fadeIn">
          <div className="w-full max-w-md bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden flex flex-col">
            <div className="p-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-blue-600" />
                <h3 className="font-bold text-slate-900 text-base">Xác nhận cập nhật cấu hình</h3>
              </div>
              <button
                type="button"
                onClick={() => setShowConfirmModal(false)}
                className="w-8 h-8 rounded-lg hover:bg-slate-200 flex items-center justify-center text-slate-500"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-5 text-sm text-slate-600 flex flex-col gap-3">
              <p>
                Bạn có chắc chắn muốn áp dụng các thay đổi cấu hình cơ chế điểm danh này trên toàn bộ hệ thống không?
              </p>
              <div className="p-3 bg-blue-50 text-blue-800 rounded-lg text-xs leading-relaxed">
                Hành động này sẽ được ghi nhận vào Nhật ký kiểm toán (Audit Trail) của hệ thống UniCheck.
              </div>
            </div>

            <div className="p-4 border-t border-slate-100 bg-slate-50/60 flex items-center justify-end gap-2">
              <button
                type="button"
                onClick={() => setShowConfirmModal(false)}
                className="px-4 py-2 rounded-lg border border-slate-200 hover:bg-slate-100 text-slate-700 text-sm font-medium"
              >
                Hủy bỏ
              </button>
              <button
                type="button"
                disabled={saving}
                onClick={handleSave}
                className="px-5 py-2 rounded-lg bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold disabled:opacity-50 transition-colors shadow-sm"
              >
                {saving ? 'Đang lưu...' : 'Xác nhận áp dụng'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AttendanceConfigPage;
