import React, { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import {
  User,
  Lock,
  ArrowRight,
  ScanFace,
  ShieldCheck,
  QrCode,
  Sparkles,
  School,
  CheckCircle2,
  AlertCircle,
  Eye,
  EyeOff,
} from 'lucide-react';
import { useAuthStore } from '../../store/auth-store';
import { loginApi } from '../../api/auth.api';

// Error message mapping according to UniCheck ErrorCode dictionary
const getFriendlyErrorMessage = (err: any): string => {
  const code = err?.response?.data?.errorCode || err?.errorCode;
  const rawMsg = err?.response?.data?.message || err?.message;

  switch (code) {
    case 'ERR_2002':
      return 'Tên đăng nhập hoặc mật khẩu không chính xác. Vui lòng thử lại.';
    case 'ERR_2003':
      return 'Tài khoản của bạn hiện đang bị khóa. Vui lòng liên hệ Phòng Đào tạo.';
    case 'ERR_2004':
      return 'Tài khoản chưa được kích hoạt trong hệ thống.';
    case 'ERR_2007':
      return 'Quá nhiều lần thử đăng nhập thất bại. Vui lòng thử lại sau 15 phút.';
    case 'ERR_2000':
      return 'Yêu cầu đăng nhập hoặc phiên làm việc không hợp lệ.';
    case 'ERR_1001':
      return 'Dữ liệu gửi lên không hợp lệ. Vui lòng kiểm tra lại.';
    default:
      return rawMsg || 'Không thể kết nối đến máy chủ xác thực. Vui lòng thử lại sau.';
  }
};

export const LoginPage: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const navigate = useNavigate();
  const location = useLocation();
  const setAuth = useAuthStore((state) => state.setAuth);

  const fromLocation = (location.state as any)?.from?.pathname || '/dashboard';

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    const trimmedUsername = username.trim();
    if (!trimmedUsername) {
      setError('Vui lòng nhập mã số sinh viên, mã cán bộ hoặc email.');
      return;
    }
    if (!password) {
      setError('Vui lòng nhập mật khẩu truy cập.');
      return;
    }

    setLoading(true);

    try {
      const response = await loginApi({ username: trimmedUsername, password });

      if (response && response.success && response.data) {
        const loginData = response.data;
        // Save auth data to Zustand store and localStorage
        setAuth(loginData);

        // Check if mandatory first-time password change is required
        if (loginData.isPasswordChanged === false) {
          navigate('/change-password?required=true', { replace: true });
        } else {
          navigate(fromLocation, { replace: true });
        }
      } else {
        setError(response?.message || 'Đăng nhập không thành công');
      }
    } catch (err: any) {
      setError(getFriendlyErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="w-full max-w-5xl mx-auto my-auto p-3 sm:p-6 relative z-10">
      <div className="bg-white rounded-2xl shadow-2xl border border-slate-200/90 overflow-hidden grid grid-cols-1 lg:grid-cols-12 text-left">
        {/* Left Column (58%): Academic Branding & Intelligence Showcase (Stitch 41e9fae8d8d44fac8260cc17252be377) */}
        <div className="lg:col-span-7 bg-slate-900 p-6 sm:p-8 lg:p-10 text-white flex flex-col justify-between relative overflow-hidden">
          {/* Subtle Ambient Glows */}
          <div className="absolute -top-24 -left-24 w-80 h-80 rounded-full bg-primary-600/30 blur-3xl pointer-events-none" />
          <div className="absolute -bottom-24 -right-24 w-80 h-80 rounded-full bg-accent-500/25 blur-3xl pointer-events-none" />

          {/* Top Academic Badges */}
          <div className="relative z-10 space-y-6">
            <div className="flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary-500/15 border border-primary-500/30 text-primary-300 text-xs font-semibold">
                <School className="w-3.5 h-3.5" />
                Hạ tầng Giáo dục Số 4.0
              </span>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/15 border border-emerald-500/30 text-emerald-300 text-xs font-semibold">
                <ShieldCheck className="w-3.5 h-3.5" />
                Chuẩn VNU-HCM & ĐHQGHN
              </span>
            </div>

            <div className="space-y-2">
              <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-white leading-tight">
                Điểm danh thông minh, <br />
                <span className="text-primary-400">quản lý dễ dàng.</span>
              </h1>
              <p className="text-sm text-slate-300 leading-relaxed max-w-lg">
                Nền tảng vận hành dữ liệu chuyên cần và lịch trình học vụ thời gian thực cho giảng đường số với độ trễ dưới 0.3s.
              </p>
            </div>

            {/* AI Biometrics & Dynamic QR Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5 pt-2">
              {/* Card 1: AI FaceMatch */}
              <div className="p-4 rounded-xl bg-slate-800/80 border border-slate-700/80 backdrop-blur-sm space-y-2.5">
                <div className="flex items-center justify-between">
                  <span className="inline-flex items-center gap-1.5 text-xs font-bold text-primary-300 bg-primary-950/80 px-2 py-0.5 rounded border border-primary-800">
                    <ScanFace className="w-3.5 h-3.5 text-primary-400" />
                    AI FaceMatch
                  </span>
                  <span className="text-xs font-mono font-bold text-emerald-400">Độ chuẩn 99.8%</span>
                </div>
                <p className="text-xs text-slate-300 leading-snug">
                  Nhận diện đa khuôn mặt tức thì, đối soát sinh trắc học học phần với thuật toán Anti-spoofing tiên tiến.
                </p>
              </div>

              {/* Card 2: Dynamic QR Code */}
              <div className="p-4 rounded-xl bg-slate-800/80 border border-slate-700/80 backdrop-blur-sm space-y-2.5">
                <div className="flex items-center justify-between">
                  <span className="inline-flex items-center gap-1.5 text-xs font-bold text-accent-300 bg-accent-950/80 px-2 py-0.5 rounded border border-accent-800">
                    <QrCode className="w-3.5 h-3.5 text-accent-400" />
                    Dynamic QR
                  </span>
                  <span className="text-xs font-mono text-slate-300">Làm mới 5s</span>
                </div>
                <p className="text-xs text-slate-300 leading-snug">
                  Mã QR động xoay vòng kèm kiểm định Geofence Wi-Fi phòng học, ngăn chặn hoàn toàn gian lận điểm danh.
                </p>
              </div>
            </div>

            {/* Institutional Compliance & Roles */}
            <div className="p-3.5 rounded-xl bg-slate-800/60 border border-slate-700/60 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg bg-primary-700/30 border border-primary-500/40 flex items-center justify-center text-primary-400 shrink-0">
                  <ShieldCheck className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-xs font-bold text-white leading-tight">ISO/IEC 27001:2022</p>
                  <p className="text-[11px] text-slate-400 leading-tight">Mã hóa AES-256 dữ liệu sinh viên</p>
                </div>
              </div>

              <div className="flex items-center gap-1 text-[11px] font-semibold text-slate-300 bg-slate-900/80 px-2.5 py-1 rounded-lg border border-slate-800">
                <span className="text-primary-400">Sinh viên</span>
                <span>•</span>
                <span className="text-accent-400">Giảng viên</span>
                <span>•</span>
                <span className="text-slate-200">Quản trị</span>
              </div>
            </div>
          </div>

          {/* Left Footer */}
          <div className="relative z-10 pt-6 mt-6 border-t border-slate-800 flex items-center justify-between text-[11px] text-slate-400">
            <span>Trung tâm Khảo thí & Đảm bảo Chất lượng</span>
            <span className="font-mono font-medium">Phiên bản v4.2.8 Enterprise</span>
          </div>
        </div>

        {/* Right Column (42%): Login Form */}
        <div className="lg:col-span-5 p-6 sm:p-8 lg:p-10 bg-white flex flex-col justify-between">
          <div>
            {/* Header */}
            <div className="mb-6 space-y-1">
              <div className="inline-flex items-center justify-center w-11 h-11 rounded-xl bg-primary-50 text-primary-700 border border-primary-100 mb-3">
                <Lock className="w-5 h-5" />
              </div>
              <h2 className="text-xl sm:text-2xl font-bold tracking-tight text-slate-900">
                Đăng nhập hệ thống
              </h2>
              <p className="text-xs sm:text-sm text-slate-500 leading-relaxed">
                Sử dụng tài khoản VNU / UniCheck được cấp bởi Phòng Đào tạo & CTSV.
              </p>
            </div>

            {/* Error Alert */}
            {error && (
              <div
                role="alert"
                className="mb-5 p-3 rounded-xl bg-red-50 border border-red-200 text-red-700 text-xs flex items-start gap-2.5 animate-fadeIn"
              >
                <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
                <span className="leading-relaxed font-medium">{error}</span>
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleLogin} className="space-y-4" noValidate>
              {/* Username Input */}
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <label
                    htmlFor="login-username"
                    className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                  >
                    Mã số sinh viên / Email cán bộ
                  </label>
                  <span className="text-[11px] text-primary-700 font-semibold">Bắt buộc</span>
                </div>
                <div className="relative rounded-lg shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                    <User className="w-4 h-4" />
                  </div>
                  <input
                    id="login-username"
                    name="username"
                    type="text"
                    autoComplete="username"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    placeholder="Nhập MSSV, mã cán bộ hoặc email trường..."
                    required
                    disabled={loading}
                    className="w-full h-11 pl-9 pr-3.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 transition-all"
                  />
                </div>
              </div>

              {/* Password Input */}
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <label
                    htmlFor="login-password"
                    className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                  >
                    Mật khẩu truy cập
                  </label>
                  <span className="text-[11px] text-slate-400 font-medium">SSO Gateway</span>
                </div>
                <div className="relative rounded-lg shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                    <Lock className="w-4 h-4" />
                  </div>
                  <input
                    id="login-password"
                    name="password"
                    type={showPassword ? 'text' : 'password'}
                    autoComplete="current-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Nhập mật khẩu của bạn..."
                    required
                    disabled={loading}
                    className="w-full h-11 pl-9 pr-10 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    aria-label={showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600 transition"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Forgot Password Link */}
              <div className="flex items-center justify-end pt-1">
                <Link
                  to="/forgot-password"
                  className="text-xs font-semibold text-primary-700 hover:text-primary-800 transition hover:underline"
                >
                  Quên mật khẩu?
                </Link>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                id="btn-login-submit"
                disabled={loading}
                className="w-full h-11 px-4 rounded-lg bg-primary-700 hover:bg-primary-800 active:scale-[0.99] text-white font-semibold text-sm shadow-md shadow-primary-700/25 flex items-center justify-center gap-2 transition-all duration-150 disabled:opacity-50 disabled:cursor-not-allowed mt-2"
              >
                {loading ? (
                  <div className="flex items-center gap-2">
                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    <span>Đang xác thực...</span>
                  </div>
                ) : (
                  <>
                    <span>Đăng nhập hệ thống</span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>
            </form>
          </div>

          {/* Bottom Security Note */}
          <div className="mt-8 pt-4 border-t border-slate-100 space-y-2 text-center">
            <p className="text-xs text-slate-500">
              Cổng xác thực sinh viên, giảng viên và cán bộ quản trị học viện.
            </p>
            <div className="flex items-center justify-center gap-3 text-[11px] text-slate-400">
              <span className="flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                Mã hóa SSL 256-bit
              </span>
              <span>•</span>
              <span className="flex items-center gap-1">
                <Sparkles className="w-3.5 h-3.5 text-primary-600" />
                Phiên xác thực cô lập
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
