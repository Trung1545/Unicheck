import React from 'react';
import { Outlet } from 'react-router-dom';
import { ScanFace } from 'lucide-react';

export interface AuthLayoutProps {
  children?: React.ReactNode;
}

export const AuthLayout: React.FC<AuthLayoutProps> = ({ children }) => {
  return (
    <div className="min-h-screen bg-slate-950 flex flex-col justify-between relative overflow-hidden text-slate-100">
      {/* Ambient background glows */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-primary-700/20 rounded-full blur-3xl pointer-events-none animate-pulse" />
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-accent-500/15 rounded-full blur-3xl pointer-events-none" />

      {/* Top Simple Header */}
      <header className="relative z-10 p-6 flex items-center justify-between max-w-7xl mx-auto w-full">
        <div className="flex items-center gap-2.5">
          <div className="w-10 h-10 rounded-xl bg-primary-700 flex items-center justify-center shadow-lg shadow-primary-700/30">
            <ScanFace className="w-6 h-6 text-white" />
          </div>
          <div>
            <span className="font-bold text-lg text-white block leading-tight">UniCheck</span>
            <span className="text-xs text-primary-300 block leading-tight">Biometric Attendance Ecosystem</span>
          </div>
        </div>

        <div className="text-xs text-slate-400 font-medium">
          Đại học & Học viện Công nghệ
        </div>
      </header>

      {/* Center Auth Card Slot */}
      <main className="relative z-10 flex-1 flex items-center justify-center p-4">
        {children || <Outlet />}
      </main>

      {/* Footer */}
      <footer className="relative z-10 p-6 text-center text-xs text-slate-500">
        © 2024 - 2026 UniCheck. Hệ thống xác thực sinh trắc học và quản trị đào tạo đại học.
      </footer>
    </div>
  );
};

export default AuthLayout;
