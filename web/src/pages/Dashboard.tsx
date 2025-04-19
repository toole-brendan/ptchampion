import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { MetricCard } from '@/components/ui/metric-card';
import { 
  Dumbbell, 
  Activity, 
  Zap, 
  TrendingUp, 
  Clock, 
  Repeat, 
  Trophy, 
  ArrowRight, 
  Loader2, 
  CalendarClock, 
  Flame,
  AreaChart
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/lib/authContext';
import { useQuery } from '@tanstack/react-query';
import { useApi } from '@/lib/apiClient';
import { cn } from "@/lib/utils";

// Define exercise types for quick start
const exerciseLinks = [
  { name: "Push-ups", icon: Activity, path: '/trackers/pushups' },
  { name: "Pull-ups", icon: Dumbbell, path: '/trackers/pullups' },
  { name: "Sit-ups", icon: Zap, path: '/trackers/situps' },
  { name: "Running", icon: TrendingUp, path: '/trackers/running' },
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
    isLoading: isLeaderboardLoading 
  } = useQuery({
    queryKey: ['leaderboard', 'overall'],
    queryFn: () => api.leaderboard.getLeaderboard('overall'),
    staleTime: 1000 * 60 * 15, // 15 minutes
  });
  
  const isLoading = isAuthLoading || isHistoryLoading || isLeaderboardLoading;
  const error = authError || historyError;
  
  // Calculate dashboard metrics from history data
  const dashboardMetrics = React.useMemo(() => {
    if (!exerciseHistory || !leaderboardData) {
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
    
    // Find user rank in leaderboard
    let userRank = 0;
    if (user) {
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
  
  // Format the last workout date
  const formattedLastWorkoutDate = dashboardMetrics.lastWorkoutDate ? 
    dashboardMetrics.lastWorkoutDate.toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : 'Never';

  return (
    <div className="space-y-6">
      {/* Welcome Message */}
      <h1 className="font-heading text-2xl tracking-wide text-command-black">
        Welcome back, <span className="text-brass-gold">{userName}</span>!
      </h1>

      {/* Metrics Row */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <MetricCard
          title="Total Workouts"
          value={dashboardMetrics.totalWorkouts}
          icon={Flame}
          onClick={() => navigate('/history')}
        />
        
        <MetricCard
          title="Last Activity"
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
        />
        
        <MetricCard
          title="Total Repetitions"
          value={dashboardMetrics.totalReps}
          icon={Repeat}
          unit="reps"
          onClick={() => navigate('/history')}
        />
        
        <MetricCard
          title="Total Distance"
          value={(dashboardMetrics.totalDistance / 1000).toFixed(1)}
          unit="km"
          icon={TrendingUp}
          onClick={() => navigate('/history')}
        />
      </div>

      {/* Quick Start Section */}
      <Card className="bg-cream transition-shadow hover:shadow-md">
        <CardHeader className="rounded-t-lg bg-deep-ops text-cream">
          <CardTitle className="font-heading text-xl">
            Start Tracking
          </CardTitle>
          <CardDescription className="text-army-tan">
            Choose an exercise to begin a new session
          </CardDescription>
        </CardHeader>
        <CardContent className="pt-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {exerciseLinks.map((exercise) => (
              <Button
                key={exercise.name}
                variant="outline"
                className="flex h-24 flex-col items-center justify-center border-brass-gold/30 p-4 
                          transition-colors hover:border-brass-gold hover:bg-brass-gold/5"
                onClick={() => navigate(exercise.path)}
              >
                <exercise.icon className="mb-2 size-6 text-brass-gold" />
                <span className="text-sm font-medium">{exercise.name}</span>
              </Button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Progress Section */}
      <Card className="bg-cream transition-shadow hover:shadow-md">
        <CardHeader className="rounded-t-lg bg-deep-ops text-cream">
          <CardTitle className="flex items-center font-heading text-xl">
            <AreaChart className="mr-2 size-5" />
            Progress Summary
          </CardTitle>
          <CardDescription className="text-army-tan">
            Your training overview at a glance
          </CardDescription>
        </CardHeader>
        <CardContent className="pt-6">
          <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
            <div className="flex flex-col items-center justify-center rounded-lg bg-white/50 p-4 text-center">
              <Clock className="mb-2 size-10 text-brass-gold" />
              <span className="font-mono text-2xl text-brass-gold">
                {Math.floor(dashboardMetrics.totalDuration / 3600)}h {Math.floor((dashboardMetrics.totalDuration % 3600) / 60)}m
              </span>
              <span className="text-sm text-tactical-gray">Total Training Time</span>
            </div>
            
            <div className="flex flex-col items-center justify-center rounded-lg bg-white/50 p-4 text-center">
              <Flame className="mb-2 size-10 text-brass-gold" />
              <span className="font-mono text-2xl text-brass-gold">
                {Math.floor(dashboardMetrics.totalDuration / 60 * 7)}
              </span>
              <span className="text-sm text-tactical-gray">Est. Calories Burned</span>
            </div>
            
            <div className="flex flex-col items-center justify-center rounded-lg bg-white/50 p-4 text-center">
              <Trophy className="mb-2 size-10 text-brass-gold" />
              <span className="font-mono text-2xl text-brass-gold">
                {dashboardMetrics.userRank > 0 ? `#${dashboardMetrics.userRank}` : 'Unranked'}
              </span>
              <span className="text-sm text-tactical-gray">Global Leaderboard Rank</span>
            </div>
          </div>
          
          <div className="mt-6 flex justify-center">
            <Button 
              className="bg-brass-gold text-deep-ops hover:bg-brass-gold/90"
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