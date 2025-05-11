import React from 'react';
import { cn } from '@/lib/utils';
import { LucideIcon } from 'lucide-react';

type MetricCardProps = {
  title: string;
  value: string | number;
  description?: string;
  icon?: LucideIcon;
  change?: number;
  unit?: string;
  trend?: 'up' | 'down' | 'neutral';
  className?: string;
  iconClassName?: string;
  valueClassName?: string;
  titleClassName?: string;
  descriptionClassName?: string;
  cornerElements?: React.ReactNode;
  onClick?: () => void;
}

export function MetricCard({ 
  title, 
  value, 
  description, 
  icon: Icon, 
  change, 
  unit,
  trend = 'neutral',
  className,
  iconClassName,
  valueClassName,
  titleClassName,
  descriptionClassName,
  cornerElements,
  onClick
}: MetricCardProps) {
  return (
    <div 
      className={cn(
        "relative h-full bg-card-background overflow-hidden rounded-card p-content shadow-medium", 
        onClick && "cursor-pointer",
        className
      )}
      onClick={onClick}
    >
      {cornerElements}
      
      <div className="flex flex-row items-center justify-between space-y-0 pb-2">
        <div className={cn("text-xs font-semibold uppercase tracking-wider text-tactical-gray", titleClassName)}>
          {title}
        </div>
        {Icon && <Icon className={cn("size-5 text-brass-gold", iconClassName)} />}
      </div>
      
      <div className="flex flex-col justify-center">
        <div className="flex items-baseline">
          <div className={cn("font-heading text-heading3 text-command-black", valueClassName)}>
            {value}
          </div>
          {unit && (
            <span className="ml-1 font-semibold text-sm text-tactical-gray">{unit}</span>
          )}
        </div>
        
        {description && (
          <p className={cn("mt-1 text-xs text-tactical-gray", descriptionClassName)}>
            {description}
          </p>
        )}
        
        {change !== undefined && (
          <div className={cn(
            "mt-2 flex items-center text-xs font-semibold",
            trend === 'up' && "text-success",
            trend === 'down' && "text-error"
          )}>
            {trend === 'up' && <span className="mr-1">↑</span>}
            {trend === 'down' && <span className="mr-1">↓</span>}
            <span>
              {change > 0 ? '+' : ''}{change}% from last period
            </span>
          </div>
        )}
      </div>
    </div>
  );
} 