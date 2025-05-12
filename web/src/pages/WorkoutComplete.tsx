import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Clock, Award, BarChart } from 'lucide-react';
import { ExerciseResult } from '@/viewmodels/TrackerViewModel';
import { formatScoreDisplay } from '@/grading/APFTScoring';

const WorkoutComplete: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const result = location.state as ExerciseResult;
  
  // If no result data, redirect to exercises page
  if (!result) {
    // Use useEffect to avoid React warnings about navigation during render
    React.useEffect(() => {
      navigate('/exercises', { replace: true });
    }, [navigate]);
    return null;
  }

  // Helper function to get human-readable exercise name
  const getExerciseName = (type: string): string => {
    // Map to proper display name
    const exerciseNames: Record<string, string> = {
      'PUSHUP': 'Push-ups',
      'PULLUP': 'Pull-ups',
      'SITUP': 'Sit-ups',
      'RUNNING': 'Running'
    };
    return exerciseNames[type] || type;
  };

  // Format timestamp to readable date/time
  const formatDate = (date: Date): string => {
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric'
    }).format(date);
  };

  // Format time in seconds to mm:ss
  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="container mx-auto max-w-lg py-12 px-4">
      <div className="flex items-center justify-between mb-8">
        <Button variant="outline" onClick={() => navigate('/exercises')}>
          <ArrowLeft className="mr-2 size-4" /> Back to Exercises
        </Button>
      </div>

      <Card className="bg-card shadow-lg">
        <CardHeader className="bg-primary/10 pb-6">
          <div className="flex justify-between items-center">
            <div>
              <CardTitle className="text-2xl font-semibold">Workout Completed!</CardTitle>
              <CardDescription>{getExerciseName(result.exerciseType)} session - {formatDate(result.date)}</CardDescription>
            </div>
            <div className="bg-primary text-primary-foreground rounded-full p-3">
              <Award className="size-7" />
            </div>
          </div>
        </CardHeader>

        <CardContent className="py-6">
          <div className="grid grid-cols-2 gap-y-6 gap-x-4">
            {/* Reps */}
            <div className="flex flex-col items-center justify-center p-4 bg-muted rounded-lg">
              <p className="text-sm text-muted-foreground mb-1">Total Reps</p>
              <p className="text-4xl font-bold">{result.repCount}</p>
            </div>

            {/* Time */}
            <div className="flex flex-col items-center justify-center p-4 bg-muted rounded-lg">
              <p className="text-sm text-muted-foreground mb-1">Duration</p>
              <div className="flex items-center">
                <Clock className="mr-1.5 size-5 text-muted-foreground" />
                <p className="text-4xl font-bold">{formatTime(result.duration)}</p>
              </div>
            </div>

            {/* APFT Score */}
            <div className="flex flex-col items-center justify-center p-4 bg-muted rounded-lg">
              <p className="text-sm text-muted-foreground mb-1">APFT Score</p>
              <p className="text-4xl font-bold">{result.grade || '--'}</p>
            </div>

            {/* Rep-to-Score Ratio */}
            <div className="flex flex-col items-center justify-center p-4 bg-muted rounded-lg">
              <p className="text-sm text-muted-foreground mb-1">Rep-to-Score</p>
              <div className="flex items-center">
                <BarChart className="mr-1.5 size-5 text-muted-foreground" />
                <p className="text-4xl font-bold">
                  {typeof result.grade === 'number' 
                    ? formatScoreDisplay(result.repCount || 0, result.grade) 
                    : '--'}
                </p>
              </div>
            </div>
          </div>

          {/* Sync Status */}
          <div className="mt-6 p-3 rounded-md bg-background/80 border flex items-center justify-between">
            <span>Workout {result.saved ? 'saved' : 'pending sync'}</span>
            <span className={`px-2 py-0.5 rounded-full text-xs ${result.saved ? 'bg-green-100 text-green-800' : 'bg-amber-100 text-amber-800'}`}>
              {result.saved ? 'Synced' : 'Will sync when online'}
            </span>
          </div>
        </CardContent>

        <CardFooter className="flex flex-col gap-3 pt-2 pb-6">
          <Button className="w-full" onClick={() => navigate('/history')}>
            View Workout History
          </Button>
          <Button variant="outline" className="w-full" onClick={() => {
            // Navigate back to the specific exercise page
            const exerciseRoutes: Record<string, string> = {
              'PUSHUP': '/exercises/pushups',
              'PULLUP': '/exercises/pullups',
              'SITUP': '/exercises/situps',
              'RUNNING': '/exercises/running'
            };
            navigate(exerciseRoutes[result.exerciseType] || '/exercises');
          }}>
            Start New Session
          </Button>
        </CardFooter>
      </Card>
    </div>
  );
};

export default WorkoutComplete; 