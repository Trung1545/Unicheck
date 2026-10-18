import { create } from 'zustand';
import { CurrentUser, LoginResponse, Role, UserProfileResponse } from '../types/api';

interface AuthState {
  user: CurrentUser | null;
  token: string | null;
  refreshToken: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;

  setAuth: (
    data: LoginResponse | CurrentUser | { user: CurrentUser; token: string; refreshToken?: string },
    legacyToken?: string
  ) => void;
  updateTokens: (token: string, refreshToken: string) => void;
  setUser: (user: CurrentUser | UserProfileResponse) => void;
  logout: () => void;
}

const getStoredUser = (): CurrentUser | null => {
  try {
    const raw = localStorage.getItem('unicheck_user');
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
};

const getStoredToken = (): string | null => {
  try {
    return localStorage.getItem('access_token');
  } catch {
    return null;
  }
};

const getStoredRefreshToken = (): string | null => {
  try {
    return localStorage.getItem('refresh_token');
  } catch {
    return null;
  }
};

export const useAuthStore = create<AuthState>((set) => ({
  user: getStoredUser(),
  token: getStoredToken(),
  refreshToken: getStoredRefreshToken(),
  isAuthenticated: !!getStoredToken(),
  isLoading: false,

  setAuth: (data, legacyToken) => {
    let token = '';
    let refreshToken = '';
    let user: CurrentUser;

    // Check if called with legacy format: setAuth(userObj, tokenString)
    if (legacyToken && typeof legacyToken === 'string') {
      token = legacyToken;
      user = data as CurrentUser;
      refreshToken = localStorage.getItem('refresh_token') || '';
    } else if ('userId' in (data as any) && 'token' in (data as any)) {
      // Backend Flat LoginResponse Contract
      const flat = data as LoginResponse;
      token = flat.token;
      refreshToken = flat.refreshToken;
      user = {
        id: flat.userId,
        code: flat.code,
        username: flat.username,
        fullName: flat.fullName,
        email: flat.email,
        role: flat.role,
        isPasswordChanged: flat.isPasswordChanged,
      };
    } else if ('user' in (data as any) && 'token' in (data as any)) {
      // Nested legacy format
      const nested = data as { user: CurrentUser; token: string; refreshToken?: string };
      token = nested.token;
      refreshToken = nested.refreshToken || '';
      user = nested.user;
    } else {
      token = localStorage.getItem('access_token') || '';
      refreshToken = localStorage.getItem('refresh_token') || '';
      user = data as CurrentUser;
    }

    try {
      if (token) localStorage.setItem('access_token', token);
      if (refreshToken) localStorage.setItem('refresh_token', refreshToken);
      if (user) localStorage.setItem('unicheck_user', JSON.stringify(user));
    } catch {
      // Ignore storage write errors (e.g. quota/incognito)
    }

    set({
      user,
      token,
      refreshToken,
      isAuthenticated: !!token,
      isLoading: false,
    });
  },

  updateTokens: (token: string, refreshToken: string) => {
    try {
      localStorage.setItem('access_token', token);
      localStorage.setItem('refresh_token', refreshToken);
    } catch {
      // Ignore storage write errors
    }
    set({ token, refreshToken, isAuthenticated: !!token });
  },

  setUser: (user: CurrentUser | UserProfileResponse) => {
    try {
      localStorage.setItem('unicheck_user', JSON.stringify(user));
    } catch {
      // Ignore storage write errors
    }
    set({ user });
  },

  logout: () => {
    try {
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      localStorage.removeItem('unicheck_user');
    } catch {
      // Ignore storage errors
    }
    set({
      user: null,
      token: null,
      refreshToken: null,
      isAuthenticated: false,
      isLoading: false,
    });
  },
}));
