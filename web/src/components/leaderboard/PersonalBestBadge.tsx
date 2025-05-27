import React from 'react';
import { cn } from '@/lib/utils';
import { Star } from 'lucide-react';

interface PersonalBestBadgeProps {
  className?: string;
}

const PersonalBestBadge: React.FC<PersonalBestBadgeProps> = ({ className }) => {
  return (
    <div className={cn(
      "inline-flex items-center space-x-1 px-2 py-1 rounded-full",
      "bg-brass-gold/20 text-brass-gold",
      "border border-brass-gold/30",
      className
    )}>
      <Star className="w-2 h-2 fill-current" />
      <span className="text-xs font-mono uppercase tracking-wide font-bold">
        PB
      </span>
    </div>
  );
};

export default PersonalBestBadge; 