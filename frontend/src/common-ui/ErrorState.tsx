import React from 'react';
import { AlertCircle, RefreshCw } from 'lucide-react';
import { clsx } from 'clsx';
import { Button } from './Button';

export interface ErrorStateProps {
  title?: string;
  message?: string;
  onRetry?: () => void;
  className?: string;
}

export const ErrorState: React.FC<ErrorStateProps> = ({
  title = 'Không thể tải dữ liệu',
  message = 'Đã có lỗi xảy ra trong quá trình xử lý yêu cầu. Vui lòng kiểm tra lại kết nối mạng hoặc thử lại.',
  onRetry,
  className,
}) => {
  return (
    <div
      role="alert"
      className={clsx(
        'flex flex-col items-center justify-center p-8 text-center rounded-xl border border-red-200 bg-red-50/40',
        className
      )}
    >
      <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center text-red-600 mb-3">
        <AlertCircle className="w-6 h-6" />
      </div>
      <h3 className="text-base font-semibold text-red-900 tracking-tight">{title}</h3>
      <p className="text-sm text-red-700/80 mt-1 max-w-sm">{message}</p>
      {onRetry && (
        <div className="mt-4">
          <Button
            variant="outline"
            size="sm"
            onClick={onRetry}
            leftIcon={<RefreshCw className="w-3.5 h-3.5" />}
            className="border-red-300 text-red-800 hover:bg-red-50"
          >
            Thử lại
          </Button>
        </div>
      )}
    </div>
  );
};
