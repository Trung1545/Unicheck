import React, { useEffect, useState } from 'react';
import {
  User as UserIcon,
  Mail,
  Phone,
  Calendar,
  Shield,
  CreditCard,
  ScanFace,
  CheckCircle2,
  AlertCircle,
  Building2,
  GraduationCap,
  Save,
  RotateCcw,
  Sparkles,
  Lock,
  BadgeCheck,
} from 'lucide-react';
import { getProfileApi, updateProfileApi } from '../../api/auth.api';
import { useAuthStore } from '../../store/auth-store';
import { UserProfileResponse } from '../../types/api';
import { Skeleton } from '../../common-ui/Skeleton';
import { ErrorState } from '../../common-ui/ErrorState';

export const ProfilePage: React.FC = () => {
  const [profile, setProfile] = useState<UserProfileResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saveSuccess, setSaveSuccess] = useState(false);

  // Editable Form fields
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [dob, setDob] = useState('');
  const [sex, setSex] = useState('NAM');
  const [avatar, setAvatar] = useState('');

  const setUser = useAuthStore((state) => state.setUser);

  const fetchProfile = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await getProfileApi();
      if (response && response.success && response.data) {
        const data = response.data;
        setProfile(data);
        setFullName(data.fullName || '');
        setPhone(data.phone || '');
        setDob(data.dob || '');
        setSex(data.sex || 'NAM');
        setAvatar(data.avatar || '');
        setUser(data);
      } else {
        setError(response?.message || 'Không thể tải thông tin hồ sơ.');
      }
    } catch (err: any) {
      setError(err?.message || 'Không thể kết nối đến máy chủ lấy thông tin hồ sơ.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfile();
  }, []);

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    setSaveSuccess(false);

    try {
      const response = await updateProfileApi({
        fullName: fullName.trim() || undefined,
        phone: phone.trim() || undefined,
        dob: dob || undefined,
        sex: sex || undefined,
        avatar: avatar.trim() || undefined,
      });

      if (response && response.success && response.data) {
        setProfile(response.data);
        setUser(response.data);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 5000);
      } else {
        setError(response?.message || 'Cập nhật hồ sơ không thành công.');
      }
    } catch (err: any) {
      setError(err?.message || 'Có lỗi xảy ra khi lưu thay đổi.');
    } finally {
      setSaving(false);
    }
  };

  const getInitials = (name?: string) => {
    if (!name) return 'UC';
    const parts = name.trim().split(/\s+/);
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  };

  const roleLabelMap: Record<string, string> = {
    ADMIN: 'Quản trị viên',
    LECTURER: 'Giảng viên',
    STUDENT: 'Sinh viên',
  };

  if (loading) {
    return (
      <div className="w-full max-w-6xl mx-auto space-y-6 animate-pulse">
        <div className="h-20 bg-slate-200/80 rounded-2xl" />
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <div className="lg:col-span-4 h-96 bg-slate-200/80 rounded-2xl" />
          <div className="lg:col-span-8 space-y-6">
            <div className="h-64 bg-slate-200/80 rounded-2xl" />
            <div className="h-64 bg-slate-200/80 rounded-2xl" />
          </div>
        </div>
      </div>
    );
  }

  if (error && !profile) {
    return (
      <div className="w-full max-w-2xl mx-auto py-12">
        <ErrorState
          title="Không thể tải hồ sơ người dùng"
          message={error}
          onRetry={fetchProfile}
        />
      </div>
    );
  }

  return (
    <div className="w-full max-w-6xl mx-auto space-y-6 text-left">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-200">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 flex items-center gap-2.5">
            <UserIcon className="w-6 h-6 text-primary-700" />
            <span>Hồ sơ cá nhân & Định danh học vụ</span>
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Quản trị dữ liệu hồ sơ cá nhân và quyền hạn truy cập trong hệ sinh thái UniCheck.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={fetchProfile}
            className="h-9 px-3 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600 text-xs font-semibold flex items-center gap-1.5 transition"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span>Làm mới dữ liệu</span>
          </button>
        </div>
      </div>

      {/* Save Success Alert */}
      {saveSuccess && (
        <div
          role="status"
          className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-900 flex items-center justify-between gap-3 shadow-sm animate-fadeIn"
        >
          <div className="flex items-center gap-2.5 text-xs sm:text-sm">
            <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
            <span className="font-semibold">Cập nhật thông tin hồ sơ thành công! Dữ liệu đã được lưu trữ an toàn.</span>
          </div>
        </div>
      )}

      {/* Main Grid: Left Column (4 cols) & Right Column (8 cols) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* LEFT COLUMN: Identity & SmartPass Card Mockup (Stitch 1c85a287b68c437e8e7fe5f9f829bc16) */}
        <div className="lg:col-span-4 space-y-6">
          {/* User Overview Card */}
          <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm p-6 text-center space-y-4">
            <div className="relative inline-block mx-auto">
              {profile?.avatar ? (
                <img
                  src={profile.avatar}
                  alt={profile.fullName}
                  className="w-24 h-24 rounded-full object-cover border-4 border-white shadow-md mx-auto"
                />
              ) : (
                <div className="w-24 h-24 rounded-full bg-primary-700 text-white text-2xl font-bold flex items-center justify-center border-4 border-white shadow-md mx-auto">
                  {getInitials(profile?.fullName)}
                </div>
              )}
              <span className="absolute bottom-1 right-1 w-4 h-4 rounded-full bg-emerald-500 border-2 border-white" />
            </div>

            <div className="space-y-1">
              <h2 className="text-lg font-bold text-slate-900 flex items-center justify-center gap-1.5">
                <span>{profile?.fullName || 'Người dùng'}</span>
                <BadgeCheck className="w-4 h-4 text-primary-700" />
              </h2>
              <p className="text-xs font-mono font-bold text-primary-700">
                MSSV / ID: {profile?.code}
              </p>
              <div className="pt-1">
                <span className="inline-block px-3 py-1 rounded-full bg-primary-50 text-primary-800 text-xs font-bold border border-primary-200/60">
                  {roleLabelMap[profile?.role || ''] || profile?.role}
                </span>
              </div>
            </div>

            {/* Face-ID Biometric Status Badge */}
            <div className="pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
              <span className="text-slate-500 flex items-center gap-1">
                <ScanFace className="w-4 h-4 text-slate-400" />
                Dữ liệu Face-ID:
              </span>
              <a
                href="/student/face-enrollment"
                className={`px-2.5 py-0.5 rounded-full font-bold text-[11px] transition hover:opacity-80 flex items-center gap-1 ${
                  profile?.faceDataStatus === 'REGISTERED' || profile?.faceDataStatus === 'ACTIVE'
                    ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                    : 'bg-blue-50 text-blue-700 border border-blue-200 hover:bg-blue-100'
                }`}
              >
                <span>
                  {profile?.faceDataStatus === 'REGISTERED' || profile?.faceDataStatus === 'ACTIVE'
                    ? 'Đã đăng ký (v4.2)'
                    : 'Quét Face-ID ngay →'}
                </span>
              </a>
            </div>

            {/* Account Status Badge */}
            <div className="flex items-center justify-between text-xs">
              <span className="text-slate-500 flex items-center gap-1">
                <Shield className="w-4 h-4 text-slate-400" />
                Trạng thái tài khoản:
              </span>
              <span className="px-2 py-0.5 rounded-full font-bold text-[11px] bg-slate-100 text-slate-700 border border-slate-200">
                {profile?.status || 'ACTIVE'}
              </span>
            </div>
          </div>

          {/* e-SmartPass Digital ID Card (Stitch 1c85a287b68c437e8e7fe5f9f829bc16) */}
          <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm p-6 space-y-3">
            <div className="flex items-center justify-between text-xs font-semibold text-slate-700">
              <span className="flex items-center gap-1.5">
                <CreditCard className="w-4 h-4 text-primary-700" />
                Thẻ định danh số (SmartPass)
              </span>
              <span className="text-[11px] text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded font-bold">
                NFC Active
              </span>
            </div>

            <div className="w-full bg-gradient-to-tr from-primary-800 via-primary-700 to-accent-600 text-white rounded-xl p-5 flex flex-col justify-between h-48 shadow-lg relative overflow-hidden select-none">
              <div className="flex items-center justify-between relative z-10">
                <div className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-lg bg-white/20 backdrop-blur-sm flex items-center justify-center font-bold text-xs">
                    UC
                  </div>
                  <span className="font-bold text-xs tracking-wider">UNICHECK SMARTPASS</span>
                </div>
                <div className="w-7 h-5 rounded border border-white/50 flex items-center justify-center text-[10px] font-mono opacity-80">
                  NFC
                </div>
              </div>

              <div className="relative z-10 flex items-end justify-between">
                <div className="space-y-0.5">
                  <p className="text-[10px] text-white/75 uppercase tracking-wider">Chủ sở hữu thẻ</p>
                  <p className="font-bold text-sm tracking-wide uppercase">{profile?.fullName}</p>
                  <p className="font-mono text-xs opacity-90">{profile?.code}</p>
                </div>

                {/* Micro QR Placeholder */}
                <div className="w-12 h-12 bg-white rounded p-1 shadow-sm shrink-0 flex items-center justify-center">
                  <div className="w-full h-full border-2 border-slate-900 border-dashed rounded flex items-center justify-center text-[8px] font-bold text-slate-900">
                    QR
                  </div>
                </div>
              </div>
            </div>

            <p className="text-[11px] text-slate-400 text-center">
              Dùng để chạm NFC tại phòng thi và quét mã khi điểm danh khẩn cấp.
            </p>
          </div>
        </div>

        {/* RIGHT COLUMN: Institutional Info (Read-Only) + Editable Form */}
        <div className="lg:col-span-8 space-y-6">
          {/* Section 1: Read-Only Academic & Institutional Identifiers */}
          <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm p-6 sm:p-7 space-y-5">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3 border-b border-slate-100 gap-2">
              <div className="flex items-center gap-2">
                <Building2 className="w-5 h-5 text-primary-700" />
                <h3 className="font-bold text-base text-slate-900">
                  Định danh học vụ & Đào tạo
                </h3>
              </div>
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 text-slate-600 text-xs font-semibold">
                <Lock className="w-3.5 h-3.5 text-slate-400" />
                <span>Chỉ do Quản trị viên quản lý</span>
              </div>
            </div>

            <p className="text-xs text-slate-500 -mt-2">
              Các thông tin định danh gốc thuộc hồ sơ trúng tuyển và tuyển sinh. Người dùng không thể tự ý sửa đổi.
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              {/* MSSV / Code */}
              <div className="space-y-1">
                <span className="font-semibold text-slate-500 uppercase tracking-wider text-[11px]">
                  Mã số định danh (MSSV / MSG)
                </span>
                <div className="h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg flex items-center justify-between text-slate-900 font-mono font-bold">
                  <span>{profile?.code || 'Chưa cập nhật'}</span>
                  <Lock className="w-3.5 h-3.5 text-slate-400" />
                </div>
              </div>

              {/* Username */}
              <div className="space-y-1">
                <span className="font-semibold text-slate-500 uppercase tracking-wider text-[11px]">
                  Tên đăng nhập hệ thống
                </span>
                <div className="h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg flex items-center justify-between text-slate-900 font-mono">
                  <span>{profile?.username || 'Chưa cập nhật'}</span>
                  <Lock className="w-3.5 h-3.5 text-slate-400" />
                </div>
              </div>

              {/* Academic Email */}
              <div className="sm:col-span-2 space-y-1">
                <span className="font-semibold text-slate-500 uppercase tracking-wider text-[11px]">
                  Tài khoản Email hệ thống (.edu.vn)
                </span>
                <div className="h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg flex items-center justify-between text-slate-900">
                  <div className="flex items-center gap-2">
                    <Mail className="w-4 h-4 text-primary-700" />
                    <span>{profile?.email || 'user@unicheck.edu.vn'}</span>
                  </div>
                  <span className="px-2 py-0.5 rounded bg-primary-100 text-primary-800 font-bold text-[10px]">
                    Primary Account
                  </span>
                </div>
              </div>

              {/* Student specific fields */}
              {profile?.role === 'STUDENT' && (
                <>
                  <div className="space-y-1">
                    <span className="font-semibold text-slate-500 uppercase tracking-wider text-[11px]">
                      Khóa học sinh viên
                    </span>
                    <div className="h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg flex items-center justify-between text-slate-900 font-medium">
                      <span>{profile?.studentCourse || 'K18 (2022 - 2026)'}</span>
                      <GraduationCap className="w-4 h-4 text-slate-400" />
                    </div>
                  </div>

                  <div className="space-y-1">
                    <span className="font-semibold text-slate-500 uppercase tracking-wider text-[11px]">
                      Điểm trung bình tích lũy (GPA)
                    </span>
                    <div className="h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg flex items-center justify-between text-slate-900 font-mono font-bold">
                      <span className="text-emerald-700">{profile?.gpa ? profile.gpa.toFixed(2) : '3.45 / 4.0'}</span>
                      <span className="text-[10px] text-slate-400">Thang 4</span>
                    </div>
                  </div>
                </>
              )}

              {/* Lecturer specific fields */}
              {profile?.role === 'LECTURER' && (
                <>
                  <div className="space-y-1">
                    <span className="font-semibold text-slate-500 uppercase tracking-wider text-[11px]">
                      Khoa / Bộ môn giảng dạy
                    </span>
                    <div className="h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg flex items-center text-slate-900 font-medium">
                      <span>{profile?.department || 'Khoa Công nghệ Thông tin'}</span>
                    </div>
                  </div>

                  <div className="space-y-1">
                    <span className="font-semibold text-slate-500 uppercase tracking-wider text-[11px]">
                      Chuyên môn phụ trách
                    </span>
                    <div className="h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg flex items-center text-slate-900 font-medium">
                      <span>{profile?.expertise || 'Trí tuệ nhân tạo & Thị giác máy tính'}</span>
                    </div>
                  </div>
                </>
              )}
            </div>

            {/* Permissions list chips */}
            {profile?.permissions && profile.permissions.length > 0 && (
              <div className="pt-3 border-t border-slate-100 space-y-2">
                <span className="font-semibold text-slate-500 uppercase tracking-wider text-[11px] block">
                  Danh mục quyền hạn được cấp phát (Permissions)
                </span>
                <div className="flex flex-wrap gap-1.5">
                  {profile.permissions.map((perm) => (
                    <span
                      key={perm}
                      className="px-2.5 py-1 rounded-md bg-slate-100 text-slate-700 text-[11px] font-mono font-medium border border-slate-200"
                    >
                      {perm}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Section 2: Editable Personal Contact Information Form */}
          <form
            onSubmit={handleSaveProfile}
            className="bg-white rounded-2xl border border-slate-200/90 shadow-sm p-6 sm:p-7 space-y-5"
          >
            <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3 border-b border-slate-100 gap-2">
              <div className="flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-accent-600" />
                <h3 className="font-bold text-base text-slate-900">
                  Thông tin cá nhân & Liên lạc
                </h3>
              </div>
              <span className="text-emerald-700 bg-emerald-50 border border-emerald-200 text-xs font-semibold px-2.5 py-0.5 rounded-full flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5" />
                Được phép cập nhật trực tuyến
              </span>
            </div>

            {/* Error in form */}
            {error && (
              <div
                role="alert"
                className="p-3 rounded-xl bg-red-50 border border-red-200 text-red-700 text-xs flex items-start gap-2"
              >
                <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {/* Full Name */}
              <div className="space-y-1.5">
                <label
                  htmlFor="profile-fullName"
                  className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                >
                  Họ và tên hiển thị
                </label>
                <div className="relative rounded-lg shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                    <UserIcon className="w-4 h-4" />
                  </div>
                  <input
                    id="profile-fullName"
                    type="text"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    placeholder="Nguyễn Văn A"
                    required
                    disabled={saving}
                    className="w-full h-10 pl-9 pr-3.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15"
                  />
                </div>
              </div>

              {/* Phone */}
              <div className="space-y-1.5">
                <label
                  htmlFor="profile-phone"
                  className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                >
                  Số điện thoại di động
                </label>
                <div className="relative rounded-lg shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                    <Phone className="w-4 h-4" />
                  </div>
                  <input
                    id="profile-phone"
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="0901234567"
                    disabled={saving}
                    className="w-full h-10 pl-9 pr-3.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15"
                  />
                </div>
              </div>

              {/* Date of Birth */}
              <div className="space-y-1.5">
                <label
                  htmlFor="profile-dob"
                  className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                >
                  Ngày sinh
                </label>
                <div className="relative rounded-lg shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                    <Calendar className="w-4 h-4" />
                  </div>
                  <input
                    id="profile-dob"
                    type="date"
                    value={dob}
                    onChange={(e) => setDob(e.target.value)}
                    disabled={saving}
                    className="w-full h-10 pl-9 pr-3.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15"
                  />
                </div>
              </div>

              {/* Gender */}
              <div className="space-y-1.5">
                <label
                  htmlFor="profile-sex"
                  className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                >
                  Giới tính
                </label>
                <select
                  id="profile-sex"
                  value={sex}
                  onChange={(e) => setSex(e.target.value)}
                  disabled={saving}
                  className="w-full h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15"
                >
                  <option value="NAM">Nam</option>
                  <option value="NU">Nữ</option>
                  <option value="KHAC">Khác</option>
                </select>
              </div>

              {/* Avatar URL */}
              <div className="sm:col-span-2 space-y-1.5">
                <label
                  htmlFor="profile-avatar"
                  className="block text-xs font-semibold uppercase tracking-wider text-slate-700"
                >
                  Liên kết ảnh đại diện (Avatar URL)
                </label>
                <input
                  id="profile-avatar"
                  type="url"
                  value={avatar}
                  onChange={(e) => setAvatar(e.target.value)}
                  placeholder="https://example.com/avatar.jpg"
                  disabled={saving}
                  className="w-full h-10 px-3.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 focus:bg-white focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15"
                />
              </div>
            </div>

            {/* Action Bar */}
            <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => {
                  if (profile) {
                    setFullName(profile.fullName || '');
                    setPhone(profile.phone || '');
                    setDob(profile.dob || '');
                    setSex(profile.sex || 'NAM');
                    setAvatar(profile.avatar || '');
                  }
                }}
                disabled={saving}
                className="h-10 px-4 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs font-semibold transition"
              >
                Khôi phục ban đầu
              </button>

              <button
                type="submit"
                id="btn-save-profile"
                disabled={saving}
                className="h-10 px-5 rounded-lg bg-primary-700 hover:bg-primary-800 text-white text-xs font-semibold shadow-sm flex items-center gap-1.5 transition disabled:opacity-50"
              >
                {saving ? (
                  <>
                    <div className="w-3.5 h-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    <span>Đang lưu...</span>
                  </>
                ) : (
                  <>
                    <Save className="w-3.5 h-3.5" />
                    <span>Lưu thay đổi hồ sơ</span>
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default ProfilePage;
