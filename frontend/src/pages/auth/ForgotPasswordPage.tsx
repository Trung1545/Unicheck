import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  Mail,
  ArrowRight,
  ArrowLeft,
  KeyRound,
  ShieldCheck,
  AlertCircle,
  CheckCircle2,
  Inbox,
  HelpCircle,
} from 'lucide-react';
import { forgotPasswordApi } from '../../api/auth.api';

export const ForgotPasswordPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submittedEmail, setSubmittedEmail] = useState<string | null>(null);

  const navigate = useNavigate();

  const maskEmail = (str: string) => {
    const parts = str.split('@');
    if (parts.length !== 2) return str;
    const name = parts[0];
    const domain = parts[1];
    if (name.length <= 2) return `${name}***@${domain}`;
    return `${name[0]}****${name[name.length - 1]}@${domain}`;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    const trimmedEmail = email.trim().toLowerCase();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!trimmedEmail) {
      setError('Vui lòng nhập địa chỉ email đã đăng ký tại trường.');
      return;
    }
    if (!emailRegex.test(trimmedEmail)) {
      setError('Định dạng email không hợp lệ. Ví dụ: student@unicheck.edu.vn');
      return;
    }

    setLoading(true);

    try {
      const response = await forgotPasswordApi({ email: trimmedEmail });
      if (response && response.success) {
        setSubmittedEmail(trimmedEmail);
      } else {
        // Fallback message conforming to security principle
        setSubmittedEmail(trimmedEmail);
      }
    } catch (err: any) {
      // Backend contract specifies generic message even if user not found, but if network error
      const msg = err?.message || 'Có lỗi xảy ra khi gửi yêu cầu. Vui lòng thử lại sau.';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="w-full max-w-5xl mx-auto my-auto p-3 sm:p-6 relative z-10">
      <div className="bg-white rounded-2xl shadow-2xl border border-slate-200/90 overflow-hidden grid grid-cols-1 lg:grid-cols-12 text-left">
        {/* Left Column (58%): Security Guidance & Architecture Showcase */}
        <div className="lg:col-span-7 bg-slate-900 p-6 sm:p-8 lg:p-10 text-white flex flex-col justify-between relative overflow-hidden">
          <div className="absolute -top-24 -left-24 w-80 h-80 rounded-full bg-primary-600/30 blur-3xl pointer-events-none" />
          <div className="absolute -bottom-24 -right-24 w-80 h-80 rounded-full bg-accent-500/25 blur-3xl pointer-events-none" />

          <div className="relative z-10 space-y-6">
            <div className="flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary-500/15 border border-primary-500/30 text-primary-300 text-xs font-semibold">
                <ShieldCheck className="w-3.5 h-3.5" />
                Quy trình Khôi phục An toàn
              </span>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/15 border border-emerald-500/30 text-emerald-300 text-xs font-semibold">
                Mã xác thực OTP 6 số
              </span>
            </div>

            <div className="space-y-2">
              <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-white leading-tight">
                Khôi phục quyền truy cập, <br />
                <span className="text-primary-400">bảo vệ tài khoản học đường.</span>
              </h1>
              <p className="text-sm text-slate-300 leading-relaxed max-w-lg">
                Hệ thống xác thực an toàn đảm bảo thông tin cá nhân và dữ liệu điểm danh của bạn luôn được bảo mật.
              </p>
            </div>

            {/* Stepper info */}
            <div className="space-y-3 pt-2">
              <div className="flex items-start gap-3 p-3.5 rounded-xl bg-slate-800/70 border border-slate-700/70">
                <div className="w-7 h-7 rounded-lg bg-primary-600 text-white flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                  1
                </div>
                <div>
                  <h4 className="text-xs font-bold text-white">Xác nhận định danh email</h4>
                  <p className="text-[11px] text-slate-300">
                    Nhập địa chỉ email đã đăng ký trong hồ sơ tài khoản.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-3.5 rounded-xl bg-slate-800/70 border border-slate-700/70">
                <div className="w-7 h-7 rounded-lg bg-slate-700 text-slate-300 flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                  2
                </div>
                <div>
                  <h4 className="text-xs font-bold text-white">Nhận mã OTP bảo mật</h4>
                  <p className="text-[11px] text-slate-300">
                    Mã xác thực 6 chữ số có hiệu lực trong 10 phút được gửi bảo mật vào hòm thư.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-3.5 rounded-xl bg-slate-800/70 border border-slate-700/70">
                <div className="w-7 h-7 rounded-lg bg-slate-700 text-slate-300 flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                  3
                </div>
                <div>
                  <h4 className="text-xs font-bold text-white">Thiết lập mật khẩu mới</h4>
                  <p className="text-[11px] text-slate-300">
                    Nhập mật khẩu mới an toàn và hoàn tất khôi phục quyền truy cập.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div className="relative z-10 pt-6 mt-6 border-t border-slate-800 flex items-center justify-between text-[11px] text-slate-400">
            <span>Tổng đài Hỗ trợ Học vụ: 1900 6868</span>
            <span className="font-mono">UniCheck Identity Guard</span>
          </div>
        </div>

        {/* Right Column (42%): Action Form */}
        <div className="lg:col-span-5 p-6 sm:p-8 lg:p-10 bg-white flex flex-col justify-between">
          <div>
            {/* Header */}
            <div className="mb-6 space-y-1">
              <div className="inline-flex items-center justify-center w-11 h-11 rounded-xl bg-primary-50 text-primary-700 border border-primary-100 mb-3">
                <KeyRound className="w-5 h-5" />
              </div>
              <h2 className="text-xl sm:text-2xl font-bold tracking-tight text-slate-900">
                Quên mật khẩu?
              </h2>
              <p className="text-xs sm:text-sm text-slate-500 leading-relaxed">
                Nhập email tài khoản học đường của bạn để nhận mã xác thực đặt lại mật khẩu.
              </p>
            </div>

            {/* Error Message */}
            {error && (
              <div
                role="alert"
                className="mb-5 p-3 rounded-xl bg-red-50 border border-red-200 text-red-700 text-xs flex items-start gap-2.5 animate-fadeIn"
              >
                <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
                <span className="leading-relaxed font-medium">{error}</span>
              </div>
            )}

            {!submittedEmail ? (
              /* Request OTP Form */
              <form onSubmit={handleSubmit} className="space-y-4" noValidate>
                <div className="space-y-1.5">
                  <div className="flex items-center justify-between">
                    <label
                      htmlFor="forgot-email"
                      className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                    >
                      Địa chỉ Email trường học
                    </label>
                    <span className="text-[11px] text-primary-700 font-semibold">Bắt buộc</span>
                  </div>
                  <div className="relative rounded-lg shadow-sm">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                      <Mail className="w-4 h-4" />
                    </div>
                    <input
                      id="forgot-email"
                      name="email"
                      type="email"
                      autoComplete="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="student@unicheck.edu.vn"
                      required
                      disabled={loading}
                      className="w-full h-11 pl-9 pr-3.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 transition-all"
                    />
                  </div>
                  <p className="text-[11px] text-slate-500 flex items-center gap-1 pt-0.5">
                    <HelpCircle className="w-3 h-3 text-slate-400" />
                    Email đăng ký trong hồ sơ tài khoản người dùng.
                  </p>
                </div>

                <button
                  type="submit"
                  id="btn-forgot-submit"
                  disabled={loading}
                  className="w-full h-11 px-4 rounded-lg bg-primary-700 hover:bg-primary-800 active:scale-[0.99] text-white font-semibold text-sm shadow-md shadow-primary-700/25 flex items-center justify-center gap-2 transition-all duration-150 disabled:opacity-50 disabled:cursor-not-allowed mt-2"
                >
                  {loading ? (
                    <div className="flex items-center gap-2">
                      <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      <span>Đang gửi mã xác thực...</span>
                    </div>
                  ) : (
                    <>
                      <span>Gửi mã xác thực OTP</span>
                      <ArrowRight className="w-4 h-4" />
                    </>
                  )}
                </button>
              </form>
            ) : (
              /* Success Confirmation Card (Stitch bdeeb9ad8e6e48eb830753c46c0718eb) */
              <div className="space-y-4 animate-fadeIn">
                <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-900 space-y-2">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-lg bg-emerald-600 text-white flex items-center justify-center shrink-0">
                      <Inbox className="w-4 h-4" />
                    </div>
                    <div>
                      <h4 className="text-xs font-bold text-emerald-950 uppercase tracking-wide">
                        Đã phát lệnh xác thực
                      </h4>
                      <p className="text-xs font-mono font-semibold text-emerald-800">
                        {maskEmail(submittedEmail)}
                      </p>
                    </div>
                  </div>
                  <p className="text-xs text-emerald-800 leading-relaxed pt-1 border-t border-emerald-200/80">
                    Nếu email trùng khớp với hồ sơ lưu trữ tại trường, hệ thống đã gửi mã xác thực 6 chữ số. Vui lòng kiểm tra hộp thư đến hoặc thư rác (Spam).
                  </p>
                </div>

                <button
                  type="button"
                  id="btn-goto-verify-otp"
                  onClick={() => navigate(`/verify-otp?email=${encodeURIComponent(submittedEmail)}`)}
                  className="w-full h-11 px-4 rounded-lg bg-primary-700 hover:bg-primary-800 active:scale-[0.99] text-white font-semibold text-sm shadow-md shadow-primary-700/25 flex items-center justify-center gap-2 transition-all duration-150"
                >
                  <span>Tiếp tục nhập mã xác thực OTP</span>
                  <ArrowRight className="w-4 h-4" />
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setSubmittedEmail(null);
                    setEmail('');
                  }}
                  className="w-full text-center text-xs text-slate-500 hover:text-primary-700 transition hover:underline"
                >
                  Nhập địa chỉ email khác
                </button>
              </div>
            )}
          </div>

          {/* Back to Login Link */}
          <div className="mt-8 pt-4 border-t border-slate-100 text-center">
            <Link
              to="/login"
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-slate-600 hover:text-primary-700 transition"
            >
              <ArrowLeft className="w-3.5 h-3.5" />
              <span>Quay lại trang Đăng nhập</span>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ForgotPasswordPage;
