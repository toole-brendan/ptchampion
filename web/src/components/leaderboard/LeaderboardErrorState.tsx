import React from 'react';
import { cn } from '@/lib/utils';
import { WifiOff, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface LeaderboardErrorStateProps {
  message: string;
  onRetry: () => void;
  className?: string;
}

const LeaderboardErrorState: React.FC<LeaderboardErrorStateProps> = ({
  message,
  onRetry,
  className
}) => {
  return (
    <div className={cn(
      "flex flex-col items-center justify-center py-12 space-y-4",
      className
    )}>
      <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center">
        <WifiOff className="w-8 h-8 text-red-600" />
      </div>
      
      <h3 className="font-mono text-sm font-medium text-tactical-gray uppercase tracking-wide">
        Error Loading Rankings
      </h3>
      
      <p className="text-xs text-tactical-gray text-center max-w-xs uppercase tracking-wide">
        {message}
      </p>
      
      <Button 
        variant="default"
        onClick={onRetry}
        className="mt-4 bg-brass-gold hover:bg-brass-gold/90 text-deep-ops font-mono uppercase tracking-wide"
      >
        RETRY
      </Button>
    </div>
  );
};

export default LeaderboardErrorState; 