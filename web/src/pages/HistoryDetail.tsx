import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { format } from 'date-fns';
import { 
  // Removed unused icons to avoid linter warnings
  Calendar, 
  Loader2, 
  ChevronLeft,
  Share2
} from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Separator } from '@/components/ui/separator';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';

import { getExerciseById } from '@/lib/apiClient';
import { formatTime, formatDistance } from '@/lib/utils';

export function HistoryDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [isSharing, setIsSharing] = useState(false);
  
  const { 
    data: workout, 
    isLoading, 
    error 
  } = useQuery<ExerciseResponse, Error>({
    queryKey: ['workout', id],
    queryFn: () => getExerciseById(id as string),
    enabled: !!id,
  });

  // Share workout to social media or copy to clipboard
  const shareWorkout = async () => {
    if (!workout) return;
    
    setIsSharing(true);
    
    // Determine exercise type helpers
    const typeLower = workout.exercise_type.toLowerCase();
    const isRunning = typeLower.includes('run');

    try {
      const shareText = `I completed ${isRunning ?
        `a ${formatDistance(workout.distance ?? 0)} run` :
        `${workout.reps ?? 0} ${workout.exercise_type.toLowerCase()}s`} with a form score of ${(workout.grade ?? 0)}% using PT Champion!`;
      
      if (navigator.share) {
        await navigator.share({
          title: 'PT Champion Workout',
          text: shareText,
          url: window.location.href,
        });
      } else {
        await navigator.clipboard.writeText(shareText);
        // Ideally use a toast component; fallback to alert
        alert('Results copied to clipboard!');
      }
    } catch (err) {
      console.error('Error sharing:', err);
    } finally {
      setIsSharing(false);
    }
  };
  
  if (isLoading) {
    return (
      <div className="flex min-h-[calc(100vh-200px)] items-center justify-center">
        <div className="text-center text-muted-foreground">
          <Loader2 className="mx-auto mb-2 size-8 animate-spin"/>
          <p className="text-lg">Loading workout details...</p>
        </div>
      </div>
    );
  }
  
  if (error) {
    return (
      <div className="space-y-6">
        <Button 
          variant="ghost" 
          className="flex items-center text-muted-foreground" 
          onClick={() => navigate('/history')}
        >
          <ChevronLeft className="mr-1 size-4" />
          Back to History
        </Button>
        
        <Alert variant="destructive">
          <AlertTitle>Error</AlertTitle>
          <AlertDescription>
            {error instanceof Error ? error.message : 'Failed to load workout details'}
          </AlertDescription>
        </Alert>
      </div>
    );
  }
  
  if (!workout) {
    return (
      <div className="space-y-6">
        <Button 
          variant="ghost" 
          className="flex items-center text-muted-foreground" 
          onClick={() => navigate('/history')}
        >
          <ChevronLeft className="mr-1 size-4" />
          Back to History
        </Button>
        
        <Card>
          <CardHeader>
            <CardTitle>Workout Not Found</CardTitle>
            <CardDescription>
              The workout you are looking for could not be found.
            </CardDescription>
          </CardHeader>
          <CardFooter>
            <Button onClick={() => navigate('/history')}>Go Back to History</Button>
          </CardFooter>
        </Card>
      </div>
    );
  }

  // Format the exercise date
  const exerciseDate = new Date(workout.created_at);
  const formattedDate = format(exerciseDate, 'PPPP');
  const formattedTime = format(exerciseDate, 'p');
  
  // Helpers for UI rendering
  const typeLower = workout.exercise_type.toLowerCase();
  const isRunning = typeLower.includes('run');
  const isPushup = typeLower.includes('push');
  const isSitup = typeLower.includes('sit');
  const isPullup = typeLower.includes('pull');

  const prettyExerciseName = isRunning ? 'Running' : isPushup ? 'Push-ups' : isSitup ? 'Sit-ups' : isPullup ? 'Pull-ups' : workout.exercise_type;

  const mainMetricLabel = isRunning ? 'Distance' : 'Repetitions';
  const mainMetricValue = isRunning ? formatDistance(workout.distance ?? 0) : (workout.reps ?? 0);

  const durationSeconds = workout.time_in_seconds ?? 0;
  const formScore = workout.grade ?? 0;

  return (
    <div className="space-y-6">
      <Button 
        variant="ghost" 
        className="flex items-center text-muted-foreground" 
        onClick={() => navigate('/history')}
      >
        <ChevronLeft className="mr-1 size-4" />
        Back to History
      </Button>
      
      <div className="flex items-center justify-between">
        <h1 className="font-heading text-2xl tracking-wide">Workout Details</h1>
        <Button 
          variant="outline" 
          size="sm" 
          onClick={shareWorkout}
          disabled={isSharing}
        >
          <Share2 className="mr-2 size-4" />
          {isSharing ? 'Sharing...' : 'Share'}
        </Button>
      </div>
      
      <Card className="bg-cream">
        <CardHeader className="rounded-t-lg bg-deep-ops text-cream">
          <CardTitle className="font-heading text-xl">
            {prettyExerciseName}
          </CardTitle>
          <CardDescription className="flex items-center text-army-tan">
            <Calendar className="mr-1 size-4" />
            {formattedDate} at {formattedTime}
          </CardDescription>
        </CardHeader>
        
        <CardContent className="space-y-6 p-6">
          <div className="grid grid-cols-2 gap-6">
            <div className="space-y-2">
              <div className="text-sm font-medium text-muted-foreground">
                {mainMetricLabel}
              </div>
              <div className="flex items-baseline">
                <span className="font-mono text-3xl text-brass-gold">
                  {mainMetricValue}
                </span>
                <span className="ml-1 text-sm text-muted-foreground">
                  {isRunning ? '' : 'reps'}
                </span>
              </div>
            </div>
            
            <div className="space-y-2">
              <div className="text-sm font-medium text-muted-foreground">Duration</div>
              <div className="flex items-baseline">
                <span className="font-mono text-3xl text-brass-gold">
                  {formatTime(durationSeconds)}
                </span>
              </div>
            </div>
          </div>
          
          <Separator />
          
          <div className="space-y-2">
            <div className="flex items-baseline justify-between">
              <div className="text-sm font-medium text-muted-foreground">Form Score</div>
              <div className="font-mono text-sm">{formScore}%</div>
            </div>
            <Progress value={formScore} className="h-2" />
          </div>
          
          <div className="space-y-3">
            <div className="text-sm font-medium text-muted-foreground">Performance Grade</div>
            <div className="rounded-lg bg-white/50 p-4 text-center">
              <div className="inline-flex size-16 items-center justify-center rounded-full bg-brass-gold font-heading text-4xl text-white">
                {formScore >= 90 ? 'A' : 
                 formScore >= 80 ? 'B' : 
                 formScore >= 70 ? 'C' : 
                 formScore >= 60 ? 'D' : 'F'}
              </div>
              <div className="mt-2 text-sm text-muted-foreground">
                {formScore >= 90 ? 'Excellent Form' : 
                 formScore >= 80 ? 'Good Form' : 
                 formScore >= 70 ? 'Acceptable Form' : 
                 formScore >= 60 ? 'Needs Improvement' : 'Poor Form'}
              </div>
            </div>
          </div>
          
          <div className="bg-muted/30 rounded-lg p-4">
            <h3 className="mb-2 font-semibold text-sm">Device Information</h3>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-muted-foreground">Platform:</span>
                <span className="ml-2">Web</span>
              </div>
              <div>
                <span className="text-muted-foreground">Session ID:</span>
                <span className="ml-2 font-mono text-xs">{workout.id.toString().substring(0, 8)}</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
} 