import React, { useEffect, useState } from 'react';
import { BrowserRouter, useNavigate } from 'react-router-dom';
import { ShieldAlert, X } from 'lucide-react';
import { AppRoutes } from './routes';

const SessionExpiryListener: React.FC = () => {
  const [expired, setExpired] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const handleExpired = () => {
      setExpired(true);
      navigate('/login');
    };

    window.addEventListener('unicheck:session-expired', handleExpired);
    return () => window.removeEventListener('unicheck:session-expired', handleExpired);
  }, [navigate]);

  if (!expired) return null;

  return (
    <div className="fixed top-4 right-4 z-50 max-w-sm w-full bg-red-600 text-white p-3.5 rounded-xl shadow-2xl flex items-start justify-between gap-3 text-xs animate-fadeIn">
      <div className="flex items-start gap-2.5">
        <ShieldAlert className="w-4 h-4 text-white shrink-0 mt-0.5" />
        <div>
          <p className="font-bold">Phiên làm việc đã hết hạn</p>
          <p className="text-red-100 text-[11px] mt-0.5">
            Mã xác thực của bạn đã hết thời hạn hoặc bị thu hồi. Vui lòng đăng nhập lại.
          </p>
        </div>
      </div>
      <button
        type="button"
        onClick={() => setExpired(false)}
        className="text-white/80 hover:text-white p-1 transition"
        aria-label="Đóng thông báo"
      >
        <X className="w-3.5 h-3.5" />
      </button>
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <BrowserRouter>
      <SessionExpiryListener />
      <AppRoutes />
    </BrowserRouter>
  );
};

export default App;
