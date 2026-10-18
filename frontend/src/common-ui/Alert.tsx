import React from 'react';
import { CheckCircle2, AlertTriangle, AlertCircle, Info, X } from 'lucide-react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export type AlertVariant = 'success' | 'warning' | 'error' | 'info';

export interface AlertProps {
  variant?: AlertVariant;
  title?: string;
  message?: string;
  children?: React.ReactNode;
  onClose?: () => void;
  className?: string;
}

export const Alert: React.FC<AlertProps> = ({
  variant = 'info',
  title,
  message,
  children,
  onClose,
  className,
}) => {
  const variantConfig = {
    success: {
      container: 'bg-emerald-50 border-emerald-200 text-emerald-900',
      icon: <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />,
      closeBtn: 'text-emerald-700 hover:bg-emerald-100',
    },
    warning: {
      container: 'bg-amber-50 border-amber-200 text-amber-900',
      icon: <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />,
      closeBtn: 'text-amber-700 hover:bg-amber-100',
    },
    error: {
      container: 'bg-red-50 border-red-200 text-red-900',
      icon: <AlertCircle className="w-5 h-5 text-red-600 shrink-0 mt-0.5" />,
      closeBtn: 'text-red-700 hover:bg-red-100',
    },
    info: {
      container: 'bg-blue-50 border-blue-200 text-blue-900',
      icon: <Info className="w-5 h-5 text-blue-600 shrink-0 mt-0.5" />,
      closeBtn: 'text-blue-700 hover:bg-blue-100',
    },
  };

  const config = variantConfig[variant];

  return (
    <div
      role="alert"
      className={twMerge(
        clsx(
          'p-3.5 rounded-xl border flex items-start justify-between gap-3 shadow-sm text-sm transition-all',
          config.container,
          className
        )
      )}
    >
      <div className="flex items-start gap-3">
        {config.icon}
        <div className="space-y-0.5">
          {title && <h5 className="font-semibold text-sm leading-tight">{title}</h5>}
          {message && <p className="text-xs opacity-90">{message}</p>}
          {children}
        </div>
      </div>

      {onClose && (
        <button
          type="button"
          onClick={onClose}
          aria-label="Đóng thông báo"
          className={clsx(
            'p-1 rounded-lg transition-colors shrink-0',
            config.closeBtn
          )}
        >
          <X className="w-4 h-4" />
        </button>
      )}
    </div>
  );
};
