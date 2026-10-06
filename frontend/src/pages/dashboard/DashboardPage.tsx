import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Users,
  Calendar,
  CheckCircle2,
  Cpu,
  LogOut,
  ScanFace,
  Server,
  Activity,
  Layers,
  ChevronRight
} from 'lucide-react';
import { useAuthStore } from '../../store/auth-store';

export const DashboardPage: React.FC = () => {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const stats = [
    { label: 'Tổng số lớp học', value: '48', icon: Layers, color: 'text-indigo-400', bg: 'bg-indigo-500/10' },
    { label: 'Ca học hôm nay', value: '12', icon: Calendar, color: 'text-cyan-400', bg: 'bg-cyan-500/10' },
    { label: 'Sinh viên đã điểm danh', value: '384', icon: CheckCircle2, color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    { label: 'Độ chính xác AI Face', value: '99.4%', icon: Cpu, color: 'text-amber-400', bg: 'bg-amber-500/10' },
  ];

  const recentSessions = [
    { code: 'SE104.O21', name: 'Nhập môn Công nghệ Phần mềm', room: 'A201', time: '07:30 - 09:00', status: 'Đang mở', count: '42/45' },
    { code: 'CS202.N11', name: 'Trí tuệ Nhân tạo & Thị giác Máy', room: 'B104', time: '09:15 - 11:45', status: 'Chuẩn bị mở', count: '38/40' },
    { code: 'IT301.L22', name: 'Lập trình Di động Flutter', room: 'Lab 03', time: '13:00 - 15:30', status: 'Đã hoàn thành', count: '35/35' },
  ];

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      {/* Top Navigation */}
      <header className="border-b border-slate-800/80 bg-slate-900/60 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-600 to-cyan-500 flex items-center justify-center shadow-lg shadow-indigo-500/20">
              <ScanFace className="w-6 h-6 text-white" />
            </div>
            <div>
              <span className="font-bold text-lg text-white">UniCheck</span>
              <span className="ml-2 text-xs text-indigo-400 border border-indigo-500/30 px-2 py-0.5 rounded-full">
                Portal Giảng Viên & Quản Trị
              </span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div className="text-right hidden sm:block">
              <div className="text-sm font-semibold text-slate-200">{user?.fullName || 'Giảng viên quản trị'}</div>
              <div className="text-xs text-slate-400">{user?.email || 'admin@unicheck.edu.vn'}</div>
            </div>
            <button
              onClick={handleLogout}
              className="p-2 text-slate-400 hover:text-red-400 hover:bg-slate-800/60 rounded-xl transition"
              title="Đăng xuất"
            >
              <LogOut className="w-5 h-5" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
        {/* Welcome Section */}
        <div className="glass-card rounded-2xl p-6 border border-white/5 relative overflow-hidden">
          <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h2 className="text-2xl font-bold text-white">
                Chào mừng trở lại, <span className="gradient-text">{user?.fullName || 'Thầy/Cô'}</span>!
              </h2>
              <p className="text-sm text-slate-400 mt-1">
                Hệ thống nhận diện khuôn mặt và xác minh thực thể (Liveness Detection) đang hoạt động ổn định.
              </p>
            </div>
            <div className="flex items-center gap-3">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                <Activity className="w-3.5 h-3.5 animate-pulse" />
                Dịch vụ AI: Sẵn sàng
              </span>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                <Server className="w-3.5 h-3.5" />
                Backend: v1.0.0
              </span>
            </div>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {stats.map((stat, idx) => {
            const Icon = stat.icon;
            return (
              <div key={idx} className="glass-card glass-card-hover rounded-2xl p-5 border border-white/5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-medium text-slate-400">{stat.label}</span>
                  <div className={`p-2.5 rounded-xl ${stat.bg}`}>
                    <Icon className={`w-5 h-5 ${stat.color}`} />
                  </div>
                </div>
                <div className="text-2xl font-bold text-white mt-3">{stat.value}</div>
              </div>
            );
          })}
        </div>

        {/* Recent Attendance Sessions */}
        <div className="glass-card rounded-2xl p-6 border border-white/5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="text-lg font-semibold text-white">Ca điểm danh gần đây</h3>
              <p className="text-xs text-slate-400">Danh sách các lớp học có lịch điểm danh hôm nay</p>
            </div>
            <button className="text-xs text-indigo-400 hover:text-indigo-300 flex items-center gap-1 font-medium">
              Xem tất cả <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-800 text-xs uppercase text-slate-400">
                  <th className="pb-3 font-semibold">Mã Lớp</th>
                  <th className="pb-3 font-semibold">Môn học</th>
                  <th className="pb-3 font-semibold">Phòng</th>
                  <th className="pb-3 font-semibold">Thời gian</th>
                  <th className="pb-3 font-semibold">Hiện diện</th>
                  <th className="pb-3 font-semibold text-right">Trạng thái</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60">
                {recentSessions.map((session, index) => (
                  <tr key={index} className="hover:bg-slate-800/20 transition">
                    <td className="py-3.5 font-medium text-indigo-300">{session.code}</td>
                    <td className="py-3.5 text-slate-200">{session.name}</td>
                    <td className="py-3.5 text-slate-400">{session.room}</td>
                    <td className="py-3.5 text-slate-400">{session.time}</td>
                    <td className="py-3.5 text-slate-200 font-medium">{session.count}</td>
                    <td className="py-3.5 text-right">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${
                        session.status === 'Đang mở'
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                          : session.status === 'Chuẩn bị mở'
                          ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                          : 'bg-slate-800 text-slate-400'
                      }`}>
                        {session.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
};
