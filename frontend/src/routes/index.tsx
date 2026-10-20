import React from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { LoginPage } from '../pages/auth/LoginPage';
import { ForgotPasswordPage } from '../pages/auth/ForgotPasswordPage';
import { VerifyOtpPage } from '../pages/auth/VerifyOtpPage';
import { ResetPasswordPage } from '../pages/auth/ResetPasswordPage';
import { ChangePasswordPage } from '../pages/auth/ChangePasswordPage';
import { ProfilePage } from '../pages/profile/ProfilePage';
import { DashboardPage } from '../pages/dashboard/DashboardPage';
import { UiKitPage } from '../pages/uikit/UiKitPage';
import { UserManagementPage } from '../pages/admin/UserManagementPage';
import { CourseCatalogPage } from '../pages/admin/CourseCatalogPage';
import { SemesterManagementPage } from '../pages/admin/SemesterManagementPage';
import { ClassSectionPage } from '../pages/admin/ClassSectionPage';
import { EnrollmentManagementPage } from '../pages/admin/EnrollmentManagementPage';
import { FacilitiesWifiPage } from '../pages/admin/FacilitiesWifiPage';
import { MasterTimetablePage } from '../pages/admin/MasterTimetablePage';
import { FaceRegistrationPage } from '../pages/student/FaceRegistrationPage';
import { AttendanceSessionManagementPage } from '../pages/admin/AttendanceSessionManagementPage';
import { AttendanceConfigPage } from '../pages/admin/AttendanceConfigPage';
import { SessionQrCodePage } from '../pages/lecturer/SessionQrCodePage';
import { MainLayout } from '../layouts/MainLayout';
import { AuthLayout } from '../layouts/AuthLayout';
import { useAuthStore } from '../store/auth-store';

/**
 * Guard for authenticated users
 * Enforces mandatory first-time password change policy
 */
export const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const user = useAuthStore((state) => state.user);
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // Prevent users from bypassing required initial password change
  if (user?.isPasswordChanged === false && location.pathname !== '/change-password') {
    return <Navigate to="/change-password?required=true" replace />;
  }

  return <>{children}</>;
};

/**
 * Guard specifically for ADMIN users
 */
export const AdminRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const user = useAuthStore((state) => state.user);
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (user?.isPasswordChanged === false && location.pathname !== '/change-password') {
    return <Navigate to="/change-password?required=true" replace />;
  }

  if (user?.role !== 'ADMIN') {
    return <Navigate to="/dashboard" replace />;
  }

  return <>{children}</>;
};

/**
 * Guard for unauthenticated guests (login, forgot-password, verify-otp, reset-password)
 */
export const GuestRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const user = useAuthStore((state) => state.user);

  if (isAuthenticated) {
    if (user?.isPasswordChanged === false) {
      return <Navigate to="/change-password?required=true" replace />;
    }
    return <Navigate to="/dashboard" replace />;
  }

  return <>{children}</>;
};

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      {/* 1. Guest Authentication Routes (Isolated AuthLayout) */}
      <Route
        path="/login"
        element={
          <GuestRoute>
            <AuthLayout>
              <LoginPage />
            </AuthLayout>
          </GuestRoute>
        }
      />

      <Route
        path="/forgot-password"
        element={
          <GuestRoute>
            <AuthLayout>
              <ForgotPasswordPage />
            </AuthLayout>
          </GuestRoute>
        }
      />

      <Route
        path="/verify-otp"
        element={
          <GuestRoute>
            <AuthLayout>
              <VerifyOtpPage />
            </AuthLayout>
          </GuestRoute>
        }
      />

      <Route
        path="/reset-password"
        element={
          <GuestRoute>
            <AuthLayout>
              <ResetPasswordPage />
            </AuthLayout>
          </GuestRoute>
        }
      />

      {/* 2. Protected User Profile & Self-Service Routes (MainLayout) */}
      <Route
        path="/profile"
        element={
          <ProtectedRoute>
            <MainLayout>
              <ProfilePage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/change-password"
        element={
          <ProtectedRoute>
            <MainLayout>
              <ChangePasswordPage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      {/* 2b. Student Face-ID Biometric Registration & Scanning (Stitch a17db05b39144990b49bee366c1e3b43) */}
      <Route
        path="/student/face-enrollment"
        element={
          <ProtectedRoute>
            <MainLayout>
              <FaceRegistrationPage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/student/face-id"
        element={
          <ProtectedRoute>
            <MainLayout>
              <FaceRegistrationPage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/profile/face-id"
        element={
          <ProtectedRoute>
            <MainLayout>
              <FaceRegistrationPage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      {/* 3. Admin Management Routes (Strict RBAC: ADMIN ONLY) */}
      <Route
        path="/admin/users"
        element={
          <AdminRoute>
            <MainLayout>
              <UserManagementPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/dashboard/users"
        element={
          <AdminRoute>
            <MainLayout>
              <UserManagementPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/admin/courses"
        element={
          <AdminRoute>
            <MainLayout>
              <CourseCatalogPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/dashboard/courses"
        element={
          <AdminRoute>
            <MainLayout>
              <CourseCatalogPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/admin/semesters"
        element={
          <AdminRoute>
            <MainLayout>
              <SemesterManagementPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/dashboard/semesters"
        element={
          <AdminRoute>
            <MainLayout>
              <SemesterManagementPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/admin/classes"
        element={
          <AdminRoute>
            <MainLayout>
              <ClassSectionPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/dashboard/classes"
        element={
          <AdminRoute>
            <MainLayout>
              <ClassSectionPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/admin/enrollments"
        element={
          <AdminRoute>
            <MainLayout>
              <EnrollmentManagementPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/dashboard/enrollments"
        element={
          <AdminRoute>
            <MainLayout>
              <EnrollmentManagementPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/admin/facilities"
        element={
          <AdminRoute>
            <MainLayout>
              <FacilitiesWifiPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/dashboard/facilities"
        element={
          <AdminRoute>
            <MainLayout>
              <FacilitiesWifiPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/admin/timetable"
        element={
          <AdminRoute>
            <MainLayout>
              <MasterTimetablePage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/dashboard/timetable"
        element={
          <AdminRoute>
            <MainLayout>
              <MasterTimetablePage />
            </MainLayout>
          </AdminRoute>
        }
      />

      {/* Attendance Session Management (TASK-05 - Stitch 4f83098c7b904d4389563c28f54e1c48) */}
      <Route
        path="/admin/attendance/sessions"
        element={
          <AdminRoute>
            <MainLayout>
              <AttendanceSessionManagementPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/dashboard/attendance-sessions"
        element={
          <AdminRoute>
            <MainLayout>
              <AttendanceSessionManagementPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      {/* Attendance Config (TASK-05 - Stitch 300c3071598340e5981a9a5f5097f909) */}
      <Route
        path="/admin/attendance/configs"
        element={
          <AdminRoute>
            <MainLayout>
              <AttendanceConfigPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      <Route
        path="/dashboard/attendance-configs"
        element={
          <AdminRoute>
            <MainLayout>
              <AttendanceConfigPage />
            </MainLayout>
          </AdminRoute>
        }
      />

      {/* Lecturer Attendance Management Routes */}
      <Route
        path="/lecturer/attendance/sessions"
        element={
          <ProtectedRoute>
            <MainLayout>
              <AttendanceSessionManagementPage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/lecturer/attendance-session"
        element={
          <ProtectedRoute>
            <MainLayout>
              <AttendanceSessionManagementPage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      {/* Dynamic QR Code Attendance (TASK-06 - Stitch 5c0df9af4d2545919e8f774c1159e7da) */}
      <Route
        path="/lecturer/session/qr"
        element={
          <ProtectedRoute>
            <MainLayout>
              <SessionQrCodePage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/lecturer/session/:sessionId/qr"
        element={
          <ProtectedRoute>
            <MainLayout>
              <SessionQrCodePage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/lecturer/sessions/:sessionId/qr"
        element={
          <ProtectedRoute>
            <MainLayout>
              <SessionQrCodePage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      {/* 4. Protected Dashboard Shell (MainLayout with Role-based Sidebar & Header) */}
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <MainLayout>
              <DashboardPage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      <Route
        path="/dashboard/*"
        element={
          <ProtectedRoute>
            <MainLayout>
              <DashboardPage />
            </MainLayout>
          </ProtectedRoute>
        }
      />

      {/* 4. Internal UI Kit Showcase & Responsive Testing */}
      <Route
        path="/uikit"
        element={
          <MainLayout>
            <UiKitPage />
          </MainLayout>
        }
      />

      {/* 5. Default Redirections */}
      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
};

export default AppRoutes;
