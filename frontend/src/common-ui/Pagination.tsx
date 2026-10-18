import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { clsx } from 'clsx';

export interface PaginationProps {
  currentPage: number;
  totalPages: number;
  totalElements?: number;
  pageSize?: number;
  onPageChange: (page: number) => void;
  className?: string;
}

export const Pagination: React.FC<PaginationProps> = ({
  currentPage,
  totalPages,
  totalElements,
  pageSize,
  onPageChange,
  className,
}) => {
  if (totalPages <= 1) return null;

  // Calculate visible page range with ellipsis
  const getPageNumbers = () => {
    const delta = 1;
    const range: number[] = [];
    for (
      let i = Math.max(2, currentPage - delta);
      i <= Math.min(totalPages - 1, currentPage + delta);
      i++
    ) {
      range.push(i);
    }

    if (currentPage - delta > 2) {
      range.unshift(-1);
    }
    if (currentPage + delta < totalPages - 1) {
      range.push(-2);
    }

    range.unshift(1);
    if (totalPages > 1) {
      range.push(totalPages);
    }

    return range;
  };

  const pages = getPageNumbers();

  const startRecord = pageSize ? (currentPage - 1) * pageSize + 1 : undefined;
  const endRecord = pageSize && totalElements ? Math.min(currentPage * pageSize, totalElements) : undefined;

  return (
    <div className={clsx('flex flex-col sm:flex-row items-center justify-between gap-3 px-2 py-3', className)}>
      {/* Informational counter */}
      {totalElements !== undefined && (
        <div className="text-xs text-slate-500 font-medium">
          Hiển thị{' '}
          {startRecord && endRecord ? (
            <span className="font-semibold text-slate-700 data-tabular">
              {startRecord} - {endRecord}
            </span>
          ) : null}{' '}
          trên tổng số <span className="font-semibold text-slate-700 data-tabular">{totalElements}</span> bản ghi
        </div>
      )}

      {/* Navigation Buttons */}
      <nav className="inline-flex items-center gap-1 rounded-lg" aria-label="Pagination Navigation">
        <button
          type="button"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage <= 1}
          aria-label="Trang trước"
          className="inline-flex items-center justify-center w-8 h-8 rounded-lg text-slate-600 hover:bg-slate-100 disabled:opacity-40 disabled:cursor-not-allowed transition"
        >
          <ChevronLeft className="w-4 h-4" />
        </button>

        {pages.map((p, idx) => {
          if (p === -1 || p === -2) {
            return (
              <span key={`ellipsis-${idx}`} className="w-8 h-8 flex items-center justify-center text-slate-400 select-none">
                …
              </span>
            );
          }

          const isActive = p === currentPage;
          return (
            <button
              key={p}
              type="button"
              onClick={() => onPageChange(p)}
              aria-current={isActive ? 'page' : undefined}
              className={clsx(
                'w-8 h-8 text-xs font-semibold rounded-lg transition-all data-tabular flex items-center justify-center select-none',
                isActive
                  ? 'bg-primary-700 text-white shadow-sm'
                  : 'text-slate-700 hover:bg-slate-100'
              )}
            >
              {p}
            </button>
          );
        })}

        <button
          type="button"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage >= totalPages}
          aria-label="Trang tiếp theo"
          className="inline-flex items-center justify-center w-8 h-8 rounded-lg text-slate-600 hover:bg-slate-100 disabled:opacity-40 disabled:cursor-not-allowed transition"
        >
          <ChevronRight className="w-4 h-4" />
        </button>
      </nav>
    </div>
  );
};
