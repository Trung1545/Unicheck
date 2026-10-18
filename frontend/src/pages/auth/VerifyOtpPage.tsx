import React, { useState, useEffect, useRef } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import {
  ShieldCheck,
  RotateCcw,
  Clock,
  ArrowLeft,
  ArrowRight,
  AlertCircle,
  CheckCircle2,
  Lock,
} from 'lucide-react';
import { forgotPasswordApi } from '../../api/auth.api';

export const VerifyOtpPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const emailParam = searchParams.get('email') || '';

  const [email, setEmail] = useState(emailParam);
  const [otpDigits, setOtpDigits] = useState<string[]>(['', '', '', '', '', '']);
  const [timerSeconds, setTimerSeconds] = useState(600); // 10 minutes Redis TTL
  const [resendCooldown, setResendCooldown] = useState(60); // 60s cooldown
  const [resending, setResending] = useState(false);
  const [resendMessage, setResendMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);
  const navigate = useNavigate();

  // Focus first input on mount
  useEffect(() => {
    if (inputRefs.current[0]) {
      inputRefs.current[0]?.focus();
    }
  }, []);

  // 10 minutes expiration countdown timer
  useEffect(() => {
    if (timerSeconds <= 0) return;
    const interval = setInterval(() => {
      setTimerSeconds((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(interval);
  }, [timerSeconds]);

  // Resend cooldown timer
  useEffect(() => {
    if (resendCooldown <= 0) return;
    const interval = setInterval(() => {
      setResendCooldown((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(interval);
  }, [resendCooldown]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const maskEmail = (str: string) => {
    const parts = str.split('@');
    if (parts.length !== 2) return str;
    const name = parts[0];
    const domain = parts[1];
    if (name.length <= 2) return `${name}***@${domain}`;
    return `${name[0]}****${name[name.length - 1]}@${domain}`;
  };

  const handleDigitChange = (index: number, value: string) => {
    setError(null);
    setResendMessage(null);

    // Filter only numeric characters
    const cleanVal = value.replace(/[^0-9]/g, '');

    if (!cleanVal) {
      const nextDigits = [...otpDigits];
      nextDigits[index] = '';
      setOtpDigits(nextDigits);
      return;
    }

    // Take the last character
    const char = cleanVal[cleanVal.length - 1];
    const nextDigits = [...otpDigits];
    nextDigits[index] = char;
    setOtpDigits(nextDigits);

    // Jump to next input if available
    if (index < 5 && inputRefs.current[index + 1]) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace') {
      if (!otpDigits[index] && index > 0) {
        const nextDigits = [...otpDigits];
        nextDigits[index - 1] = '';
        setOtpDigits(nextDigits);
        inputRefs.current[index - 1]?.focus();
      }
    } else if (e.key === 'ArrowLeft' && index > 0) {
      inputRefs.current[index - 1]?.focus();
    } else if (e.key === 'ArrowRight' && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handlePaste = (e: React.ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData('text/plain').trim();
    const cleanNumbers = pastedData.replace(/[^0-9]/g, '');

    if (cleanNumbers.length > 0) {
      const nextDigits = [...otpDigits];
      for (let i = 0; i < 6; i++) {
        if (i < cleanNumbers.length) {
          nextDigits[i] = cleanNumbers[i];
        }
      }
      setOtpDigits(nextDigits);

      // Focus last filled or 6th input
      const targetIndex = Math.min(cleanNumbers.length, 5);
      inputRefs.current[targetIndex]?.focus();
    }
  };

  const handleResendOtp = async () => {
    if (resendCooldown > 0 || resending) return;
    if (!email) {
      setError('Vui lòng cung cấp địa chỉ email để gửi lại mã.');
      return;
    }

    setResending(true);
    setError(null);
    setResendMessage(null);

    try {
      await forgotPasswordApi({ email: email.trim().toLowerCase() });
      setResendCooldown(60);
      setTimerSeconds(600); // Reset 10 minutes expiration
      setResendMessage('Mã xác thực mới đã được phát hành và gửi tới email của bạn.');
    } catch (err: any) {
      setError(err?.message || 'Không thể gửi lại mã OTP. Vui lòng thử lại.');
    } finally {
      setResending(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (timerSeconds <= 0) {
      setError('Mã xác thực đã hết hạn. Vui lòng bấm gửi lại mã mới.');
      return;
    }

    const fullOtp = otpDigits.join('');
    if (fullOtp.length < 6) {
      setError('Vui lòng nhập đầy đủ 6 chữ số của mã xác thực.');
      return;
    }

    if (!email) {
      setError('Vui lòng nhập địa chỉ email hợp lệ.');
      return;
    }

    // Proceed to Reset Password screen carrying email and OTP
    navigate(`/reset-password?email=${encodeURIComponent(email)}&otp=${encodeURIComponent(fullOtp)}`);
  };

  const isComplete = otpDigits.every((d) => d !== '');
  const percentRemaining = Math.max(0, Math.min(100, (timerSeconds / 600) * 100));

  return (
    <div className="w-full max-w-5xl mx-auto my-auto p-3 sm:p-6 relative z-10">
      <div className="bg-white rounded-2xl shadow-2xl border border-slate-200/90 overflow-hidden grid grid-cols-1 lg:grid-cols-12 text-left">
        {/* Left Column (58%): Institutional Security Context (Stitch a82fccdfa56d4efa8dec59a3a636a0ff) */}
        <div className="lg:col-span-7 bg-slate-900 p-6 sm:p-8 lg:p-10 text-white flex flex-col justify-between relative overflow-hidden">
          <div className="absolute -top-24 -left-24 w-80 h-80 rounded-full bg-primary-600/30 blur-3xl pointer-events-none" />
          <div className="absolute -bottom-24 -right-24 w-80 h-80 rounded-full bg-accent-500/25 blur-3xl pointer-events-none" />

          <div className="relative z-10 space-y-6">
            <div className="flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary-500/15 border border-primary-500/30 text-primary-300 text-xs font-semibold">
                <ShieldCheck className="w-3.5 h-3.5" />
                Kiểm định Xác thực Hai lớp (2FA)
              </span>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/15 border border-emerald-500/30 text-emerald-300 text-xs font-semibold">
                Hiệu lực 10 Phút
              </span>
            </div>

            <div className="space-y-2">
              <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-white leading-tight">
                Xác thực mã an toàn, <br />
                <span className="text-primary-400">hoàn tất nhận diện.</span>
              </h1>
              <p className="text-sm text-slate-300 leading-relaxed max-w-lg">
                Mã OTP 6 chữ số được gửi tới hòm thư cá nhân nhằm xác nhận chủ sở hữu hợp pháp của tài khoản đào tạo tại trường.
              </p>
            </div>

            {/* Target Account Display */}
            <div className="p-4 rounded-xl bg-slate-800/80 border border-slate-700/80 space-y-2">
              <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">
                Tài khoản nhận mã xác thực
              </span>
              <p className="text-sm font-mono font-bold text-primary-300">
                {email ? maskEmail(email) : 'Chưa xác định email'}
              </p>
              <p className="text-[11px] text-slate-400">
                Nếu không thấy trong Hộp thư đến (Inbox), hãy kiểm tra thư mục Spam hoặc Quảng cáo.
              </p>
            </div>

            {/* Security checklist */}
            <div className="space-y-2.5 text-xs text-slate-300">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                <span>Không chia sẻ mã OTP với bất kỳ ai, kể cả quản trị viên hệ thống.</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                <span>Mã sẽ tự động vô hiệu hóa sau 10 phút hoặc sau khi được dùng thành công.</span>
              </div>
            </div>
          </div>

          <div className="relative z-10 pt-6 mt-6 border-t border-slate-800 flex items-center justify-between text-[11px] text-slate-400">
            <span>UniCheck Two-Factor Guard</span>
            <span className="font-mono">Chuẩn ISO 27001</span>
          </div>
        </div>

        {/* Right Column (42%): OTP Input Form */}
        <div className="lg:col-span-5 p-6 sm:p-8 lg:p-10 bg-white flex flex-col justify-between">
          <div>
            {/* Header */}
            <div className="mb-6 space-y-1">
              <div className="inline-flex items-center justify-center w-11 h-11 rounded-xl bg-primary-50 text-primary-700 border border-primary-100 mb-3">
                <Lock className="w-5 h-5" />
              </div>
              <h2 className="text-xl sm:text-2xl font-bold tracking-tight text-slate-900">
                Xác thực mã OTP
              </h2>
              <p className="text-xs sm:text-sm text-slate-500 leading-relaxed">
                Nhập mã 6 chữ số đã được gửi qua email của bạn để tiếp tục.
              </p>
            </div>

            {/* Email field if not provided in search params */}
            {!emailParam && (
              <div className="mb-4 space-y-1.5">
                <label
                  htmlFor="verify-email"
                  className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                >
                  Email nhận mã
                </label>
                <input
                  id="verify-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="student@unicheck.edu.vn"
                  required
                  className="w-full h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 transition-all"
                />
              </div>
            )}

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

            {/* Resend Success Notification */}
            {resendMessage && (
              <div
                role="status"
                className="mb-4 p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs flex items-start gap-2.5 animate-fadeIn"
              >
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span className="leading-relaxed font-medium">{resendMessage}</span>
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-5" noValidate>
              {/* 6 Digit OTP Input Boxes */}
              <div className="space-y-2">
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-700">
                  Mã xác thực (6 chữ số)
                </label>
                <div className="grid grid-cols-6 gap-2 sm:gap-2.5" onPaste={handlePaste}>
                  {otpDigits.map((digit, idx) => (
                    <input
                      key={idx}
                      ref={(el) => { inputRefs.current[idx] = el; }}
                      type="text"
                      inputMode="numeric"
                      pattern="[0-9]*"
                      maxLength={1}
                      value={digit}
                      onChange={(e) => handleDigitChange(idx, e.target.value)}
                      onKeyDown={(e) => handleKeyDown(idx, e)}
                      id={`otp-digit-${idx}`}
                      aria-label={`Chữ số thứ ${idx + 1}`}
                      className="w-full h-12 text-center text-lg font-bold font-mono rounded-lg bg-slate-50 border border-slate-200 text-slate-900 focus:bg-white focus:border-primary-600 focus:ring-2 focus:ring-primary-500/20 outline-none transition-all"
                    />
                  ))}
                </div>
              </div>

              {/* Countdown Bar & Timer */}
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/80 space-y-2">
                <div className="flex items-center justify-between text-xs font-medium">
                  <span className="flex items-center gap-1.5 text-slate-500">
                    <Clock className="w-3.5 h-3.5 text-primary-700" />
                    Thời gian hiệu lực mã:
                  </span>
                  <span
                    className={`font-mono font-bold ${
                      timerSeconds < 60 ? 'text-red-600 animate-pulse' : 'text-primary-700'
                    }`}
                  >
                    {formatTime(timerSeconds)}
                  </span>
                </div>
                <div className="w-full h-1.5 bg-slate-200 rounded-full overflow-hidden">
                  <div
                    className={`h-full transition-all duration-1000 ${
                      timerSeconds < 60 ? 'bg-red-500' : 'bg-primary-600'
                    }`}
                    style={{ width: `${percentRemaining}%` }}
                  />
                </div>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                id="btn-verify-otp-submit"
                disabled={!isComplete || timerSeconds <= 0}
                className="w-full h-11 px-4 rounded-lg bg-primary-700 hover:bg-primary-800 active:scale-[0.99] text-white font-semibold text-sm shadow-md shadow-primary-700/25 flex items-center justify-center gap-2 transition-all duration-150 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <span>Xác nhận & Đặt mật khẩu</span>
                <ArrowRight className="w-4 h-4" />
              </button>

              {/* Resend OTP Control */}
              <div className="flex flex-col sm:flex-row items-center justify-between gap-2 pt-1 text-xs">
                <span className="text-slate-500">
                  {resendCooldown > 0 ? (
                    <>
                      Gửi lại mã sau: <strong className="font-mono text-slate-800">{resendCooldown}s</strong>
                    </>
                  ) : (
                    'Chưa nhận được mã?'
                  )}
                </span>
                <button
                  type="button"
                  id="btn-resend-otp"
                  onClick={handleResendOtp}
                  disabled={resendCooldown > 0 || resending}
                  className="font-semibold text-primary-700 hover:text-primary-800 disabled:text-slate-400 disabled:cursor-not-allowed transition flex items-center gap-1"
                >
                  <RotateCcw className={`w-3.5 h-3.5 ${resending ? 'animate-spin' : ''}`} />
                  <span>{resending ? 'Đang gửi lại...' : 'Gửi lại mã OTP'}</span>
                </button>
              </div>
            </form>
          </div>

          {/* Navigation Links */}
          <div className="mt-8 pt-4 border-t border-slate-100 flex items-center justify-between text-xs">
            <Link
              to="/forgot-password"
              className="inline-flex items-center gap-1 font-semibold text-slate-500 hover:text-slate-800 transition"
            >
              <ArrowLeft className="w-3.5 h-3.5" />
              <span>Đổi email</span>
            </Link>
            <Link
              to="/login"
              className="font-semibold text-primary-700 hover:text-primary-800 transition hover:underline"
            >
              Quay lại Đăng nhập
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VerifyOtpPage;
