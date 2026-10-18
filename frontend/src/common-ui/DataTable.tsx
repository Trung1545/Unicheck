import React from 'react';
import { clsx } from 'clsx';
import { Skeleton } from './Skeleton';
import { EmptyState } from './EmptyState';
import { Pagination, PaginationProps } from './Pagination';

export interface ColumnDef<T> {
  key: string;
  header: string;
  render?: (item: T, index: number) => React.ReactNode;
  width?: string;
  align?: 'left' | 'center' | 'right';
  className?: string;
}

export interface DataTableProps<T> {
  columns: ColumnDef<T>[];
  data: T[];
  isLoading?: boolean;
  emptyTitle?: string;
  emptyDescription?: string;
  keyExtractor?: (item: T, index: number) => string | number;
  pagination?: PaginationProps;
  className?: string;
}

export function DataTable<T>({
  columns,
  data,
  isLoading = false,
  emptyTitle = 'Không tìm thấy dữ liệu',
  emptyDescription = 'Hiện chưa có dữ liệu phù hợp với điều kiện tìm kiếm hoặc hệ thống chưa ghi nhận bản ghi nào.',
  keyExtractor = (_, index) => index,
  pagination,
  className,
}: DataTableProps<T>) {
  const alignClass = (align?: 'left' | 'center' | 'right') => {
    switch (align) {
      case 'center':
        return 'text-center';
      case 'right':
        return 'text-right';
      default:
        return 'text-left';
    }
  };

  return (
    <div
      className={clsx(
        'w-full bg-white rounded-xl border border-slate-200/90 shadow-sm overflow-hidden flex flex-col',
        className
      )}
    >
      {/* Table container with responsive horizontal scrolling */}
      <div className="w-full overflow-x-auto">
        <table className="w-full text-left border-collapse min-w-[640px]">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200/90">
              {columns.map((col) => (
                <th
                  key={col.key}
                  scope="col"
                  style={col.width ? { width: col.width } : undefined}
                  className={clsx(
                    'py-3.5 px-4 text-xs font-semibold uppercase tracking-wider text-slate-600 select-none',
                    alignClass(col.align),
                    col.className
                  )}
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>

          <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
            {isLoading ? (
              // Skeleton rows when loading
              Array.from({ length: 5 }).map((_, rIdx) => (
                <tr key={`skeleton-row-${rIdx}`} className="animate-pulse">
                  {columns.map((col) => (
                    <td key={`skeleton-col-${col.key}`} className="py-3.5 px-4">
                      <Skeleton variant="text" className="h-4 max-w-[85%]" />
                    </td>
                  ))}
                </tr>
              ))
            ) : data.length > 0 ? (
              data.map((item, idx) => (
                <tr
                  key={keyExtractor(item, idx)}
                  className="hover:bg-slate-50/80 transition-colors group"
                >
                  {columns.map((col) => (
                    <td
                      key={`${col.key}-${idx}`}
                      className={clsx('py-3.5 px-4 align-middle', alignClass(col.align), col.className)}
                    >
                      {col.render
                        ? col.render(item, idx)
                        : (item as any)[col.key] !== undefined && (item as any)[col.key] !== null
                        ? String((item as any)[col.key])
                        : '—'}
                    </td>
                  ))}
                </tr>
              ))
            ) : null}
          </tbody>
        </table>
      </div>

      {/* Empty State */}
      {!isLoading && data.length === 0 && (
        <div className="p-8">
          <EmptyState title={emptyTitle} description={emptyDescription} />
        </div>
      )}

      {/* Optional Pagination Footer */}
      {pagination && !isLoading && data.length > 0 && (
        <div className="border-t border-slate-100 px-4 py-2 bg-slate-50/50">
          <Pagination {...pagination} />
        </div>
      )}
    </div>
  );
}
