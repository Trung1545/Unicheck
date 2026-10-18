import React from 'react';
import { RotateCcw } from 'lucide-react';
import { clsx } from 'clsx';
import { Button } from './Button';

export interface FilterBarProps {
  children?: React.ReactNode;
  onReset?: () => void;
  hasActiveFilters?: boolean;
  className?: string;
}

export const FilterBar: React.FC<FilterBarProps> = ({
  children,
  onReset,
  hasActiveFilters = false,
  className,
}) => {
  return (
    <div
      className={clsx(
        'p-3.5 lg:p-4 bg-white rounded-xl border border-slate-200/80 shadow-sm flex flex-col sm:flex-row flex-wrap items-stretch sm:items-center justify-between gap-3',
        className
      )}
    >
      <div className="flex flex-1 flex-col sm:flex-row flex-wrap items-stretch sm:items-center gap-3">
        {children}
      </div>

      {onReset && hasActiveFilters && (
        <Button
          variant="ghost"
          size="sm"
          onClick={onReset}
          leftIcon={<RotateCcw className="w-3.5 h-3.5" />}
          className="text-slate-500 hover:text-slate-800 shrink-0 self-end sm:self-auto"
        >
          Đặt lại bộ lọc
        </Button>
      )}
    </div>
  );
};
