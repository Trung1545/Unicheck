import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';
import { ApiResponse } from '../types/api';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 15000,
});

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

apiClient.interceptors.response.use(
  (response) => {
    return response.data;
  },
  (error: AxiosError<ApiResponse>) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('access_token');
    }
    const responseData = error.response?.data;
    const errorMessage = responseData?.message || error.message || 'Lỗi mạng kết nối đến máy chủ';
    return Promise.reject(new Error(errorMessage));
  }
);

export default apiClient;
