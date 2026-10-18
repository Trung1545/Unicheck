import React from 'react';
import { Search, X } from 'lucide-react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export interface SearchInputProps
  extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'onChange'> {
  value: string;
  onChange: (value: string) => void;
  onClear?: () => void;
}

export const SearchInput: React.FC<SearchInputProps> = ({
  value,
  onChange,
  onClear,
  placeholder = 'Tìm kiếm...',
  className,
  disabled,
  ...props
}) => {
  const handleClear = () => {
    onChange('');
    if (onClear) onClear();
  };

  return (
    <div className={twMerge(clsx('relative w-full max-w-sm', className))}>
      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
        <Search className="w-4 h-4" />
      </div>

      <input
        type="text"
        value={value}
        disabled={disabled}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className={clsx(
          'w-full h-10 pl-9 pr-8 bg-white border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400',
          'focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-500/15 transition-all shadow-sm',
          disabled && 'bg-slate-50 text-slate-400 cursor-not-allowed'
        )}
        {...props}
      />

      {value && !disabled && (
        <button
          type="button"
          onClick={handleClear}
          aria-label="Xóa nội dung tìm kiếm"
          className="absolute inset-y-0 right-0 pr-2.5 flex items-center text-slate-400 hover:text-slate-600 transition"
        >
          <X className="w-4 h-4" />
        </button>
      )}
    </div>
  );
};
