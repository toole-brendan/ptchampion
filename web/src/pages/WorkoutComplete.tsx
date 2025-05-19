import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Button } from "@/components/ui/button";
import { ArrowLeft, Share2, Clipboard, Check, Trash2 } from 'lucide-react';
import { ExerciseResult } from '@/viewmodels/TrackerViewModel';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { useToast } from '@/components/ui/use-toast';
import { 
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

import WorkoutSummary from '@/components/WorkoutSummary';
import { deleteExercise } from '@/lib/apiClient';
import { buildShareText } from '@/lib/share';

const WorkoutComplete: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { toast } = useToast();
  
  const [result, setResult] = useState<ExerciseResult | null>(null);
  const [shareText, setShareText] = useState<string>('');
  const [isSharing, setIsSharing] = useState(false);
  const [copied, setCopied] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [canUseShareApi, setCanUseShareApi] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  
  // Check if Web Share API is available
  useEffect(() => {
    setCanUseShareApi(typeof navigator.share === 'function');
  }, []);
  
  // Extract result from location state
  useEffect(() => {
    const resultData = location.state as ExerciseResult;
    if (resultData) {
      setResult(resultData);
      // Build share text
      if (resultData.exerciseType) {
        setShareText(buildShareText(resultData));
      }
    } else {
      // If no result data, redirect to exercises page
      navigate('/exercises', { replace: true });
    }
  }, [location.state, navigate]);

  // Reset copied state when navigating away
  useEffect(() => {
    let timeout: NodeJS.Timeout;
    if (copied) {
      timeout = setTimeout(() => {
        setCopied(false);
      }, 3000);
    }
    return () => clearTimeout(timeout);
  }, [copied]);

  // Share workout to social media or copy to clipboard
  const handleShare = async () => {
    if (!shareText) return;
    
    setIsSharing(true);
    
    try {
      if (canUseShareApi) {
        // Use Web Share API if available
        await navigator.share({
          title: 'PT Champion Workout',
          text: shareText,
          url: window.location.href,
        });
      } else {
        // Fall back to clipboard copy
        await navigator.clipboard.writeText(shareText);
        setCopied(true);
        toast({
          title: "Copied to clipboard",
          description: "Workout details copied to clipboard",
        });
      }
    } catch (err) {
      console.error('Error sharing:', err);
      toast({
        title: "Sharing failed",
        description: "Could not share your workout",
        variant: "destructive",
      });
    } finally {
      setIsSharing(false);
    }
  };

  // Handle discard/delete workout
  const handleDiscard = async () => {
    if (!result) return;
    
    setIsDeleting(true);
    setDialogOpen(false);
    
    try {
      // If saved and has an ID, call delete API
      if (result.saved && result.id) {
        await deleteExercise(result.id);
        toast({
          title: "Workout discarded",
          description: "Your workout has been deleted",
        });
      }
      
      // Navigate back to exercises page
      navigate('/exercises');
    } catch (err) {
      console.error('Error discarding workout:', err);
      toast({
        title: "Error discarding workout",
        description: "Could not delete workout. Please try again.",
        variant: "destructive",
      });
      setIsDeleting(false);
    }
  };

  if (!result) {
    return null; // Return early while redirecting
  }



  return (
    <div className="container mx-auto max-w-lg px-4 py-12">
      <div className="mb-8 flex items-center justify-between">
        <Button variant="outline" onClick={() => navigate('/exercises')}>
          <ArrowLeft className="mr-2 size-4" /> Back to Exercises
        </Button>
      </div>

      {/* Display notification if workout not saved yet */}
      {!result.saved && (
        <Alert className="mb-6 border-amber-200 bg-amber-50 text-amber-800">
          <AlertDescription>
            This workout hasn't been saved yet. It will sync automatically when you go back online.
          </AlertDescription>
        </Alert>
      )}

      {/* Workout Summary Card */}
      <WorkoutSummary
        exerciseType={result.exerciseType}
        date={result.date}
        repCount={result.repCount}
        distance={result.distance}
        duration={result.duration}
        pace={result.pace}
        formScore={result.formScore}
        grade={result.grade}
        saved={result.saved}
      />

      {/* Action Buttons */}
      <div className="mt-6 space-y-3">
        <Button className="w-full" onClick={() => navigate('/dashboard')}>
          Done
        </Button>
        
        <Button 
          variant="outline" 
          className="w-full" 
          onClick={handleShare}
          disabled={isSharing}
        >
          {copied ? (
            <>
              <Check className="mr-2 size-4" />
              Copied to Clipboard
            </>
          ) : (
            <>
              {canUseShareApi ? (
                <Share2 className="mr-2 size-4" />
              ) : (
                <Clipboard className="mr-2 size-4" />
              )}
              {isSharing ? 'Sharing...' : 'Share Workout'}
            </>
          )}
        </Button>
        
        {/* Discard Button with Confirmation Dialog */}
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger asChild>
            <Button 
              variant="ghost" 
              className="w-full text-destructive hover:bg-destructive/10 hover:text-destructive/90"
              disabled={isDeleting}
            >
              <Trash2 className="mr-2 size-4" />
              {isDeleting ? 'Discarding...' : 'Discard Workout'}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Are you sure?</DialogTitle>
              <DialogDescription>
                This will permanently delete this workout record. This action cannot be undone.
              </DialogDescription>
            </DialogHeader>
            <DialogFooter>
              <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
              <Button 
                onClick={handleDiscard}
                variant="destructive"
              >
                Delete
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </div>
  );
};

export default WorkoutComplete; 