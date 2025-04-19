import React from 'react';
import { cn } from '@/lib/utils';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
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
  onClick
}: MetricCardProps) {
  return (
    <Card 
      className={cn(
        "transition-shadow hover:shadow-md bg-cream", 
        onClick && "cursor-pointer",
        className
      )}
      onClick={onClick}
    >
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium text-tactical-gray">{title}</CardTitle>
        {Icon && <Icon className="size-4 text-tactical-gray" />}
      </CardHeader>
      <CardContent className="p-6 pt-2">
        <div className="flex items-baseline">
          <div className="font-mono text-2xl font-bold text-brass-gold">
            {value}
          </div>
          {unit && (
            <span className="ml-1 text-sm text-tactical-gray">{unit}</span>
          )}
        </div>
        
        {description && (
          <p className="mt-1 text-xs text-tactical-gray">
            {description}
          </p>
        )}
        
        {change !== undefined && (
          <div className={cn(
            "flex items-center mt-2 text-xs",
            trend === 'up' && "text-green-600",
            trend === 'down' && "text-red-600"
          )}>
            {trend === 'up' && <span className="mr-1">↑</span>}
            {trend === 'down' && <span className="mr-1">↓</span>}
            <span>
              {change > 0 ? '+' : ''}{change}% from last period
            </span>
          </div>
        )}
      </CardContent>
    </Card>
  );
} 