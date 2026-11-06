import React from 'react';
import {
  Calendar,
  CheckCircle2,
  Cpu,
  Server,
  Activity,
  Layers,
  ChevronRight,
} from 'lucide-react';
import { useAuthStore } from '../../store/auth-store';

export const DashboardPage: React.FC = () => {
  const { user } = useAuthStore();

  const stats = [
    { label: 'Tổng số lớp học', value: '48', icon: Layers, color: 'text-primary-700', bg: 'bg-primary-50' },
    { label: 'Ca học hôm nay', value: '12', icon: Calendar, color: 'text-cyan-600', bg: 'bg-cyan-50' },
    { label: 'Sinh viên đã điểm danh', value: '384', icon: CheckCircle2, color: 'text-emerald-600', bg: 'bg-emerald-50' },
    { label: 'Trạng thái AI Face', value: 'Hoạt động', icon: Cpu, color: 'text-emerald-600', bg: 'bg-emerald-50' },
  ];

  const recentSessions = [
    { code: 'SE104.O21', name: 'Nhập môn Công nghệ Phần mềm', room: 'A201', time: '07:30 - 09:00', status: 'Đang mở', count: '42/45' },
    { code: 'CS202.N11', name: 'Trí tuệ Nhân tạo & Thị giác Máy', room: 'B104', time: '09:15 - 11:45', status: 'Chuẩn bị mở', count: '38/40' },
    { code: 'IT301.L22', name: 'Lập trình Di động Flutter', room: 'Lab 03', time: '13:00 - 15:30', status: 'Đã hoàn thành', count: '35/35' },
  ];

  return (
    <div className="space-y-6 text-left">
      {/* Welcome Banner */}
      <div className="bg-white p-6 rounded-xl border border-slate-200/90 shadow-sm relative overflow-hidden">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 className="text-xl lg:text-2xl font-bold text-slate-900 tracking-tight">
              Chào mừng trở lại, <span className="text-primary-700">{user?.fullName || 'Quý Thầy/Cô'}</span>!
            </h2>
            <p className="text-xs lg:text-sm text-slate-500 mt-1">
              Hệ thống nhận diện khuôn mặt và xác minh thực thể (Liveness Detection) đang hoạt động ổn định.
            </p>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
              <Activity className="w-3.5 h-3.5 animate-pulse text-emerald-500" />
              Dịch vụ AI: Sẵn sàng
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-primary-50 text-primary-700 border border-primary-200">
              <Server className="w-3.5 h-3.5 text-primary-600" />
              Backend: v1.0.0
            </span>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <div
              key={idx}
              className="bg-white p-5 rounded-xl border border-slate-200/90 shadow-sm flex items-center justify-between gap-3 hover:shadow-md transition-shadow"
            >
              <div className="space-y-1">
                <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
                  {stat.label}
                </span>
                <div className="text-2xl font-bold text-slate-900 data-tabular">{stat.value}</div>
              </div>
              <div className={`w-11 h-11 rounded-xl ${stat.bg} ${stat.color} flex items-center justify-center shrink-0`}>
                <Icon className="w-5 h-5" />
              </div>
            </div>
          );
        })}
      </div>

      {/* Recent Sessions Table */}
      <div className="bg-white rounded-xl border border-slate-200/90 shadow-sm overflow-hidden">
        <div className="p-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 className="text-base font-bold text-slate-900">Ca điểm danh gần đây</h3>
            <p className="text-xs text-slate-500">Danh sách các lớp học có lịch điểm danh hôm nay</p>
          </div>
          <button className="text-xs text-primary-700 hover:text-primary-800 flex items-center gap-1 font-semibold">
            Xem tất cả <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm min-w-[640px]">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-xs uppercase text-slate-600 font-semibold tracking-wider">
                <th className="py-3 px-4">Mã Lớp</th>
                <th className="py-3 px-4">Môn học</th>
                <th className="py-3 px-4">Phòng</th>
                <th className="py-3 px-4">Thời gian</th>
                <th className="py-3 px-4">Hiện diện</th>
                <th className="py-3 px-4 text-right">Trạng thái</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {recentSessions.map((session, index) => (
                <tr key={index} className="hover:bg-slate-50/80 transition">
                  <td className="py-3.5 px-4 font-semibold text-primary-700 data-tabular">{session.code}</td>
                  <td className="py-3.5 px-4 font-medium text-slate-900">{session.name}</td>
                  <td className="py-3.5 px-4 text-slate-600">{session.room}</td>
                  <td className="py-3.5 px-4 text-slate-600 data-tabular">{session.time}</td>
                  <td className="py-3.5 px-4 font-semibold text-slate-900 data-tabular">{session.count}</td>
                  <td className="py-3.5 px-4 text-right">
                    <span
                      className={`px-2.5 py-1 rounded-full text-xs font-semibold ${
                        session.status === 'Đang mở'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : session.status === 'Chuẩn bị mở'
                          ? 'bg-amber-50 text-amber-700 border border-amber-200'
                          : 'bg-slate-100 text-slate-600 border border-slate-200'
                      }`}
                    >
                      {session.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;
