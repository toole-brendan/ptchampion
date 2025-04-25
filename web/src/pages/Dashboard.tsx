import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { MetricCard } from '@/components/ui/metric-card';
import { 
  Clock, 
  Repeat, 
  Trophy, 
  ArrowRight, 
  Loader2, 
  CalendarClock, 
  Flame,
  AreaChart,
  AlertCircle,
  Play
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/lib/authContext';
import { useHeaderContext } from '@/dashboard-message-context';
import { useQuery } from '@tanstack/react-query';
import { useApi } from '@/lib/apiClient';
import { cn } from "@/lib/utils";
import { Alert, AlertTitle, AlertDescription } from "@/components/ui/alert";

// Import the exercise PNG images
import pushupImage from '@/assets/pushup.png';
import pullupImage from '@/assets/pullup.png';
import situpImage from '@/assets/situp.png';
import runningImage from '@/assets/running.png';

// Define exercise types for quick start
const exerciseLinks = [
  { name: "PUSH-UPS", image: pushupImage, path: '/exercises/pushups' },
  { name: "PULL-UPS", image: pullupImage, path: '/exercises/pullups' },
  { name: "SIT-UPS", image: situpImage, path: '/exercises/situps' },
  { name: "RUNNING", image: runningImage, path: '/exercises/running' },
];

const Dashboard: React.FC = () => {
  const navigate = useNavigate();
  const { user, isLoading: isAuthLoading, error: authError } = useAuth();
  const api = useApi();
  const { setUserName } = useHeaderContext();
  
  // Get user exercise history for dashboard stats
  const { 
    data: exerciseHistory, 
    isLoading: isHistoryLoading,
    error: historyError
  } = useQuery({
    queryKey: ['exerciseHistory', user?.id, 1, 15], // First page, 15 items
    queryFn: () => api.exercises.getUserExercises(1, 15),
    enabled: !!user,
    staleTime: 1000 * 60 * 5, // 5 minutes
  });
  
  // Get leaderboard data for user ranking
  const { 
    data: leaderboardData, 
    isLoading: isLeaderboardLoading,
    error: leaderboardError
  } = useQuery({
    queryKey: ['leaderboard', 'overall'],
    queryFn: () => api.leaderboard.getLeaderboard('overall'),
    staleTime: 1000 * 60 * 15, // 15 minutes
    retry: 1, // Only retry once
    refetchOnMount: false, // Don't refetch on every mount
    refetchOnWindowFocus: false, // Don't refetch on window focus
  });
  
  // Base loading state only on auth and history, not leaderboard
  const isLoading = isAuthLoading || isHistoryLoading;
  const error = authError || historyError;
  
  // Calculate dashboard metrics from history data
  const dashboardMetrics = React.useMemo(() => {
    if (!exerciseHistory) {
      return {
        totalWorkouts: 0,
        lastWorkoutDate: null,
        lastWorkoutType: null,
        lastWorkoutMetric: null,
        totalReps: 0,
        totalDistance: 0,
        totalDuration: 0,
        userRank: 0
      };
    }
    
    const items = exerciseHistory.items || [];
    const totalWorkouts = exerciseHistory.total_count || 0;
    const lastWorkout = items[0]; // Most recent workout
    
    // Calculate totals
    let totalReps = 0;
    let totalDistance = 0;
    let totalDuration = 0;
    
    items.forEach(workout => {
      // For running, we might use reps field for distance or have a separate distance field
      if (workout.exercise_type === 'RUNNING') {
        totalDistance += workout.distance || 0;
      } else {
        totalReps += workout.reps || 0;
      }
      totalDuration += workout.time_in_seconds || 0;
    });
    
    // Find user rank in leaderboard - handle null leaderboard data gracefully
    let userRank = 0;
    if (user && leaderboardData && Array.isArray(leaderboardData)) {
      const userIndex = leaderboardData.findIndex(entry => entry.user_id === user.id);
      userRank = userIndex !== -1 ? userIndex + 1 : 0;
    }
    
    return {
      totalWorkouts,
      lastWorkoutDate: lastWorkout ? new Date(lastWorkout.created_at) : null,
      lastWorkoutType: lastWorkout ? lastWorkout.exercise_type : null,
      lastWorkoutMetric: lastWorkout ? 
        (lastWorkout.exercise_type === 'RUNNING' ? 
          `${((lastWorkout.distance || 0) / 1000).toFixed(2)} km` : 
          `${lastWorkout.reps || 0} reps`) 
        : null,
      totalReps,
      totalDistance,
      totalDuration,
      userRank
    };
  }, [exerciseHistory, leaderboardData, user]);
  
  // Set username in context when it changes
  useEffect(() => {
    if (user && setUserName) {
      // Extract first name from display_name, username, or email
      let firstName = '';
      
      if (user.display_name) {
        // Use first part of display name
        firstName = user.display_name.split(' ')[0];
      } else if (user.username) {
        // Check if it's an email address
        if (user.username.includes('@')) {
          // For email like "toole.brendan@gmail.com", extract "brendan"
          const emailParts = user.username.split('@')[0];
          
          if (emailParts.includes('.')) {
            // Assume format is "lastname.firstname@..."
            firstName = emailParts.split('.')[1];
          } else {
            // Just use whatever is before the @ symbol
            firstName = emailParts;
          }
        } else {
          firstName = user.username;
        }
      } else {
        firstName = 'User';
      }
      
      // Properly capitalize the first name (e.g., "john" → "John")
      firstName = firstName.charAt(0).toUpperCase() + firstName.slice(1).toLowerCase();
      
      setUserName(`Welcome Back, ${firstName}`);
    }
  }, [user, setUserName]);
  
  if (isLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <Loader2 className="size-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-md border border-destructive p-4 text-destructive">
        Error: {error instanceof Error ? error.message : String(error)}
      </div>
    );
  }

  // Format display name properly
  const formatDisplayName = () => {
    if (!user) return 'USER';
    
    if (user.display_name) {
      return user.display_name;
    }
    
    if (user.username) {
      return user.username;
    }
    
    return 'USER';
  };
  
  // Format the last workout date
  const formattedLastWorkoutDate = dashboardMetrics.lastWorkoutDate ? 
    dashboardMetrics.lastWorkoutDate.toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : 'Never';

  return (
    <div className="space-y-6">
      {/* Metrics Section - 2x2 Grid with reduced vertical padding */}
      <div className="grid gap-4 py-4 md:grid-cols-2">
        <div className="grid gap-4 md:grid-cols-2">
          <MetricCard
            title="TOTAL WORKOUTS"
            value={dashboardMetrics.totalWorkouts}
            icon={Flame}
            onClick={() => navigate('/history')}
            className="bg-white shadow-sm transition-all hover:-translate-y-1 hover:shadow-md"
          />
          
          <MetricCard
            title="LAST ACTIVITY"
            value={dashboardMetrics.lastWorkoutType ? 
              dashboardMetrics.lastWorkoutType === 'RUNNING' ? 'Running' : 
              dashboardMetrics.lastWorkoutType === 'PUSHUP' ? 'Push-ups' :
              dashboardMetrics.lastWorkoutType === 'SITUP' ? 'Sit-ups' :
              dashboardMetrics.lastWorkoutType === 'PULLUP' ? 'Pull-ups' :
              dashboardMetrics.lastWorkoutType : 'None'
            }
            description={dashboardMetrics.lastWorkoutDate ? 
              `${formattedLastWorkoutDate} - ${dashboardMetrics.lastWorkoutMetric}` : 
              'No workouts yet'
            }
            icon={CalendarClock}
            onClick={() => dashboardMetrics.lastWorkoutDate && navigate('/history')}
            className="bg-white shadow-sm transition-all hover:-translate-y-1 hover:shadow-md"
          />
        </div>
        
        <div className="grid gap-4 md:grid-cols-2">
          <MetricCard
            title="TOTAL REPETITIONS"
            value={dashboardMetrics.totalReps}
            icon={Repeat}
            unit="reps"
            onClick={() => navigate('/history')}
            className="bg-white shadow-sm transition-all hover:-translate-y-1 hover:shadow-md"
          />
          
          <MetricCard
            title="TOTAL DISTANCE"
            value={(dashboardMetrics.totalDistance / 1000).toFixed(1)}
            unit="km"
            icon={Flame}
            onClick={() => navigate('/history')}
            className="bg-white shadow-sm transition-all hover:-translate-y-1 hover:shadow-md"
          />
        </div>
      </div>

      {/* Enhanced Start Tracking Section */}
      <Card className="rounded-panel bg-[#EDE9DB] shadow-sm transition-shadow hover:shadow-md">
        <CardHeader className="rounded-t-panel bg-deep-ops pb-4 text-cream">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="font-heading text-xl">
                Start Tracking
              </CardTitle>
              <CardDescription className="text-army-tan">
                Choose an exercise to begin a new session
              </CardDescription>
            </div>
            <Button 
              className="bg-brass-gold text-deep-ops hover:bg-brass-gold/90"
              onClick={() => navigate('/exercises')}
            >
              <Play className="mr-2 size-4" />
              Start Session
            </Button>
          </div>
        </CardHeader>
        <CardContent className="grid grid-cols-2 gap-4 p-6 lg:grid-cols-4">
          {exerciseLinks.map((exercise) => (
            <div
              key={exercise.name}
              className="flex cursor-pointer flex-col items-center justify-center rounded-lg bg-white p-4 
                        transition-all hover:-translate-y-1 hover:border-brass-gold hover:bg-white 
                        hover:shadow-md active:bg-brass-gold/10"
              onClick={() => navigate(exercise.path)}
            >
              <img src={exercise.image} alt={exercise.name} className="mb-3 h-16 w-auto object-contain" />
              <span className="font-sans text-sm font-semibold text-tactical-gray">{exercise.name}</span>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Progress Section with less padding */}
      <Card className="rounded-panel bg-white shadow-sm transition-shadow hover:shadow-md">
        <CardHeader className="rounded-t-panel bg-deep-ops pb-4 text-cream">
          <CardTitle className="flex items-center font-heading text-xl">
            <AreaChart className="mr-2 size-5" />
            Progress Summary
          </CardTitle>
          <CardDescription className="text-army-tan">
            Your training overview at a glance
          </CardDescription>
        </CardHeader>
        <CardContent className="p-4">
          {leaderboardError && (
            <Alert variant="default" className="mb-4">
              <AlertCircle className="h-4 w-4" />
              <AlertTitle>Leaderboard data unavailable</AlertTitle>
              <AlertDescription>
                We're unable to load the leaderboard rankings right now. Your personal stats are still available.
              </AlertDescription>
            </Alert>
          )}

          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <div className="relative flex flex-col items-center justify-center rounded-lg border-l-4 border-brass-gold bg-cream/50 p-4 text-center shadow-sm">
              <div className="absolute -left-1 top-1/2 h-8 w-1 -translate-y-1/2 rounded bg-brass-gold/40"></div>
              <Clock className="mb-2 size-10 text-brass-gold" />
              <span className="font-mono text-2xl font-medium text-command-black">
                {Math.floor(dashboardMetrics.totalDuration / 3600)}h {Math.floor((dashboardMetrics.totalDuration % 3600) / 60)}m
              </span>
              <span className="text-xs font-medium uppercase tracking-wide text-tactical-gray">Total Training Time</span>
            </div>
            
            <div className="relative flex flex-col items-center justify-center rounded-lg border-l-4 border-brass-gold bg-cream/50 p-4 text-center shadow-sm">
              <div className="absolute -left-1 top-1/2 h-8 w-1 -translate-y-1/2 rounded bg-brass-gold/40"></div>
              <Flame className="mb-2 size-10 text-brass-gold" />
              <span className="font-mono text-2xl font-medium text-command-black">
                {Math.floor(dashboardMetrics.totalDuration / 60 * 7)}
              </span>
              <span className="text-xs font-medium uppercase tracking-wide text-tactical-gray">Est. Calories Burned</span>
            </div>
            
            <div className="relative flex flex-col items-center justify-center rounded-lg border-l-4 border-brass-gold bg-cream/50 p-4 text-center shadow-sm">
              <div className="absolute -left-1 top-1/2 h-8 w-1 -translate-y-1/2 rounded bg-brass-gold/40"></div>
              <Trophy className="mb-2 size-10 text-brass-gold" />
              <span className="font-mono text-2xl font-medium text-command-black">
                {isLeaderboardLoading ? (
                  <Loader2 className="mx-auto size-6 animate-spin text-brass-gold/70" />
                ) : dashboardMetrics.userRank > 0 ? (
                  `#${dashboardMetrics.userRank}` 
                ) : (
                  'Unranked'
                )}
              </span>
              <span className="text-xs font-medium uppercase tracking-wide text-tactical-gray">Global Leaderboard Rank</span>
            </div>
          </div>
          
          <div className="mt-4 flex justify-center">
            <Button 
              className="bg-brass-gold text-deep-ops transition-all hover:-translate-y-1 hover:bg-brass-gold/90 hover:shadow-md"
              onClick={() => navigate('/history')}
            >
              <ArrowRight className="mr-2 size-4" />
              View Detailed Progress
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Dashboard; 