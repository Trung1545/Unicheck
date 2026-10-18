import React from 'react';
import { Loader2 } from 'lucide-react';
import { clsx } from 'clsx';

export interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  label?: string;
  className?: string;
}

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  size = 'md',
  label,
  className,
}) => {
  const sizeMap = {
    sm: 'w-4 h-4',
    md: 'w-6 h-6',
    lg: 'w-8 h-8',
    xl: 'w-12 h-12',
  };

  return (
    <div
      role="status"
      className={clsx('flex flex-col items-center justify-center gap-2 text-primary-700', className)}
    >
      <Loader2 className={clsx('animate-spin', sizeMap[size])} />
      {label && <span className="text-xs font-medium text-slate-500">{label}</span>}
      <span className="sr-only">Đang tải dữ liệu...</span>
    </div>
  );
};
