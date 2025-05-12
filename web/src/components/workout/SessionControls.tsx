import React from 'react';
import { Button } from "@/components/ui/button";
import { Play, Pause, RotateCcw, Octagon, Loader2 } from 'lucide-react';
import { SessionStatus } from '@/viewmodels/TrackerViewModel';

export interface SessionControlsProps {
  status: SessionStatus;
  isModelLoading: boolean;
  disabled: boolean;
  repCount: number;
  isSubmitting?: boolean;
  onStartPause: () => void;
  onReset: () => void;
  onFinish: () => void;
}

const SessionControls: React.FC<SessionControlsProps> = ({
  status,
  isModelLoading,
  disabled,
  repCount,
  isSubmitting = false,
  onStartPause,
  onReset,
  onFinish
}) => {
  const isActive = status === SessionStatus.ACTIVE;
  const isFinished = status === SessionStatus.COMPLETED;
  const canFinish = repCount > 0 && !isActive && !isFinished;
  
  return (
    <div className="fixed bottom-5 left-1/2 -translate-x-1/2 z-30 flex items-center gap-3 px-4 py-2 bg-black/50 backdrop-blur-sm rounded-xl shadow-lg">
      {!isFinished ? (
        <>
          {/* Start/Pause button */}
          <Button 
            size="lg" 
            variant="default"
            className="rounded-full h-14 w-14 p-0 flex items-center justify-center"
            onClick={onStartPause} 
            disabled={isFinished || disabled || isModelLoading}
          >
            {isModelLoading ? 
              <Loader2 className="size-6 animate-spin" /> : 
              isActive ? 
                <Pause className="size-6" /> : 
                <Play className="size-6" />
            }
          </Button>
          
          {/* Reset button */}
          <Button 
            size="lg" 
            variant="secondary"
            className="rounded-full h-14 w-14 p-0 flex items-center justify-center" 
            onClick={onReset} 
            disabled={isActive || isFinished || disabled}
          >
            <RotateCcw className="size-6" />
          </Button>
          
          {/* Finish button */}
          <Button 
            size="lg" 
            variant="destructive"
            className="rounded-full h-14 w-14 p-0 flex items-center justify-center" 
            onClick={onFinish} 
            disabled={!canFinish || isSubmitting}
          >
            {isSubmitting ? 
              <Loader2 className="size-6 animate-spin" /> : 
              <Octagon className="size-6" />
            }
          </Button>
        </>
      ) : null}
    </div>
  );
};

export default SessionControls; 