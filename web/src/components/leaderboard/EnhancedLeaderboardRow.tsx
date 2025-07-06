import React from 'react';
import { cn } from '@/lib/utils';
import { Trophy, Medal, MapPin } from 'lucide-react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import PersonalBestBadge from './PersonalBestBadge';
import PerformanceIndicator from './PerformanceIndicator';

interface LeaderboardEntry {
  rank: number;
  name: string;
  username: string;
  userId: string;
  score: number;
  formattedScore: string;
  avatar?: string | null;
  unit?: string;
  location?: string;
  isPersonalBest?: boolean;
  performanceChange?: {
    type: 'improved' | 'declined' | 'maintained';
    positions?: number;
  };
  displaySubtitle?: string;
}

interface EnhancedLeaderboardRowProps {
  entry: LeaderboardEntry;
  isCurrentUser: boolean;
  onClick?: () => void;
  className?: string;
}

const getInitials = (name: string) => {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase();
};

const EnhancedLeaderboardRow: React.FC<EnhancedLeaderboardRowProps> = React.memo(({
  entry,
  isCurrentUser,
  onClick,
  className
}) => {
  const { rank } = entry;

  // Medal colors and styling
  const medalColors = {
    1: { 
      bg: 'bg-yellow-100', 
      icon: 'text-yellow-600', 
      score: 'text-yellow-600',
      shadow: 'shadow-yellow-200'
    },
    2: { 
      bg: 'bg-gray-100', 
      icon: 'text-gray-500', 
      score: 'text-gray-500',
      shadow: 'shadow-gray-200'
    },
    3: { 
      bg: 'bg-amber-100', 
      icon: 'text-amber-700', 
      score: 'text-amber-700',
      shadow: 'shadow-amber-200'
    }
  };

  const colors = medalColors[rank as keyof typeof medalColors] || { 
    bg: 'bg-olive-mist/20', 
    icon: 'text-deep-ops', 
    score: 'text-brass-gold',
    shadow: 'shadow-olive-mist/20'
  };

  const getRankIcon = () => {
    if (rank === 1) return Trophy;
    if (rank <= 3) return Medal;
    return null;
  };

  const RankIcon = getRankIcon();

  return (
    <div 
      className={cn(
        "flex items-center space-x-4 p-4 transition-all duration-200",
        "hover:bg-gray-50 cursor-pointer",
        isCurrentUser && "bg-brass-gold/5 border-l-4 border-brass-gold",
        onClick && "active:scale-[0.99]",
        className
      )}
      onClick={onClick}
      role={onClick ? "button" : undefined}
      tabIndex={onClick ? 0 : undefined}
      onKeyDown={onClick ? (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onClick();
        }
      } : undefined}
    >
      {/* Rank badge */}
      <div className={cn(
        "w-11 h-11 rounded-full flex items-center justify-center flex-shrink-0",
        colors.bg,
        rank <= 3 && colors.shadow
      )}>
        {RankIcon ? (
          <RankIcon className={cn("w-5 h-5", colors.icon)} />
        ) : (
          <span className={cn("font-mono font-bold text-sm", colors.icon)}>
            {rank}
          </span>
        )}
      </div>

      {/* User info */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center space-x-2 mb-1">
          <Avatar className={cn(
            "w-8 h-8 border-2 border-brass-gold/20",
            rank <= 3 && "shadow-md shadow-brass-gold/20"
          )}>
            <AvatarImage src={entry.avatar || undefined} alt={entry.name} />
            <AvatarFallback className="bg-army-tan/20 text-xs font-medium text-tactical-gray">
              {getInitials(entry.name)}
            </AvatarFallback>
          </Avatar>
          
          <div className="flex-1 min-w-0">
            <div className="flex items-center space-x-2">
              <span className="font-semibold text-deep-ops truncate">
                {entry.name}
              </span>
              {entry.isPersonalBest && <PersonalBestBadge />}
              {entry.performanceChange && (
                <PerformanceIndicator change={entry.performanceChange} />
              )}
            </div>
            
            {(entry.unit || entry.location) && (
              <div className="flex items-center space-x-1 text-xs text-tactical-gray mt-1">
                {entry.unit && <span>{entry.unit}</span>}
                {entry.unit && entry.location && <span>•</span>}
                {entry.location && (
                  <div className="flex items-center space-x-1">
                    <MapPin className="w-3 h-3" />
                    <span>{entry.location}</span>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Score */}
      <div className="text-right flex-shrink-0">
        <div className={cn("text-xl font-bold tabular-nums", colors.score)}>
          {entry.formattedScore}
        </div>
        {entry.displaySubtitle && (
          <div className="text-xs text-tactical-gray">
            {entry.displaySubtitle}
          </div>
        )}
      </div>
    </div>
  );
});

EnhancedLeaderboardRow.displayName = 'EnhancedLeaderboardRow';

export default EnhancedLeaderboardRow; 