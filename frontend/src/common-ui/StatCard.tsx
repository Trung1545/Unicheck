import React from 'react';
import { TrendingUp, TrendingDown } from 'lucide-react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export interface StatCardTrend {
  value: string;
  isPositive?: boolean;
  label?: string;
}

export interface StatCardSubMetric {
  label: string;
  value: string | number;
}

export interface StatCardProps extends React.HTMLAttributes<HTMLDivElement> {
  title: string;
  value: string | number;
  icon?: React.ReactNode;
  iconBgColor?: string;
  iconColor?: string;
  trend?: StatCardTrend;
  progressPercent?: number;
  subMetrics?: StatCardSubMetric[];
  description?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  icon,
  iconBgColor = 'bg-primary-50',
  iconColor = 'text-primary-700',
  trend,
  progressPercent,
  subMetrics,
  description,
  className,
  ...props
}) => {
  return (
    <div
      className={twMerge(
        clsx(
          'bg-white p-5 lg:p-6 rounded-xl border border-slate-200/80 shadow-sm flex flex-col justify-between gap-4 hover:shadow-md transition-shadow',
          className
        )
      )}
      {...props}
    >
      {/* Top Section: Title & Icon */}
      <div className="flex items-start justify-between gap-2">
        <div className="space-y-1">
          <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
            {title}
          </span>
          <div className="text-2xl lg:text-3xl font-bold tracking-tight text-slate-900 data-tabular">
            {value}
          </div>
          {description && <p className="text-xs text-slate-400">{description}</p>}
        </div>

        {icon && (
          <div
            className={clsx(
              'w-10 h-10 rounded-lg flex items-center justify-center shrink-0',
              iconBgColor,
              iconColor
            )}
          >
            {icon}
          </div>
        )}
      </div>

      {/* Middle: Trend Indicator */}
      {trend && (
        <div className="flex items-center gap-1.5 text-xs font-semibold">
          {trend.isPositive !== undefined && (
            <span
              className={clsx(
                'inline-flex items-center gap-0.5',
                trend.isPositive ? 'text-emerald-600' : 'text-red-600'
              )}
            >
              {trend.isPositive ? (
                <TrendingUp className="w-3.5 h-3.5" />
              ) : (
                <TrendingDown className="w-3.5 h-3.5" />
              )}
              <span>{trend.value}</span>
            </span>
          )}
          {trend.label && <span className="text-slate-400 font-normal">{trend.label}</span>}
        </div>
      )}

      {/* Progress Bar (if provided) */}
      {typeof progressPercent === 'number' && (
        <div className="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
          <div
            className="bg-primary-700 h-full rounded-full transition-all duration-500"
            style={{ width: `${Math.min(100, Math.max(0, progressPercent))}%` }}
          />
        </div>
      )}

      {/* Bottom Sub-metrics */}
      {subMetrics && subMetrics.length > 0 && (
        <div className="flex items-center justify-between pt-1 border-t border-slate-100 text-[11px] text-slate-500 font-medium">
          {subMetrics.map((sm, idx) => (
            <span key={idx}>
              {sm.label}: <strong className="text-slate-700 data-tabular">{sm.value}</strong>
            </span>
          ))}
        </div>
      )}
    </div>
  );
};
