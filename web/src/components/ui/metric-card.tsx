import React, { useEffect, useState, useRef } from 'react';
import { cn } from '@/lib/utils';
import { LucideIcon } from 'lucide-react';
import { Card } from './card';

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
  onClick?: () => void;
  index?: number;
  withCorners?: boolean;
  cornerStyle?: "always" | "hover" | "none";
}

// Simple hook for counting up numbers
const useCountUp = (endValue: number, duration: number = 1000) => {
  const [count, setCount] = useState(0);
  const countRef = useRef(0);
  const prevEndValue = useRef(endValue);

  useEffect(() => {
    // Reset count if end value changes significantly
    if (Math.abs(prevEndValue.current - endValue) > 5) {
      countRef.current = 0;
      setCount(0);
    }
    prevEndValue.current = endValue;

    if (endValue === 0) {
      setCount(0);
      return;
    }

    const startValue = countRef.current;
    const increment = endValue / (duration / 16);
    const startTime = performance.now();

    const animateCount = (currentTime: number) => {
      const elapsedTime = currentTime - startTime;
      if (elapsedTime >= duration) {
        countRef.current = endValue;
        setCount(endValue);
        return;
      }

      const progress = elapsedTime / duration;
      const easedProgress = 1 - Math.pow(1 - progress, 3); // Cubic ease-out
      const currentCount = Math.min(
        startValue + increment * easedProgress * (duration / 16),
        endValue
      );
      
      countRef.current = currentCount;
      setCount(Math.floor(currentCount));
      requestAnimationFrame(animateCount);
    };

    const animationId = requestAnimationFrame(animateCount);
    return () => cancelAnimationFrame(animationId);
  }, [endValue, duration]);

  return count;
};

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
  onClick,
  index = 0,
  withCorners = true,
  cornerStyle = "hover"
}: MetricCardProps) {
  // For number values, use the count-up animation
  const numericValue = typeof value === 'number' ? value : 0;
  const isNumeric = typeof value === 'number';
  const animatedValue = useCountUp(numericValue);
  const displayValue = isNumeric ? animatedValue : value;
  
  return (
    <Card 
      variant={onClick ? "interactive" : "default"}
      className={cn(
        "h-full overflow-hidden animate-slide-up",
        className
      )}
      onClick={onClick}
      style={{ animationDelay: `${index * 100}ms` }}
      tabIndex={onClick ? 0 : undefined}
      withCorners={withCorners}
      cornerStyle={cornerStyle}
    >
      <div className="p-content">
        <div className="flex flex-row items-center justify-between space-y-0 pb-2">
          <div className={cn("text-xs font-semibold uppercase tracking-wider text-olive-mist", titleClassName)}>
            {title}
          </div>
          {Icon && <Icon className={cn("size-5 text-brass-gold", iconClassName)} />}
        </div>
        
        <div className="flex flex-col justify-center">
          <div className="flex items-baseline">
            <div className={cn("font-heading text-heading3 text-command-black", valueClassName)}>
              {displayValue}
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
    </Card>
  );
} 