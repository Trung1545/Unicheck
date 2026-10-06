export interface ApiResponse<T = any> {
  success: boolean;
  data: T;
  message: string;
  errorCode: string | null;
}

export interface User {
  id: number;
  username: string;
  fullName: string;
  email: string;
  role?: string;
  avatar?: string;
  faceDataStatus?: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface LoginResponse {
  user: User;
  tokens: AuthTokens;
}
