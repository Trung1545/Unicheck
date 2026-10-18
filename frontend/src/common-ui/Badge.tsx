import React from 'react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export type BadgeVariant =
  | 'present'
  | 'late'
  | 'absent'
  | 'excused'
  | 'active'
  | 'inactive'
  | 'blocked'
  | 'pending'
  | 'primary'
  | 'neutral'
  | 'info';

export type BadgeSize = 'sm' | 'md';

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: BadgeVariant;
  size?: BadgeSize;
  hasDot?: boolean;
}

export const Badge: React.FC<BadgeProps> = ({
  children,
  variant = 'neutral',
  size = 'md',
  hasDot = true,
  className,
  ...props
}) => {
  const baseStyles =
    'inline-flex items-center font-semibold rounded-full border tracking-wide select-none transition-colors';

  const sizeStyles: Record<BadgeSize, string> = {
    sm: 'text-[11px] px-2 py-0.5 gap-1 leading-tight',
    md: 'text-xs px-2.5 py-1 gap-1.5 leading-tight',
  };

  const variantStyles: Record<BadgeVariant, { bg: string; text: string; border: string; dot: string }> = {
    // Attendance specific tokens from Stitch DESIGN.md
    present: {
      bg: 'bg-emerald-50',
      text: 'text-emerald-800',
      border: 'border-emerald-200',
      dot: 'bg-emerald-500',
    },
    late: {
      bg: 'bg-amber-50',
      text: 'text-amber-800',
      border: 'border-amber-200',
      dot: 'bg-amber-500',
    },
    absent: {
      bg: 'bg-red-50',
      text: 'text-red-800',
      border: 'border-red-200',
      dot: 'bg-red-500',
    },
    excused: {
      bg: 'bg-blue-50',
      text: 'text-blue-800',
      border: 'border-blue-200',
      dot: 'bg-blue-500',
    },
    // User / System status
    active: {
      bg: 'bg-emerald-50',
      text: 'text-emerald-700',
      border: 'border-emerald-200',
      dot: 'bg-emerald-500',
    },
    inactive: {
      bg: 'bg-slate-100',
      text: 'text-slate-600',
      border: 'border-slate-200',
      dot: 'bg-slate-400',
    },
    blocked: {
      bg: 'bg-red-50',
      text: 'text-red-700',
      border: 'border-red-200',
      dot: 'bg-red-500',
    },
    pending: {
      bg: 'bg-amber-50',
      text: 'text-amber-700',
      border: 'border-amber-200',
      dot: 'bg-amber-500',
    },
    primary: {
      bg: 'bg-primary-50',
      text: 'text-primary-800',
      border: 'border-primary-200',
      dot: 'bg-primary-600',
    },
    neutral: {
      bg: 'bg-slate-50',
      text: 'text-slate-700',
      border: 'border-slate-200',
      dot: 'bg-slate-400',
    },
    info: {
      bg: 'bg-cyan-50',
      text: 'text-cyan-800',
      border: 'border-cyan-200',
      dot: 'bg-cyan-500',
    },
  };

  const currentVariant = variantStyles[variant];

  return (
    <span
      className={twMerge(
        clsx(
          baseStyles,
          sizeStyles[size],
          currentVariant.bg,
          currentVariant.text,
          currentVariant.border,
          className
        )
      )}
      {...props}
    >
      {hasDot && (
        <span
          className={clsx(
            'rounded-full shrink-0',
            size === 'sm' ? 'w-1.5 h-1.5' : 'w-2 h-2',
            currentVariant.dot
          )}
          aria-hidden="true"
        />
      )}
      <span>{children}</span>
    </span>
  );
};
