import React from 'react';
import { cn } from '@/lib/utils';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

interface PerformanceChange {
  type: 'improved' | 'declined' | 'maintained';
  positions?: number;
}

interface PerformanceIndicatorProps {
  change: PerformanceChange;
  className?: string;
}

const PerformanceIndicator: React.FC<PerformanceIndicatorProps> = ({ 
  change, 
  className 
}) => {
  const getIcon = () => {
    switch (change.type) {
      case 'improved':
        return TrendingUp;
      case 'declined':
        return TrendingDown;
      case 'maintained':
        return Minus;
      default:
        return Minus;
    }
  };

  const getColor = () => {
    switch (change.type) {
      case 'improved':
        return 'text-green-600';
      case 'declined':
        return 'text-red-600';
      case 'maintained':
        return 'text-tactical-gray';
      default:
        return 'text-tactical-gray';
    }
  };

  const Icon = getIcon();

  return (
    <div className={cn(
      "inline-flex items-center",
      getColor(),
      className
    )}>
      <Icon className="w-3 h-3" />
      {change.positions && (
        <span className="ml-1 text-xs font-mono">
          {change.positions}
        </span>
      )}
    </div>
  );
};

export default PerformanceIndicator; 