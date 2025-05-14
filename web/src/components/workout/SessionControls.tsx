import React from 'react';
import { Button } from "@/components/ui/button";
import { Play, Pause, RotateCcw, Octagon, Loader2, Maximize, Minimize, FlipHorizontal } from 'lucide-react';
import { SessionStatus } from '@/viewmodels/TrackerViewModel';

export interface SessionControlsProps {
  status: SessionStatus;
  isModelLoading: boolean;
  disabled: boolean;
  repCount: number;
  isSubmitting?: boolean;
  showFlip?: boolean;
  onFlipCamera?: () => void;
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
  showFlip = false,
  onFlipCamera,
  onStartPause,
  onReset,
  onFinish
}) => {
  const isActive = status === SessionStatus.ACTIVE;
  const isFinished = status === SessionStatus.COMPLETED;
  const canFinish = repCount > 0 && !isActive && !isFinished;
  const [isFullscreen, setIsFullscreen] = React.useState(false);
  
  // Toggle fullscreen mode
  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      // Enter fullscreen
      const videoContainer = document.querySelector('.camera-container') as HTMLElement;
      if (videoContainer) {
        videoContainer.requestFullscreen().then(() => {
          setIsFullscreen(true);
        }).catch(err => {
          console.error(`Error attempting to enable fullscreen: ${err.message}`);
        });
      }
    } else {
      // Exit fullscreen
      document.exitFullscreen().then(() => {
        setIsFullscreen(false);
      }).catch(err => {
        console.error(`Error attempting to exit fullscreen: ${err.message}`);
      });
    }
  };

  // Listen for fullscreen change events
  React.useEffect(() => {
    const handleFullscreenChange = () => {
      setIsFullscreen(!!document.fullscreenElement);
    };
    
    document.addEventListener('fullscreenchange', handleFullscreenChange);
    return () => {
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
    };
  }, []);
  
  return (
    <>
      {/* Camera controls in top right corner */}
      <div className="absolute top-3 right-3 z-40 flex gap-2">
        {/* Fullscreen toggle button */}
        <Button
          size="sm"
          variant="secondary"
          className="flex size-10 items-center justify-center rounded-full bg-black/50 p-0 hover:bg-black/70"
          onClick={toggleFullscreen}
        >
          {isFullscreen ? <Minimize className="size-5" /> : <Maximize className="size-5" />}
        </Button>
        
        {/* Flip camera button (only on mobile) */}
        {showFlip && (
          <Button
            size="sm"
            variant="secondary"
            className="flex size-10 items-center justify-center rounded-full bg-black/50 p-0 hover:bg-black/70"
            onClick={onFlipCamera}
            disabled={disabled || isModelLoading}
          >
            <FlipHorizontal className="size-5" />
          </Button>
        )}
      </div>

      {/* Bottom controls */}
      <div className="fixed bottom-5 left-1/2 z-30 flex -translate-x-1/2 items-center gap-3 rounded-xl bg-black/50 px-4 py-2 shadow-lg backdrop-blur-sm">
        {!isFinished ? (
          <>
            {/* Start/Pause button */}
            <Button 
              size="lg" 
              variant="default"
              className="flex size-14 items-center justify-center rounded-full p-0"
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
              className="flex size-14 items-center justify-center rounded-full p-0" 
              onClick={onReset} 
              disabled={isActive || isFinished || disabled}
            >
              <RotateCcw className="size-6" />
            </Button>
            
            {/* Finish button */}
            <Button 
              size="lg" 
              variant="destructive"
              className="flex size-14 items-center justify-center rounded-full p-0" 
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
    </>
  );
};

export default SessionControls; 