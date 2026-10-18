import React, { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  KeyRound,
  Lock,
  ShieldAlert,
  ShieldCheck,
  CheckCircle2,
  AlertCircle,
  Eye,
  EyeOff,
  ArrowRight,
  Check,
  Info,
} from 'lucide-react';
import { useAuthStore } from '../../store/auth-store';
import { changePasswordApi } from '../../api/auth.api';

export const ChangePasswordPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const isRequired = searchParams.get('required') === 'true';

  const user = useAuthStore((state) => state.user);
  const setUser = useAuthStore((state) => state.setUser);
  const navigate = useNavigate();

  const [oldPassword, setOldPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const [showOldPassword, setShowOldPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  // Password rules validation
  const hasMinLength = newPassword.length >= 6;
  const hasUpperLower = /[A-Z]/.test(newPassword) && /[a-z]/.test(newPassword);
  const hasNumber = /[0-9]/.test(newPassword);
  const hasSpecial = /[^A-Za-z0-9]/.test(newPassword);
  const isDifferentFromOld = oldPassword ? newPassword !== oldPassword : true;
  const isMatch = newPassword.length > 0 && newPassword === confirmPassword;

  // Strength score: 0 to 4
  const strengthScore = [hasMinLength, hasUpperLower, hasNumber, hasSpecial].filter(Boolean).length;
  const strengthLabels = ['Chưa nhập', 'Yếu', 'Trung bình', 'Khá', 'Rất mạnh'];
  const strengthColors = ['bg-slate-200', 'bg-red-500', 'bg-amber-500', 'bg-blue-500', 'bg-emerald-500'];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!oldPassword) {
      setError('Vui lòng nhập mật khẩu hiện tại.');
      return;
    }
    if (newPassword.length < 6) {
      setError('Mật khẩu mới phải có tối thiểu 6 ký tự.');
      return;
    }
    if (oldPassword === newPassword) {
      setError('Mật khẩu mới không được trùng với mật khẩu hiện tại.');
      return;
    }
    if (newPassword !== confirmPassword) {
      setError('Mật khẩu xác nhận không khớp với mật khẩu mới.');
      return;
    }

    setLoading(true);

    try {
      const response = await changePasswordApi({
        oldPassword,
        newPassword,
      });

      if (response && response.success) {
        setSuccess(true);
        // Update user state in auth store to mark password changed
        if (user) {
          setUser({
            ...user,
            isPasswordChanged: true,
          });
        }
      } else {
        setError(response?.message || 'Đổi mật khẩu không thành công');
      }
    } catch (err: any) {
      const code = err?.response?.data?.errorCode || err?.errorCode;
      if (code === 'ERR_2009') {
        setError('Mật khẩu hiện tại không chính xác. Vui lòng kiểm tra lại.');
      } else {
        setError(err?.message || 'Có lỗi xảy ra khi đổi mật khẩu.');
      }
    } finally {
      setLoading(false);
    }
  };

  const isMandatoryNotice = isRequired || user?.isPasswordChanged === false;

  return (
    <div className="w-full max-w-4xl mx-auto space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-200">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 flex items-center gap-2.5">
            <KeyRound className="w-6 h-6 text-primary-700" />
            <span>Đổi mật khẩu tài khoản</span>
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Quản trị mật khẩu xác thực và chính sách bảo mật cá nhân UniCheck.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs font-semibold text-slate-600 bg-white px-3 py-1.5 rounded-lg border border-slate-200 shadow-sm">
          <ShieldCheck className="w-4 h-4 text-emerald-600" />
          <span>Mã hóa BCrypt 12 Rounds</span>
        </div>
      </div>

      {/* Mandatory First-Login Notice Banner */}
      {isMandatoryNotice && !success && (
        <div
          role="alert"
          className="p-4 rounded-xl bg-amber-50 border border-amber-200 text-amber-900 flex items-start gap-3 shadow-sm animate-fadeIn"
        >
          <ShieldAlert className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div className="space-y-1 text-xs sm:text-sm">
            <h4 className="font-bold text-amber-950">Yêu cầu bảo mật bắt buộc: Đổi mật khẩu lần đầu</h4>
            <p className="text-amber-800 leading-relaxed">
              Tài khoản của bạn đang sử dụng mật khẩu mặc định do hệ thống cấp. Vui lòng thiết lập mật khẩu cá nhân mới để kích hoạt đầy đủ quyền truy cập các tính năng đào tạo và điểm danh.
            </p>
          </div>
        </div>
      )}

      {/* Main Card (Stitch a982502abde84a82927fbde7620c59c5) */}
      <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm p-6 sm:p-8 space-y-6">
        {/* Success Alert */}
        {success ? (
          <div className="space-y-6 text-center py-6 animate-fadeIn">
            <div className="w-16 h-16 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto shadow-sm">
              <CheckCircle2 className="w-8 h-8" />
            </div>

            <div className="space-y-2 max-w-md mx-auto">
              <h2 className="text-xl font-bold text-slate-900">Đổi mật khẩu thành công!</h2>
              <p className="text-xs sm:text-sm text-slate-600 leading-relaxed">
                Mật khẩu mới của bạn đã được cập nhật an toàn. Mọi phiên đăng nhập kế tiếp sẽ sử dụng mật khẩu mới này.
              </p>
            </div>

            <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3">
              <button
                type="button"
                id="btn-goto-dashboard-after-change"
                onClick={() => navigate('/dashboard')}
                className="w-full sm:w-auto h-11 px-6 rounded-lg bg-primary-700 hover:bg-primary-800 text-white font-semibold text-sm shadow-sm flex items-center justify-center gap-2 transition"
              >
                <span>Vào Bảng điều khiển (Dashboard)</span>
                <ArrowRight className="w-4 h-4" />
              </button>
              <button
                type="button"
                onClick={() => {
                  setSuccess(false);
                  setOldPassword('');
                  setNewPassword('');
                  setConfirmPassword('');
                }}
                className="w-full sm:w-auto h-11 px-5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-sm transition"
              >
                Tiếp tục ở lại trang này
              </button>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-5 text-left" noValidate>
            {/* Error Message */}
            {error && (
              <div
                role="alert"
                className="p-3.5 rounded-xl bg-red-50 border border-red-200 text-red-700 text-xs flex items-start gap-2.5 animate-fadeIn"
              >
                <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
                <span className="leading-relaxed font-medium">{error}</span>
              </div>
            )}

            {/* Field 1: Current Password */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label
                  htmlFor="change-old-password"
                  className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                >
                  Mật khẩu hiện tại
                </label>
                <span className="text-[11px] text-red-500 font-semibold">* Bắt buộc</span>
              </div>
              <div className="relative rounded-lg shadow-sm">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                  <Lock className="w-4 h-4" />
                </div>
                <input
                  id="change-old-password"
                  type={showOldPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  value={oldPassword}
                  onChange={(e) => setOldPassword(e.target.value)}
                  placeholder="Nhập mật khẩu đang sử dụng..."
                  required
                  disabled={loading}
                  className="w-full h-11 pl-9 pr-10 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowOldPassword(!showOldPassword)}
                  aria-label={showOldPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600 transition"
                >
                  {showOldPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Field 2: New Password */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label
                  htmlFor="change-new-password"
                  className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                >
                  Mật khẩu mới
                </label>
                <span className="text-[11px] text-red-500 font-semibold">* Bắt buộc</span>
              </div>
              <div className="relative rounded-lg shadow-sm">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                  <KeyRound className="w-4 h-4" />
                </div>
                <input
                  id="change-new-password"
                  type={showNewPassword ? 'text' : 'password'}
                  autoComplete="new-password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="Nhập mật khẩu mới an toàn..."
                  required
                  disabled={loading}
                  className="w-full h-11 pl-9 pr-10 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 transition-all"
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

              {/* Password Strength Meter & Hints */}
              <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/80 space-y-3">
                <div className="flex items-center justify-between text-xs">
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

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-[11px] pt-1">
                  <div className={`flex items-center gap-1.5 ${hasMinLength ? 'text-emerald-700 font-semibold' : 'text-slate-500'}`}>
                    <Check className={`w-3.5 h-3.5 ${hasMinLength ? 'text-emerald-600' : 'text-slate-400'}`} />
                    <span>Tối thiểu 6 ký tự</span>
                  </div>
                  <div className={`flex items-center gap-1.5 ${hasUpperLower ? 'text-emerald-700 font-semibold' : 'text-slate-500'}`}>
                    <Check className={`w-3.5 h-3.5 ${hasUpperLower ? 'text-emerald-600' : 'text-slate-400'}`} />
                    <span>Chữ viết HOA và chữ thường</span>
                  </div>
                  <div className={`flex items-center gap-1.5 ${hasNumber ? 'text-emerald-700 font-semibold' : 'text-slate-500'}`}>
                    <Check className={`w-3.5 h-3.5 ${hasNumber ? 'text-emerald-600' : 'text-slate-400'}`} />
                    <span>Có ít nhất 1 chữ số</span>
                  </div>
                  <div className={`flex items-center gap-1.5 ${hasSpecial ? 'text-emerald-700 font-semibold' : 'text-slate-500'}`}>
                    <Check className={`w-3.5 h-3.5 ${hasSpecial ? 'text-emerald-600' : 'text-slate-400'}`} />
                    <span>Ký tự đặc biệt (!@#$...)</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Field 3: Confirm New Password */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label
                  htmlFor="change-confirm-password"
                  className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                >
                  Xác nhận mật khẩu mới
                </label>
                <span className="text-[11px] text-red-500 font-semibold">* Bắt buộc</span>
              </div>
              <div className="relative rounded-lg shadow-sm">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                  <KeyRound className="w-4 h-4" />
                </div>
                <input
                  id="change-confirm-password"
                  type={showConfirmPassword ? 'text' : 'password'}
                  autoComplete="new-password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Nhập lại chính xác mật khẩu mới..."
                  required
                  disabled={loading}
                  className="w-full h-11 pl-9 pr-10 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 transition-all"
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
                <p className="text-xs text-red-600 font-medium">Mật khẩu xác nhận không khớp.</p>
              )}
            </div>

            {/* Security Disclaimer */}
            <div className="p-3 rounded-xl bg-blue-50/60 border border-blue-200/60 flex items-start gap-2.5 text-xs text-blue-900">
              <Info className="w-4 h-4 text-primary-700 shrink-0 mt-0.5" />
              <span>
                Sau khi đổi mật khẩu, hệ thống sẽ tự động cập nhật token và ghi nhận nhật ký kiểm toán (Audit Access Log) bảo vệ tài khoản của bạn.
              </span>
            </div>

            {/* Submit Action */}
            <div className="pt-2 flex items-center justify-end gap-3">
              {!isMandatoryNotice && (
                <button
                  type="button"
                  onClick={() => navigate(-1)}
                  disabled={loading}
                  className="h-11 px-5 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-700 font-semibold text-sm transition"
                >
                  Hủy bỏ
                </button>
              )}
              <button
                type="submit"
                id="btn-change-password-submit"
                disabled={loading || !hasMinLength || !isMatch || !oldPassword || !isDifferentFromOld}
                className="h-11 px-6 rounded-lg bg-primary-700 hover:bg-primary-800 active:scale-[0.99] text-white font-semibold text-sm shadow-md shadow-primary-700/25 flex items-center justify-center gap-2 transition-all duration-150 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? (
                  <div className="flex items-center gap-2">
                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    <span>Đang cập nhật...</span>
                  </div>
                ) : (
                  <>
                    <span>Cập nhật mật khẩu</span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};

export default ChangePasswordPage;
