import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { format } from 'date-fns';
import { 
  ArrowLeft, 
  Clock, 
  Dumbbell, 
  Award, 
  TrendingUp, 
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
  } = useQuery({
    queryKey: ['workout', id],
    queryFn: () => getExerciseById(id as string),
    enabled: !!id,
  });

  // Share workout to social media or copy to clipboard
  const shareWorkout = async () => {
    if (!workout) return;
    
    setIsSharing(true);
    
    try {
      const shareText = `I completed ${workout.exerciseType === 'RUNNING' ? 
        `a ${formatDistance(workout.count)} run` : 
        `${workout.count} ${workout.exerciseType.toLowerCase()}s`} with a form score of ${workout.formScore}% using PT Champion!`;
      
      if (navigator.share) {
        await navigator.share({
          title: 'PT Champion Workout',
          text: shareText,
          url: window.location.href,
        });
      } else {
        await navigator.clipboard.writeText(shareText);
        // Show temporary copied message
        // We would typically show a toast here
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
      <div className="flex justify-center items-center min-h-[calc(100vh-200px)]">
        <div className="text-center text-muted-foreground">
          <Loader2 className="h-8 w-8 animate-spin mx-auto mb-2"/>
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
          <ChevronLeft className="mr-1 h-4 w-4" />
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
          <ChevronLeft className="mr-1 h-4 w-4" />
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
  const exerciseDate = new Date(workout.date);
  const formattedDate = format(exerciseDate, 'PPPP');
  const formattedTime = format(exerciseDate, 'p');
  
  return (
    <div className="space-y-6">
      <Button 
        variant="ghost" 
        className="flex items-center text-muted-foreground" 
        onClick={() => navigate('/history')}
      >
        <ChevronLeft className="mr-1 h-4 w-4" />
        Back to History
      </Button>
      
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-heading tracking-wide">Workout Details</h1>
        <Button 
          variant="outline" 
          size="sm" 
          onClick={shareWorkout}
          disabled={isSharing}
        >
          <Share2 className="h-4 w-4 mr-2" />
          {isSharing ? 'Sharing...' : 'Share'}
        </Button>
      </div>
      
      <Card className="bg-cream">
        <CardHeader className="bg-deep-ops text-cream rounded-t-lg">
          <CardTitle className="text-xl font-heading">
            {workout.exerciseType === 'RUNNING' ? 'Running' : 
             workout.exerciseType === 'PUSHUP' ? 'Push-ups' :
             workout.exerciseType === 'SITUP' ? 'Sit-ups' :
             workout.exerciseType === 'PULLUP' ? 'Pull-ups' :
             workout.exerciseType}
          </CardTitle>
          <CardDescription className="text-army-tan flex items-center">
            <Calendar className="h-4 w-4 mr-1" />
            {formattedDate} at {formattedTime}
          </CardDescription>
        </CardHeader>
        
        <CardContent className="p-6 space-y-6">
          <div className="grid grid-cols-2 gap-6">
            <div className="space-y-2">
              <div className="text-sm font-medium text-muted-foreground">
                {workout.exerciseType === 'RUNNING' ? 'Distance' : 'Repetitions'}
              </div>
              <div className="flex items-baseline">
                <span className="text-3xl font-mono text-brass-gold">
                  {workout.exerciseType === 'RUNNING' ? formatDistance(workout.count) : workout.count}
                </span>
                <span className="ml-1 text-sm text-muted-foreground">
                  {workout.exerciseType === 'RUNNING' ? '' : 'reps'}
                </span>
              </div>
            </div>
            
            <div className="space-y-2">
              <div className="text-sm font-medium text-muted-foreground">Duration</div>
              <div className="flex items-baseline">
                <span className="text-3xl font-mono text-brass-gold">
                  {formatTime(workout.durationSeconds)}
                </span>
              </div>
            </div>
          </div>
          
          <Separator />
          
          <div className="space-y-2">
            <div className="flex justify-between items-baseline">
              <div className="text-sm font-medium text-muted-foreground">Form Score</div>
              <div className="text-sm font-mono">{workout.formScore}%</div>
            </div>
            <Progress value={workout.formScore} className="h-2" />
          </div>
          
          <div className="space-y-3">
            <div className="text-sm font-medium text-muted-foreground">Performance Grade</div>
            <div className="p-4 bg-white/50 rounded-lg text-center">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-brass-gold text-white font-heading text-4xl">
                {workout.formScore >= 90 ? 'A' : 
                 workout.formScore >= 80 ? 'B' : 
                 workout.formScore >= 70 ? 'C' : 
                 workout.formScore >= 60 ? 'D' : 'F'}
              </div>
              <div className="mt-2 text-sm text-muted-foreground">
                {workout.formScore >= 90 ? 'Excellent Form' : 
                 workout.formScore >= 80 ? 'Good Form' : 
                 workout.formScore >= 70 ? 'Acceptable Form' : 
                 workout.formScore >= 60 ? 'Needs Improvement' : 'Poor Form'}
              </div>
            </div>
          </div>
          
          <div className="p-4 bg-muted/30 rounded-lg">
            <h3 className="text-sm font-semibold mb-2">Device Information</h3>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-muted-foreground">Platform:</span>
                <span className="ml-2">{workout.deviceType || "Web"}</span>
              </div>
              <div>
                <span className="text-muted-foreground">Session ID:</span>
                <span className="ml-2 font-mono text-xs">{workout.id.substring(0, 8)}</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
} 