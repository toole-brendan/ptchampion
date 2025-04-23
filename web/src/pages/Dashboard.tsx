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
  AlertCircle
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/lib/authContext';
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

  // Get user name (fallback to username if display name isn't set)
  const userName = user?.display_name || user?.username || 'User';
  
  // Format display name properly
  const formatDisplayName = () => {
    if (!userName) return 'USER';
    
    if (userName.includes('@')) {
      // If it's an email, extract the part before @
      const namePart = userName.split('@')[0];
      // Convert to title case if it's all lowercase or all uppercase
      if (namePart === namePart.toLowerCase() || namePart === namePart.toUpperCase()) {
        return namePart
          .split(/[._-]/)
          .map(part => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
          .join(' ');
      }
      return namePart;
    }
    
    // If it's a full name with spaces, check if it's in "Last, First" format
    if (userName.includes(' ')) {
      // Check if there's a comma in the name (Last, First)
      if (userName.includes(',')) {
        const parts = userName.split(',').map(part => part.trim());
        // Swap order to "First Last"
        return `${parts[1]} ${parts[0]}`;
      }
      
      // Some names might be stored as "LASTNAME FIRSTNAME"
      if (userName === userName.toUpperCase()) {
        const parts = userName.toLowerCase().split(' ');
        // Assume lastname firstname format if all uppercase and convert to "Firstname Lastname"
        return parts.reverse()
          .map(part => part.charAt(0).toUpperCase() + part.slice(1))
          .join(' ');
      }
      
      return userName;
    }
    
    // Otherwise, convert to title case if needed
    if (userName === userName.toLowerCase() || userName === userName.toUpperCase()) {
      return userName.charAt(0).toUpperCase() + userName.slice(1).toLowerCase();
    }
    
    return userName;
  };
  
  // Format the last workout date
  const formattedLastWorkoutDate = dashboardMetrics.lastWorkoutDate ? 
    dashboardMetrics.lastWorkoutDate.toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : 'Never';

  return (
    <div className="space-y-8">
      {/* Enhanced Hero Section */}
      <div className="rounded-panel bg-gradient-to-r from-deep-ops/5 to-olive-mist/20 p-6">
        <h1 className="font-heading text-3xl tracking-wide text-command-black">
          WELCOME BACK, <span className="text-brass-gold">{formatDisplayName()}</span>
        </h1>
        <div className="mt-1 h-1 w-24 bg-brass-gold/40"></div>
      </div>

      {/* Metrics Section - 2x2 Grid */}
      <div className="grid gap-6 md:grid-cols-2">
        <div className="grid gap-4 md:grid-cols-2">
          <MetricCard
            title="TOTAL WORKOUTS"
            value={dashboardMetrics.totalWorkouts}
            icon={Flame}
            onClick={() => navigate('/history')}
            className="bg-white transition-all hover:-translate-y-1 hover:shadow-md"
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
            className="bg-white transition-all hover:-translate-y-1 hover:shadow-md"
          />
        </div>
        
        <div className="grid gap-4 md:grid-cols-2">
          <MetricCard
            title="TOTAL REPETITIONS"
            value={dashboardMetrics.totalReps}
            icon={Repeat}
            unit="reps"
            onClick={() => navigate('/history')}
            className="bg-white transition-all hover:-translate-y-1 hover:shadow-md"
          />
          
          <MetricCard
            title="TOTAL DISTANCE"
            value={(dashboardMetrics.totalDistance / 1000).toFixed(1)}
            unit="km"
            icon={Flame}
            onClick={() => navigate('/history')}
            className="bg-white transition-all hover:-translate-y-1 hover:shadow-md"
          />
        </div>
      </div>

      {/* Enhanced Start Tracking Section */}
      <Card className="rounded-panel bg-[#EDE9DB] shadow-sm transition-shadow hover:shadow-md">
        <CardHeader className="rounded-t-panel bg-deep-ops pb-4 text-cream">
          <CardTitle className="font-heading text-xl">
            Start Tracking
          </CardTitle>
          <CardDescription className="text-army-tan">
            Choose an exercise to begin a new session
          </CardDescription>
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

      {/* Progress Section */}
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
        <CardContent className="p-6">
          {leaderboardError && (
            <Alert variant="default" className="mb-4">
              <AlertCircle className="h-4 w-4" />
              <AlertTitle>Leaderboard data unavailable</AlertTitle>
              <AlertDescription>
                We're unable to load the leaderboard rankings right now. Your personal stats are still available.
              </AlertDescription>
            </Alert>
          )}

          <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
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
          
          <div className="mt-6 flex justify-center">
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