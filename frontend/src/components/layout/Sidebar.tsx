import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { ScanFace, X, Activity } from 'lucide-react';
import { clsx } from 'clsx';
import { NAVIGATION_CONFIG } from '../../config/navigation.config';
import { useAuthStore } from '../../store/auth-store';
import { Role } from '../../types/api';

export interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ isOpen, onClose }) => {
  const location = useLocation();
  const user = useAuthStore((state) => state.user);

  // Default to ADMIN if no role set, or fallback to user.role
  const currentRole: Role = (user?.role as Role) || 'ADMIN';
  const navSections = NAVIGATION_CONFIG[currentRole] || NAVIGATION_CONFIG.ADMIN;

  const roleLabelMap: Record<Role, string> = {
    ADMIN: 'QUẢN TRỊ VIÊN',
    LECTURER: 'GIẢNG VIÊN',
    STUDENT: 'SINH VIÊN',
  };

  const NavContent = (
    <div className="flex flex-col h-full justify-between">
      {/* Top Branding & Navigation */}
      <div className="flex flex-col">
        {/* Brand Header */}
        <div className="p-4 lg:p-5 border-b border-slate-100 flex items-center justify-between">
          <Link
            to="/dashboard"
            onClick={onClose}
            className="flex items-center gap-2.5 group"
          >
            <div className="w-9 h-9 rounded-xl bg-primary-700 text-white flex items-center justify-center shadow-md shadow-primary-700/20 group-hover:bg-primary-800 transition">
              <ScanFace className="w-5 h-5" />
            </div>
            <div>
              <span className="text-base font-bold text-slate-900 tracking-tight block leading-tight">
                UniCheck
              </span>
              <span className="text-[11px] text-slate-500 block leading-tight font-medium">
                Điểm danh thông minh, quản lý dễ dàng
              </span>
            </div>
          </Link>

          {/* Close button for Mobile Drawer */}
          <button
            type="button"
            onClick={onClose}
            aria-label="Đóng thanh điều hướng"
            className="lg:hidden p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Role Pill */}
        <div className="px-4 pt-3 pb-1">
          <div className="bg-slate-50 border border-slate-200/80 p-2 rounded-lg flex items-center justify-between text-xs">
            <span className="font-bold tracking-wider text-slate-800 text-[11px]">
              {roleLabelMap[currentRole]}
            </span>
            <span className="inline-flex items-center gap-1 font-semibold text-emerald-700 text-[11px]">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Trực tuyến
            </span>
          </div>
        </div>

        {/* Navigation Sections */}
        <nav className="p-3 space-y-4 overflow-y-auto max-h-[calc(100vh-210px)]" aria-label="Main Navigation">
          {navSections.map((section) => (
            <div key={section.title} className="space-y-1">
              <div className="px-3 py-1">
                <span className="text-[10px] font-bold uppercase tracking-wider text-slate-600">
                  {section.title}
                </span>
              </div>

              {section.items.map((item) => {
                const Icon = item.icon;
                const isActive =
                  location.pathname === item.path ||
                  (item.path !== '/dashboard' && location.pathname.startsWith(item.path));

                return (
                  <Link
                    key={item.id}
                    to={item.path}
                    onClick={onClose}
                    className={clsx(
                      'flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all select-none',
                      isActive
                        ? 'bg-primary-700 text-white font-semibold shadow-sm'
                        : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
                    )}
                  >
                    <div className="flex items-center gap-2.5">
                      <Icon className={clsx('w-4 h-4 shrink-0', isActive ? 'text-white' : 'text-slate-400')} />
                      <span>{item.label}</span>
                    </div>

                    {item.badge !== undefined && (
                      <span
                        className={clsx(
                          'px-1.5 py-0.5 rounded-full text-[10px] font-bold min-w-[18px] text-center',
                          isActive ? 'bg-white text-primary-800' : 'bg-red-500 text-white'
                        )}
                      >
                        {item.badge}
                      </span>
                    )}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>
      </div>

      {/* Footer System Status Card */}
      <div className="p-3 m-3 rounded-xl bg-slate-50 border border-slate-200/80 space-y-1">
        <div className="flex items-center justify-between text-xs font-semibold text-slate-800">
          <span>Hệ thống AI & CSDL</span>
          <span className="inline-flex items-center gap-1 text-emerald-600 font-semibold text-[11px]">
            <Activity className="w-3 h-3 animate-pulse" />
            Sẵn sàng
          </span>
        </div>
        <p className="text-[10px] text-slate-500 leading-tight">
          Trạng thái hoạt động bình thường
        </p>
      </div>
    </div>
  );

  return (
    <>
      {/* Desktop Persistent Sidebar */}
      <aside className="hidden lg:flex fixed left-0 top-0 h-screen w-64 bg-white border-r border-slate-200/90 z-40 flex-col shadow-sm">
        {NavContent}
      </aside>

      {/* Mobile Drawer with Overlay */}
      {isOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          {/* Backdrop */}
          <div
            className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm transition-opacity"
            onClick={onClose}
            aria-hidden="true"
          />

          {/* Drawer content */}
          <aside className="relative w-64 max-w-[85vw] h-full bg-white shadow-2xl z-10">
            {NavContent}
          </aside>
        </div>
      )}
    </>
  );
};
