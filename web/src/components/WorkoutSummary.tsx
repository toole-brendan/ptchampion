import React from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Award, Clock, BarChart, MapPin } from 'lucide-react';
import { ExerciseType } from '@/grading';
import { formatDistance, formatTime } from '@/lib/utils';

export interface WorkoutSummaryProps {
  exerciseType: ExerciseType;
  date: Date;
  repCount?: number;
  distance?: number;      // miles
  duration: number;       // seconds
  pace?: string;          // "8:34 /mi" etc
  formScore?: number;     // %
  grade?: string | number;  // A–F or numeric
  saved: boolean;
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

export const WorkoutSummary: React.FC<WorkoutSummaryProps> = ({
  exerciseType,
  date,
  repCount = 0,
  distance = 0,
  duration,
  pace,
  formScore,
  grade,
  saved
}) => {
  const isRunning = exerciseType === 'RUNNING';
  
  return (
    <Card className="bg-card shadow-lg">
      <CardHeader className="bg-primary/10 pb-6">
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="font-semibold text-2xl">Workout Completed!</CardTitle>
            <CardDescription>{getExerciseName(exerciseType)} session - {formatDate(date)}</CardDescription>
          </div>
          <div className="rounded-full bg-primary p-3 text-primary-foreground">
            <Award className="size-7" />
          </div>
        </div>
      </CardHeader>

      <CardContent className="py-6">
        <div className="grid grid-cols-2 gap-x-4 gap-y-6">
          {isRunning ? (
            // Running specific metrics
            <>
              {/* Distance */}
              <div className="flex flex-col items-center justify-center rounded-lg bg-muted p-4">
                <p className="mb-1 text-sm text-muted-foreground">Distance</p>
                <div className="flex items-center">
                  <MapPin className="mr-1.5 size-5 text-muted-foreground" />
                  <p className="font-bold text-4xl">{formatDistance(distance)}</p>
                </div>
              </div>
            </>
          ) : (
            // Rep-based exercise metrics
            <>
              {/* Reps */}
              <div className="flex flex-col items-center justify-center rounded-lg bg-muted p-4">
                <p className="mb-1 text-sm text-muted-foreground">Total Reps</p>
                <p className="font-bold text-4xl">{repCount}</p>
              </div>
            </>
          )}

          {/* Time */}
          <div className="flex flex-col items-center justify-center rounded-lg bg-muted p-4">
            <p className="mb-1 text-sm text-muted-foreground">Duration</p>
            <div className="flex items-center">
              <Clock className="mr-1.5 size-5 text-muted-foreground" />
              <p className="font-bold text-4xl">{formatTime(duration)}</p>
            </div>
          </div>

          {/* APFT Score or Form Score */}
          <div className="flex flex-col items-center justify-center rounded-lg bg-muted p-4">
            <p className="mb-1 text-sm text-muted-foreground">{isRunning ? 'Pace' : 'APFT Score'}</p>
            <p className="font-bold text-4xl">{isRunning ? pace : grade || '--'}</p>
          </div>

          {/* Rep-to-Score Ratio or Pace */}
          <div className="flex flex-col items-center justify-center rounded-lg bg-muted p-4">
            <p className="mb-1 text-sm text-muted-foreground">{isRunning ? 'Performance' : 'Form Score'}</p>
            <div className="flex items-center">
              <BarChart className="mr-1.5 size-5 text-muted-foreground" />
              <p className="font-bold text-4xl">
                {formScore !== undefined ? `${formScore}%` : '--'}
              </p>
            </div>
          </div>
        </div>

        {/* Form score progress bar */}
        {formScore !== undefined && (
          <div className="mt-6 space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Form Quality</span>
              <span className="font-medium">{formScore}%</span>
            </div>
            <Progress value={formScore} className="h-2" />
          </div>
        )}

        {/* Sync Status */}
        <div className="mt-6 flex items-center justify-between rounded-md border bg-background/80 p-3">
          <span>Workout {saved ? 'saved' : 'pending sync'}</span>
          <span className={`rounded-full px-2 py-0.5 text-xs ${saved ? 'bg-green-100 text-green-800' : 'bg-amber-100 text-amber-800'}`}>
            {saved ? 'Synced' : 'Will sync when online'}
          </span>
        </div>
      </CardContent>
    </Card>
  );
};

export default WorkoutSummary; 