import React, { useState, useRef, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import {
  Menu,
  Bell,
  ChevronDown,
  User,
  KeyRound,
  LogOut,
  Calendar,
  Shield,
} from 'lucide-react';
import { useAuthStore } from '../../store/auth-store';
import { logoutApi } from '../../api/auth.api';

export interface HeaderProps {
  onOpenMobileSidebar: () => void;
}

export const Header: React.FC<HeaderProps> = ({ onOpenMobileSidebar }) => {
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();

  const user = useAuthStore((state) => state.user);
  const logout = useAuthStore((state) => state.logout);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleLogout = async () => {
    try {
      await logoutApi();
    } catch {
      // Ignore network errors on logout to allow offline/expired cleanup
    } finally {
      logout();
      navigate('/login');
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

  return (
    <header className="fixed top-0 left-0 lg:left-64 right-0 h-16 bg-white/95 backdrop-blur-md border-b border-slate-200/90 shadow-sm z-30 transition-all">
      <div className="h-full px-4 lg:px-8 flex items-center justify-between gap-4">
        {/* Left Section: Mobile Menu Trigger + Breadcrumb */}
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onOpenMobileSidebar}
            aria-label="Mở thanh điều hướng"
            className="lg:hidden p-2 rounded-lg text-slate-600 hover:bg-slate-100 transition"
          >
            <Menu className="w-5 h-5" />
          </button>

          <div className="hidden sm:flex items-center gap-2 text-xs font-medium text-slate-500">
            <Shield className="w-4 h-4 text-primary-700" />
            <span>Cổng Quản Trị Đào Tạo</span>
            <span>/</span>
            <span className="text-slate-900 font-semibold">UniCheck Biometric Hub</span>
          </div>
        </div>

        {/* Right Section: Semester Badge, Notifications & Profile Dropdown */}
        <div className="flex items-center gap-3">
          {/* Semester Badge (Stitch token) */}
          <div className="hidden md:flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-100 text-xs font-semibold text-slate-700 border border-slate-200/60">
            <Calendar className="w-3.5 h-3.5 text-primary-700" />
            <span>Học kỳ I (2024 - 2025)</span>
          </div>

          {/* Notifications Button */}
          <Link
            to="/notifications"
            aria-label="Thông báo hệ thống"
            className="relative p-2 rounded-lg text-slate-600 hover:bg-slate-100 transition"
          >
            <Bell className="w-5 h-5" />
            <span className="absolute top-1.5 right-1.5 min-w-[16px] h-4 px-1 rounded-full bg-red-600 text-white text-[10px] font-bold flex items-center justify-center leading-none">
              3
            </span>
          </Link>

          {/* User Profile Dropdown */}
          <div className="relative" ref={dropdownRef}>
            <button
              type="button"
              onClick={() => setDropdownOpen(!dropdownOpen)}
              className="flex items-center gap-2.5 p-1.5 rounded-lg hover:bg-slate-100 transition focus:outline-none"
              aria-expanded={dropdownOpen}
              aria-haspopup="true"
            >
              <div className="w-8 h-8 rounded-full bg-primary-700 text-white text-xs font-bold flex items-center justify-center shrink-0 shadow-sm">
                {getInitials(user?.fullName)}
              </div>

              <div className="hidden xl:flex flex-col text-left">
                <span className="text-xs font-semibold text-slate-900 leading-tight">
                  {user?.fullName || 'Người dùng'}
                </span>
                <span className="text-[10px] text-slate-500 leading-tight font-medium">
                  {user?.role || 'Khách'}
                </span>
              </div>

              <ChevronDown className="w-3.5 h-3.5 text-slate-400 hidden sm:block" />
            </button>

            {/* Dropdown Menu */}
            {dropdownOpen && (
              <div className="absolute right-0 mt-2 w-56 bg-white rounded-xl border border-slate-200/90 shadow-xl py-2 z-50 text-xs">
                <div className="px-4 py-2 border-b border-slate-100 space-y-0.5">
                  <p className="font-semibold text-slate-900 text-sm">{user?.fullName || 'Người dùng'}</p>
                  <p className="text-slate-500 text-[11px] truncate">{user?.email || 'user@unicheck.edu.vn'}</p>
                  <div className="pt-1">
                    <span className="inline-block px-2 py-0.5 rounded-full bg-primary-50 text-primary-800 text-[10px] font-bold">
                      {user?.role || 'MEMBER'}
                    </span>
                  </div>
                </div>

                <div className="py-1">
                  <Link
                    to="/profile"
                    onClick={() => setDropdownOpen(false)}
                    className="flex items-center gap-2.5 px-4 py-2 text-slate-700 hover:bg-slate-50 hover:text-primary-700 transition"
                  >
                    <User className="w-4 h-4 text-slate-400" />
                    <span>Hồ sơ cá nhân</span>
                  </Link>
                  <Link
                    to="/change-password"
                    onClick={() => setDropdownOpen(false)}
                    className="flex items-center gap-2.5 px-4 py-2 text-slate-700 hover:bg-slate-50 hover:text-primary-700 transition"
                  >
                    <KeyRound className="w-4 h-4 text-slate-400" />
                    <span>Đổi mật khẩu</span>
                  </Link>
                </div>

                <div className="border-t border-slate-100 pt-1">
                  <button
                    type="button"
                    onClick={handleLogout}
                    className="w-full flex items-center gap-2.5 px-4 py-2 text-red-600 hover:bg-red-50 transition text-left"
                  >
                    <LogOut className="w-4 h-4 text-red-500" />
                    <span className="font-semibold">Đăng xuất</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};
