import {
  LayoutDashboard,
  Users,
  GraduationCap,
  Calendar,
  CheckCircle2,
  FileText,
  Bell,
  ShieldAlert,
  Settings,
  BookOpen,
  ClipboardList,
  History,
  QrCode,
  ScanFace,
  UserCheck,
  Wifi,
} from 'lucide-react';
import { Role } from '../types/api';

export interface NavItem {
  id: string;
  label: string;
  path: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: string | number;
}

export interface NavSection {
  title: string;
  items: NavItem[];
}

export const NAVIGATION_CONFIG: Record<Role, NavSection[]> = {
  ADMIN: [
    {
      title: 'Trung tâm điều hành',
      items: [
        {
          id: 'admin-dashboard',
          label: 'Tổng quan hệ thống',
          path: '/dashboard',
          icon: LayoutDashboard,
        },
        {
          id: 'admin-attendance-sessions',
          label: 'Quản lý điểm danh',
          path: '/dashboard/attendance-sessions',
          icon: CheckCircle2,
        },
        {
          id: 'admin-classes',
          label: 'Lớp học phần',
          path: '/dashboard/classes',
          icon: BookOpen,
        },
      ],
    },
    {
      title: 'Người dùng & Đào tạo',
      items: [
        {
          id: 'admin-users',
          label: 'Quản lý Người dùng',
          path: '/admin/users',
          icon: Users,
        },
        {
          id: 'admin-semesters',
          label: 'Học kỳ & Niên khóa',
          path: '/admin/semesters',
          icon: Calendar,
        },
        {
          id: 'admin-courses',
          label: 'Danh mục học phần',
          path: '/admin/courses',
          icon: BookOpen,
        },
        {
          id: 'admin-enrollments',
          label: 'Ghi danh & Đăng ký',
          path: '/admin/enrollments',
          icon: UserCheck,
        },
        {
          id: 'admin-timetable',
          label: 'Thời khóa biểu',
          path: '/admin/timetable',
          icon: Calendar,
        },
        {
          id: 'admin-students',
          label: 'Quản lý Sinh viên',
          path: '/dashboard/students',
          icon: GraduationCap,
        },
        {
          id: 'admin-lecturers',
          label: 'Quản lý Giảng viên',
          path: '/dashboard/lecturers',
          icon: UserCheck,
        },
      ],
    },
    {
      title: 'Cơ sở vật chất & Hạ tầng',
      items: [
        {
          id: 'admin-facilities',
          label: 'Phòng học & Wi-Fi AP',
          path: '/admin/facilities',
          icon: Wifi,
        },
      ],
    },
    {
      title: 'Dữ liệu & Giám sát',
      items: [
        {
          id: 'admin-reports',
          label: 'Báo cáo & Thống kê',
          path: '/dashboard/reports',
          icon: FileText,
        },
        {
          id: 'admin-notifications',
          label: 'Trung tâm thông báo',
          path: '/dashboard/notifications',
          icon: Bell,
          badge: 5,
        },
        {
          id: 'admin-security-alerts',
          label: 'Cảnh báo an ninh',
          path: '/dashboard/security-alerts',
          icon: ShieldAlert,
        },
      ],
    },
    {
      title: 'Cấu hình',
      items: [
        {
          id: 'admin-attendance-configs',
          label: 'Cấu hình điểm danh',
          path: '/dashboard/attendance-configs',
          icon: Settings,
        },
        {
          id: 'admin-settings',
          label: 'Cài đặt hệ thống',
          path: '/dashboard/settings',
          icon: Settings,
        },
      ],
    },
  ],

  LECTURER: [
    {
      title: 'Giảng dạy',
      items: [
        {
          id: 'lecturer-dashboard',
          label: 'Bảng điều khiển',
          path: '/dashboard',
          icon: LayoutDashboard,
        },
        {
          id: 'lecturer-classes',
          label: 'Lớp học phần phụ trách',
          path: '/lecturer/classes',
          icon: BookOpen,
        },
        {
          id: 'lecturer-timetable',
          label: 'Lịch giảng dạy',
          path: '/lecturer/timetable',
          icon: Calendar,
        },
      ],
    },
    {
      title: 'Điểm danh & Đánh giá',
      items: [
        {
          id: 'lecturer-qr-session',
          label: 'Khởi tạo phiên & QR động',
          path: '/lecturer/attendance-session',
          icon: QrCode,
        },
        {
          id: 'lecturer-live-monitor',
          label: 'Giám sát trực tiếp',
          path: '/lecturer/live-monitor',
          icon: ScanFace,
        },
        {
          id: 'lecturer-reports',
          label: 'Báo cáo chuyên cần',
          path: '/lecturer/reports',
          icon: FileText,
        },
      ],
    },
    {
      title: 'Học vụ & Tương tác',
      items: [
        {
          id: 'lecturer-requests',
          label: 'Xét duyệt đơn học vụ',
          path: '/lecturer/requests',
          icon: ClipboardList,
          badge: 2,
        },
        {
          id: 'lecturer-notifications',
          label: 'Thông báo',
          path: '/notifications',
          icon: Bell,
        },
      ],
    },
  ],

  STUDENT: [
    {
      title: 'Học tập & Điểm danh',
      items: [
        {
          id: 'student-dashboard',
          label: 'Bảng điều khiển',
          path: '/dashboard',
          icon: LayoutDashboard,
        },
        {
          id: 'student-timetable',
          label: 'Thời khóa biểu tuần',
          path: '/student/timetable',
          icon: Calendar,
        },
        {
          id: 'student-classes',
          label: 'Lớp học phần của tôi',
          path: '/student/classes',
          icon: BookOpen,
        },
        {
          id: 'student-history',
          label: 'Lịch sử điểm danh',
          path: '/student/history',
          icon: History,
        },
      ],
    },
    {
      title: 'Sinh trắc học & Đơn từ',
      items: [
        {
          id: 'student-face-id',
          label: 'Đăng ký Face-ID',
          path: '/student/face-id',
          icon: ScanFace,
        },
        {
          id: 'student-requests',
          label: 'Đơn xin nghỉ & Khiếu nại',
          path: '/student/requests',
          icon: ClipboardList,
        },
        {
          id: 'student-notifications',
          label: 'Thông báo',
          path: '/notifications',
          icon: Bell,
        },
      ],
    },
  ],
};
