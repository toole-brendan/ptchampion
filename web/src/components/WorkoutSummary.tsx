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
        <div className="flex justify-between items-center">
          <div>
            <CardTitle className="text-2xl font-semibold">Workout Completed!</CardTitle>
            <CardDescription>{getExerciseName(exerciseType)} session - {formatDate(date)}</CardDescription>
          </div>
          <div className="bg-primary text-primary-foreground rounded-full p-3">
            <Award className="size-7" />
          </div>
        </div>
      </CardHeader>

      <CardContent className="py-6">
        <div className="grid grid-cols-2 gap-y-6 gap-x-4">
          {isRunning ? (
            // Running specific metrics
            <>
              {/* Distance */}
              <div className="flex flex-col items-center justify-center p-4 bg-muted rounded-lg">
                <p className="text-sm text-muted-foreground mb-1">Distance</p>
                <div className="flex items-center">
                  <MapPin className="mr-1.5 size-5 text-muted-foreground" />
                  <p className="text-4xl font-bold">{formatDistance(distance)}</p>
                </div>
              </div>
            </>
          ) : (
            // Rep-based exercise metrics
            <>
              {/* Reps */}
              <div className="flex flex-col items-center justify-center p-4 bg-muted rounded-lg">
                <p className="text-sm text-muted-foreground mb-1">Total Reps</p>
                <p className="text-4xl font-bold">{repCount}</p>
              </div>
            </>
          )}

          {/* Time */}
          <div className="flex flex-col items-center justify-center p-4 bg-muted rounded-lg">
            <p className="text-sm text-muted-foreground mb-1">Duration</p>
            <div className="flex items-center">
              <Clock className="mr-1.5 size-5 text-muted-foreground" />
              <p className="text-4xl font-bold">{formatTime(duration)}</p>
            </div>
          </div>

          {/* APFT Score or Form Score */}
          <div className="flex flex-col items-center justify-center p-4 bg-muted rounded-lg">
            <p className="text-sm text-muted-foreground mb-1">{isRunning ? 'Pace' : 'APFT Score'}</p>
            <p className="text-4xl font-bold">{isRunning ? pace : grade || '--'}</p>
          </div>

          {/* Rep-to-Score Ratio or Pace */}
          <div className="flex flex-col items-center justify-center p-4 bg-muted rounded-lg">
            <p className="text-sm text-muted-foreground mb-1">{isRunning ? 'Performance' : 'Form Score'}</p>
            <div className="flex items-center">
              <BarChart className="mr-1.5 size-5 text-muted-foreground" />
              <p className="text-4xl font-bold">
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
        <div className="mt-6 p-3 rounded-md bg-background/80 border flex items-center justify-between">
          <span>Workout {saved ? 'saved' : 'pending sync'}</span>
          <span className={`px-2 py-0.5 rounded-full text-xs ${saved ? 'bg-green-100 text-green-800' : 'bg-amber-100 text-amber-800'}`}>
            {saved ? 'Synced' : 'Will sync when online'}
          </span>
        </div>
      </CardContent>
    </Card>
  );
};

export default WorkoutSummary; 