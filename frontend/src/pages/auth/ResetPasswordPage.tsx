import React, { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import {
  Lock,
  ArrowRight,
  ArrowLeft,
  KeyRound,
  ShieldCheck,
  AlertCircle,
  CheckCircle2,
  Eye,
  EyeOff,
  Check,
} from 'lucide-react';
import { resetPasswordApi } from '../../api/auth.api';

export const ResetPasswordPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const emailParam = searchParams.get('email') || '';
  const otpParam = searchParams.get('otp') || '';

  const [email, setEmail] = useState(emailParam);
  const [otp, setOtp] = useState(otpParam);
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const navigate = useNavigate();

  // Password rules validation
  const hasMinLength = newPassword.length >= 6;
  const hasUpperLower = /[A-Z]/.test(newPassword) && /[a-z]/.test(newPassword);
  const hasNumber = /[0-9]/.test(newPassword);
  const hasSpecial = /[^A-Za-z0-9]/.test(newPassword);
  const isMatch = newPassword.length > 0 && newPassword === confirmPassword;

  // Strength score: 0 to 4
  const strengthScore = [hasMinLength, hasUpperLower, hasNumber, hasSpecial].filter(Boolean).length;
  const strengthLabels = ['Chưa nhập', 'Yếu', 'Trung bình', 'Khá', 'Rất mạnh'];
  const strengthColors = ['bg-slate-200', 'bg-red-500', 'bg-amber-500', 'bg-blue-500', 'bg-emerald-500'];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    const cleanEmail = email.trim().toLowerCase();
    const cleanOtp = otp.trim();

    if (!cleanEmail) {
      setError('Vui lòng nhập địa chỉ email hợp lệ.');
      return;
    }
    if (!cleanOtp || cleanOtp.length < 6) {
      setError('Vui lòng nhập đầy đủ mã xác thực OTP 6 chữ số.');
      return;
    }
    if (newPassword.length < 6) {
      setError('Mật khẩu mới phải có tối thiểu 6 ký tự theo quy định của hệ thống.');
      return;
    }
    if (newPassword !== confirmPassword) {
      setError('Mật khẩu xác nhận không khớp với mật khẩu mới.');
      return;
    }

    setLoading(true);

    try {
      const response = await resetPasswordApi({
        email: cleanEmail,
        otp: cleanOtp,
        newPassword,
      });

      if (response && response.success) {
        setSuccess(true);
      } else {
        setError(response?.message || 'Đặt lại mật khẩu không thành công');
      }
    } catch (err: any) {
      const code = err?.response?.data?.errorCode || err?.errorCode;
      if (code === 'ERR_2008') {
        setError('Mã xác thực không chính xác hoặc đã hết hạn. Vui lòng quay lại lấy mã mới.');
      } else {
        setError(err?.message || 'Không thể đặt lại mật khẩu. Vui lòng kiểm tra lại thông tin.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="w-full max-w-5xl mx-auto my-auto p-3 sm:p-6 relative z-10">
      <div className="bg-white rounded-2xl shadow-2xl border border-slate-200/90 overflow-hidden grid grid-cols-1 lg:grid-cols-12 text-left">
        {/* Left Column (58%): Academic Guidance */}
        <div className="lg:col-span-7 bg-slate-900 p-6 sm:p-8 lg:p-10 text-white flex flex-col justify-between relative overflow-hidden">
          <div className="absolute -top-24 -left-24 w-80 h-80 rounded-full bg-primary-600/30 blur-3xl pointer-events-none" />
          <div className="absolute -bottom-24 -right-24 w-80 h-80 rounded-full bg-accent-500/25 blur-3xl pointer-events-none" />

          <div className="relative z-10 space-y-6">
            <div className="flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary-500/15 border border-primary-500/30 text-primary-300 text-xs font-semibold">
                <ShieldCheck className="w-3.5 h-3.5" />
                Tiêu chuẩn Mật khẩu Học viện
              </span>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/15 border border-emerald-500/30 text-emerald-300 text-xs font-semibold">
                Bảo vệ 2 Lớp
              </span>
            </div>

            <div className="space-y-2">
              <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-white leading-tight">
                Thiết lập mật khẩu mới, <br />
                <span className="text-primary-400">khởi động phiên làm việc.</span>
              </h1>
              <p className="text-sm text-slate-300 leading-relaxed max-w-lg">
                Để bảo vệ an toàn cho dữ liệu học vụ và quyền biểu quyết điểm danh, vui lòng đặt mật khẩu mạnh và không sử dụng lại các mật khẩu đã cũ.
              </p>
            </div>

            {/* Password Policy Guidelines */}
            <div className="p-4 rounded-xl bg-slate-800/80 border border-slate-700/80 space-y-3">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-300 flex items-center gap-2">
                <KeyRound className="w-4 h-4 text-primary-400" />
                Quy tắc an toàn mật khẩu
              </h4>
              <ul className="space-y-2 text-xs text-slate-300">
                <li className="flex items-center gap-2">
                  <div
                    className={`w-4 h-4 rounded-full flex items-center justify-center shrink-0 ${
                      hasMinLength ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-700 text-slate-500'
                    }`}
                  >
                    <Check className="w-2.5 h-2.5" />
                  </div>
                  <span>Tối thiểu 6 ký tự (khuyến nghị từ 8 - 32 ký tự)</span>
                </li>
                <li className="flex items-center gap-2">
                  <div
                    className={`w-4 h-4 rounded-full flex items-center justify-center shrink-0 ${
                      hasUpperLower ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-700 text-slate-500'
                    }`}
                  >
                    <Check className="w-2.5 h-2.5" />
                  </div>
                  <span>Kết hợp chữ viết HOA và chữ thường</span>
                </li>
                <li className="flex items-center gap-2">
                  <div
                    className={`w-4 h-4 rounded-full flex items-center justify-center shrink-0 ${
                      hasNumber ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-700 text-slate-500'
                    }`}
                  >
                    <Check className="w-2.5 h-2.5" />
                  </div>
                  <span>Tối thiểu 1 chữ số (0 - 9)</span>
                </li>
                <li className="flex items-center gap-2">
                  <div
                    className={`w-4 h-4 rounded-full flex items-center justify-center shrink-0 ${
                      hasSpecial ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-700 text-slate-500'
                    }`}
                  >
                    <Check className="w-2.5 h-2.5" />
                  </div>
                  <span>Ký tự đặc biệt như (!, @, #, $, %, ...)</span>
                </li>
              </ul>
            </div>
          </div>

          <div className="relative z-10 pt-6 mt-6 border-t border-slate-800 flex items-center justify-between text-[11px] text-slate-400">
            <span>Bảo mật theo tiêu chuẩn OWASP ASVS 4.0</span>
            <span className="font-mono">UniCheck v4.2.8</span>
          </div>
        </div>

        {/* Right Column (42%): Form */}
        <div className="lg:col-span-5 p-6 sm:p-8 lg:p-10 bg-white flex flex-col justify-between">
          <div>
            {/* Header */}
            <div className="mb-6 space-y-1">
              <div className="inline-flex items-center justify-center w-11 h-11 rounded-xl bg-primary-50 text-primary-700 border border-primary-100 mb-3">
                <KeyRound className="w-5 h-5" />
              </div>
              <h2 className="text-xl sm:text-2xl font-bold tracking-tight text-slate-900">
                Đặt lại mật khẩu mới
              </h2>
              <p className="text-xs sm:text-sm text-slate-500 leading-relaxed">
                Hoàn tất xác thực và lưu mật khẩu mới cho tài khoản của bạn.
              </p>
            </div>

            {/* Error Message */}
            {error && (
              <div
                role="alert"
                className="mb-4 p-3 rounded-xl bg-red-50 border border-red-200 text-red-700 text-xs flex items-start gap-2.5 animate-fadeIn"
              >
                <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
                <span className="leading-relaxed font-medium">{error}</span>
              </div>
            )}

            {!success ? (
              <form onSubmit={handleSubmit} className="space-y-4" noValidate>
                {/* Email (Readonly or Editable if missing) */}
                <div className="space-y-1">
                  <label
                    htmlFor="reset-email"
                    className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                  >
                    Email tài khoản
                  </label>
                  <input
                    id="reset-email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="student@unicheck.edu.vn"
                    required
                    disabled={loading || !!emailParam}
                    className="w-full h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 disabled:bg-slate-100 disabled:text-slate-600"
                  />
                </div>

                {/* OTP Code */}
                <div className="space-y-1">
                  <div className="flex items-center justify-between">
                    <label
                      htmlFor="reset-otp"
                      className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                    >
                      Mã xác thực OTP
                    </label>
                    <span className="text-[11px] text-primary-700 font-semibold">6 chữ số</span>
                  </div>
                  <input
                    id="reset-otp"
                    type="text"
                    inputMode="numeric"
                    maxLength={6}
                    value={otp}
                    onChange={(e) => setOtp(e.target.value.replace(/[^0-9]/g, ''))}
                    placeholder="Nhập 6 chữ số mã OTP..."
                    required
                    disabled={loading}
                    className="w-full h-10 px-3.5 font-mono tracking-widest text-base font-bold bg-slate-50 border border-slate-200 rounded-lg text-slate-900 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15"
                  />
                </div>

                {/* New Password */}
                <div className="space-y-1">
                  <label
                    htmlFor="reset-new-password"
                    className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                  >
                    Mật khẩu mới
                  </label>
                  <div className="relative rounded-lg shadow-sm">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                      <Lock className="w-4 h-4" />
                    </div>
                    <input
                      id="reset-new-password"
                      type={showNewPassword ? 'text' : 'password'}
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      placeholder="Tối thiểu 6 ký tự..."
                      required
                      disabled={loading}
                      className="w-full h-10 pl-9 pr-10 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 transition-all"
                    />
                    <button
                      type="button"
                      onClick={() => setShowNewPassword(!showNewPassword)}
                      aria-label={showNewPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'}
                      className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600 transition"
                    >
                      {showNewPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>

                  {/* Strength Meter */}
                  {newPassword && (
                    <div className="pt-1.5 space-y-1">
                      <div className="flex items-center justify-between text-[11px]">
                        <span className="text-slate-500">Độ mạnh mật khẩu:</span>
                        <span className="font-semibold text-slate-700">{strengthLabels[strengthScore]}</span>
                      </div>
                      <div className="grid grid-cols-4 gap-1.5 h-1.5">
                        {[1, 2, 3, 4].map((step) => (
                          <div
                            key={step}
                            className={`h-full rounded-full transition-all duration-300 ${
                              strengthScore >= step ? strengthColors[strengthScore] : 'bg-slate-200'
                            }`}
                          />
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                {/* Confirm Password */}
                <div className="space-y-1">
                  <label
                    htmlFor="reset-confirm-password"
                    className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                  >
                    Xác nhận mật khẩu mới
                  </label>
                  <div className="relative rounded-lg shadow-sm">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                      <Lock className="w-4 h-4" />
                    </div>
                    <input
                      id="reset-confirm-password"
                      type={showConfirmPassword ? 'text' : 'password'}
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="Nhập lại chính xác mật khẩu..."
                      required
                      disabled={loading}
                      className="w-full h-10 pl-9 pr-10 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 transition-all"
                    />
                    <button
                      type="button"
                      onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                      aria-label={showConfirmPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'}
                      className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600 transition"
                    >
                      {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                  {confirmPassword && !isMatch && (
                    <p className="text-[11px] text-red-600 font-medium">Mật khẩu xác nhận không khớp.</p>
                  )}
                </div>

                {/* Submit button */}
                <button
                  type="submit"
                  id="btn-reset-password-submit"
                  disabled={loading || !hasMinLength || !isMatch || otp.length < 6}
                  className="w-full h-11 px-4 rounded-lg bg-primary-700 hover:bg-primary-800 active:scale-[0.99] text-white font-semibold text-sm shadow-md shadow-primary-700/25 flex items-center justify-center gap-2 transition-all duration-150 disabled:opacity-50 disabled:cursor-not-allowed mt-2"
                >
                  {loading ? (
                    <div className="flex items-center gap-2">
                      <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      <span>Đang lưu mật khẩu mới...</span>
                    </div>
                  ) : (
                    <>
                      <span>Xác nhận & Hoàn tất</span>
                      <ArrowRight className="w-4 h-4" />
                    </>
                  )}
                </button>
              </form>
            ) : (
              /* Success card */
              <div className="space-y-4 animate-fadeIn">
                <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-900 space-y-2">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-lg bg-emerald-600 text-white flex items-center justify-center shrink-0">
                      <CheckCircle2 className="w-5 h-5" />
                    </div>
                    <div>
                      <h4 className="text-sm font-bold text-emerald-950">
                        Đặt lại mật khẩu thành công!
                      </h4>
                      <p className="text-xs text-emerald-800">
                        Mật khẩu tài khoản UniCheck của bạn đã được cập nhật thành công vào hệ thống.
                      </p>
                    </div>
                  </div>
                </div>

                <button
                  type="button"
                  id="btn-goto-login-success"
                  onClick={() => navigate('/login', { replace: true })}
                  className="w-full h-11 px-4 rounded-lg bg-primary-700 hover:bg-primary-800 active:scale-[0.99] text-white font-semibold text-sm shadow-md shadow-primary-700/25 flex items-center justify-center gap-2 transition-all duration-150"
                >
                  <span>Đăng nhập ngay với mật khẩu mới</span>
                  <ArrowRight className="w-4 h-4" />
                </button>
              </div>
            )}
          </div>

          {/* Navigation Links */}
          <div className="mt-8 pt-4 border-t border-slate-100 flex items-center justify-between text-xs">
            <Link
              to="/verify-otp"
              className="inline-flex items-center gap-1 font-semibold text-slate-500 hover:text-slate-800 transition"
            >
              <ArrowLeft className="w-3.5 h-3.5" />
              <span>Quay lại nhập OTP</span>
            </Link>
            <Link
              to="/login"
              className="font-semibold text-primary-700 hover:text-primary-800 transition hover:underline"
            >
              Về trang Đăng nhập
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ResetPasswordPage;
