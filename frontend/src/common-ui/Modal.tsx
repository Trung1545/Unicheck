import React, { useEffect, useRef } from 'react';
import { X, AlertTriangle } from 'lucide-react';
import { clsx } from 'clsx';
import { Button } from './Button';

export type ModalSize = 'sm' | 'md' | 'lg' | 'xl';

export interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children?: React.ReactNode;
  size?: ModalSize;
  isDanger?: boolean;
  confirmText?: string;
  cancelText?: string;
  onConfirm?: () => void;
  isLoading?: boolean;
  hideFooter?: boolean;
}

export const Modal: React.FC<ModalProps> = ({
  isOpen,
  onClose,
  title,
  description,
  children,
  size = 'md',
  isDanger = false,
  confirmText,
  cancelText = 'Hủy',
  onConfirm,
  isLoading = false,
  hideFooter = false,
}) => {
  const modalRef = useRef<HTMLDivElement>(null);

  // Close on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen && !isLoading) {
        onClose();
      }
    };
    if (isOpen) {
      window.addEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'hidden';
    }
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, isLoading, onClose]);

  if (!isOpen) return null;

  const sizeClasses: Record<ModalSize, string> = {
    sm: 'max-w-sm',
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-2xl',
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 overflow-y-auto"
    >
      {/* Backdrop overlay */}
      <div
        className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm transition-opacity"
        onClick={() => !isLoading && onClose()}
        aria-hidden="true"
      />

      {/* Modal Dialog Card */}
      <div
        ref={modalRef}
        className={clsx(
          'relative w-full bg-white rounded-2xl border border-slate-200/90 shadow-2xl p-6 transition-all z-10 my-8',
          sizeClasses[size]
        )}
      >
        {/* Header */}
        <div className="flex items-start justify-between gap-3 mb-4">
          <div className="flex items-start gap-3">
            {isDanger && (
              <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center text-red-600 shrink-0">
                <AlertTriangle className="w-5 h-5" />
              </div>
            )}
            <div className="space-y-1 text-left">
              <h3 id="modal-title" className="text-lg font-bold text-slate-900 tracking-tight">
                {title}
              </h3>
              {description && <p className="text-xs text-slate-500">{description}</p>}
            </div>
          </div>

          <button
            type="button"
            disabled={isLoading}
            onClick={onClose}
            aria-label="Đóng hộp thoại"
            className="p-1 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content Body */}
        {children && <div className="text-sm text-slate-600 mb-6 text-left">{children}</div>}

        {/* Action Buttons */}
        {!hideFooter && (
          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
            <Button
              variant="outline"
              size="md"
              disabled={isLoading}
              onClick={onClose}
            >
              {cancelText}
            </Button>
            {onConfirm && (
              <Button
                variant={isDanger ? 'danger' : 'primary'}
                size="md"
                isLoading={isLoading}
                onClick={onConfirm}
              >
                {confirmText || (isDanger ? 'Xóa dữ liệu' : 'Xác nhận')}
              </Button>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
