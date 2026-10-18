import axios, { AxiosError, AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import { ApiResponse, TokenRefreshResponse } from '../types/api';
import { useAuthStore } from '../store/auth-store';

const baseURL = import.meta.env.VITE_API_URL || '/api/v1';

export const apiClient: AxiosInstance = axios.create({
  baseURL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 15000,
});

// Queue to hold requests while token refresh is in progress
interface FailedQueueItem {
  resolve: (token: string) => void;
  reject: (error: any) => void;
}

let isRefreshing = false;
let failedQueue: FailedQueueItem[] = [];

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach((promise) => {
    if (error) {
      promise.reject(error);
    } else if (token) {
      promise.resolve(token);
    }
  });
  failedQueue = [];
};

// 1. Request Interceptor: Attach Access Token
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = localStorage.getItem('access_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 2. Response Interceptor: Unwrap ApiResponse & Handle 401 RTR
apiClient.interceptors.response.use(
  (response) => {
    return response.data;
  },
  async (error: AxiosError<ApiResponse>) => {
    const originalRequest = error.config as (InternalAxiosRequestConfig & { _retry?: boolean }) | undefined;

    if (!originalRequest) {
      const errorMessage = error.response?.data?.message || error.message || 'Lỗi mạng kết nối đến máy chủ';
      return Promise.reject(new Error(errorMessage));
    }

    const requestUrl = originalRequest.url || '';
    const isAuthRoute =
      requestUrl.includes('/auth/login') ||
      requestUrl.includes('/auth/refresh-token') ||
      requestUrl.includes('/auth/logout');

    // If 401 and not already retried and not an auth bypass route
    if (error.response?.status === 401 && !originalRequest._retry && !isAuthRoute) {
      const storedRefreshToken = localStorage.getItem('refresh_token');

      // If no refresh token is present, force logout immediately
      if (!storedRefreshToken) {
        useAuthStore.getState().logout();
        return Promise.reject(new Error(error.response?.data?.message || 'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.'));
      }

      // If already refreshing, queue this pending request
      if (isRefreshing) {
        return new Promise<string>((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        })
          .then((newToken) => {
            if (originalRequest.headers) {
              originalRequest.headers.Authorization = `Bearer ${newToken}`;
            }
            return apiClient(originalRequest);
          })
          .catch((err) => Promise.reject(err));
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        // Dedicated plain axios call without interceptor chaining to avoid circular 401 loop
        const refreshResponse = await axios.post<ApiResponse<TokenRefreshResponse>>(
          `${baseURL}/auth/refresh-token`,
          { refreshToken: storedRefreshToken },
          {
            headers: { 'Content-Type': 'application/json' },
            timeout: 10000,
          }
        );

        const data = refreshResponse.data?.data;
        if (refreshResponse.data?.success && data?.token) {
          const newAccessToken = data.token;
          const newRefreshToken = data.refreshToken || storedRefreshToken;

          // Update storage & store
          useAuthStore.getState().updateTokens(newAccessToken, newRefreshToken);

          // Retry queued requests
          processQueue(null, newAccessToken);

          // Retry original request
          if (originalRequest.headers) {
            originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
          }
          return apiClient(originalRequest);
        } else {
          throw new Error('Không thể làm mới mã xác thực');
        }
      } catch (refreshError: any) {
        // Refresh token failed or revoked/reused
        processQueue(refreshError, null);
        useAuthStore.getState().logout();

        // Dispatch optional notification event for UI listeners
        if (typeof window !== 'undefined') {
          window.dispatchEvent(new CustomEvent('unicheck:session-expired'));
        }

        const msg = refreshError.response?.data?.message || 'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.';
        return Promise.reject(new Error(msg));
      } finally {
        isRefreshing = false;
      }
    }

    const responseData = error.response?.data;
    const errorMessage = responseData?.message || error.message || 'Lỗi mạng kết nối đến máy chủ';
    return Promise.reject(new Error(errorMessage));
  }
);

export default apiClient;
