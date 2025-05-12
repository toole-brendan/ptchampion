import { formatDistance, formatTime } from '@/lib/utils';
import { WorkoutSummaryProps } from '@/components/WorkoutSummary';
import { useToast } from '@/components/ui/use-toast';

/**
 * Builds a share text string from workout summary data
 */
export const buildShareText = (summary: WorkoutSummaryProps): string => {
  const { exerciseType, repCount, distance, duration, formScore, grade } = summary;
  
  const isRunning = exerciseType === 'RUNNING';
  const exerciseNames: Record<string, string> = {
    'PUSHUP': 'push-ups',
    'PULLUP': 'pull-ups',
    'SITUP': 'sit-ups',
    'RUNNING': 'running'
  };
  const exerciseName = exerciseNames[exerciseType] || exerciseType.toLowerCase();
  
  let shareText = '';
  
  if (isRunning) {
    shareText = `I completed a ${formatDistance(distance || 0)} run in ${formatTime(duration)}`;
  } else {
    shareText = `I completed ${repCount || 0} ${exerciseName}`;
  }
  
  // Add form score if available
  if (formScore !== undefined) {
    shareText += ` with a form score of ${formScore}%`;
  }
  
  // Add APFT score if available and it's not running
  if (!isRunning && grade !== undefined && typeof grade === 'number') {
    shareText += ` (APFT score: ${grade})`;
  }
  
  // Add app name
  shareText += ` using PT Champion!`;
  
  return shareText;
};

/**
 * Shares workout text using Web Share API if available, or falls back to clipboard
 */
export const shareWorkout = async (
  shareText: string, 
  setSuccess?: (value: boolean) => void, 
  setSharing?: (value: boolean) => void,
  setCopied?: (value: boolean) => void
): Promise<boolean> => {
  // If no hooks provided, create a default toast function (component needs to use useToast hooks)
  const toast = useToast().toast;
  
  try {
    if (setSharing) setSharing(true);
    
    if (navigator.share) {
      // Use Web Share API if available
      await navigator.share({
        title: 'PT Champion Workout',
        text: shareText,
        url: window.location.href,
      });
      if (setSuccess) setSuccess(true);
      return true;
    } else {
      // Fall back to clipboard copy
      await navigator.clipboard.writeText(shareText);
      if (setCopied) setCopied(true);
      toast({
        title: "Copied to clipboard",
        description: "Workout details copied to clipboard"
      });
      
      // Reset copied state after 3 seconds
      if (setCopied) {
        setTimeout(() => {
          setCopied(false);
        }, 3000);
      }
      
      if (setSuccess) setSuccess(true);
      return true;
    }
  } catch (err) {
    console.error('Error sharing:', err);
    toast({
      title: "Sharing failed",
      description: "Could not share your workout",
      variant: "destructive",
    });
    if (setSuccess) setSuccess(false);
    return false;
  } finally {
    if (setSharing) setSharing(false);
  }
}; 