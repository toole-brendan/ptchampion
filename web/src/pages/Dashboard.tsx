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

// Military-style corner component
const MilitaryCorners: React.FC = () => (
  <>
    {/* Military corner cutouts - top left and right */}
    <div className="absolute top-0 left-0 w-[15px] h-[15px] bg-background"></div>
    <div className="absolute top-0 right-0 w-[15px] h-[15px] bg-background"></div>
    
    {/* Military corner cutouts - bottom left and right */}
    <div className="absolute bottom-0 left-0 w-[15px] h-[15px] bg-background"></div>
    <div className="absolute bottom-0 right-0 w-[15px] h-[15px] bg-background"></div>
    
    {/* Diagonal lines for corners */}
    <div className="absolute top-0 left-0 w-[15px] h-[1px] bg-tactical-gray/50 rotate-45 origin-top-left"></div>
    <div className="absolute top-0 right-0 w-[15px] h-[1px] bg-tactical-gray/50 -rotate-45 origin-top-right"></div>
    <div className="absolute bottom-0 left-0 w-[15px] h-[1px] bg-tactical-gray/50 -rotate-45 origin-bottom-left"></div>
    <div className="absolute bottom-0 right-0 w-[15px] h-[1px] bg-tactical-gray/50 rotate-45 origin-bottom-right"></div>
  </>
);

// Header divider component
const HeaderDivider: React.FC = () => (
  <div className="h-[1px] w-16 bg-brass-gold mx-auto my-2"></div>
);

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
        <Loader2 className="size-8 animate-spin text-brass-gold" />
      </div>
    );
  }

  if (error) {
    return (
      <Alert variant="destructive" className="rounded-card">
        <AlertCircle className="h-5 w-5" />
        <AlertTitle className="font-heading text-heading4">Error Loading Dashboard</AlertTitle>
        <AlertDescription>
          {error instanceof Error ? error.message : String(error)}
        </AlertDescription>
      </Alert>
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
    <div className="space-y-section">
      {/* Welcome Card */}
      <div className="relative overflow-hidden rounded-card bg-card-background p-content shadow-medium">
        <MilitaryCorners />
        <div className="mb-4 text-center">
          <h2 className="font-heading text-heading3 uppercase tracking-wider text-command-black">
            PT Champion
          </h2>
          <HeaderDivider />
          <p className="mt-2 text-sm uppercase tracking-wide text-tactical-gray">Fitness Evaluation System</p>
        </div>
        
        {/* User profile summary */}
        <div className="mt-4 rounded-card bg-cream/30 p-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-heading text-heading4 uppercase">{formatDisplayName()}</h3>
              <p className="text-sm text-tactical-gray">
                {dashboardMetrics.totalWorkouts} total workouts completed
              </p>
            </div>
            <Button 
              onClick={() => navigate('/profile')}
              variant="outline"
              className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
            >
              View Profile
            </Button>
          </div>
        </div>
      </div>

      {/* Metrics Section - 2x2 Grid with enhanced styling */}
      <div className="grid gap-card-gap md:grid-cols-2">
        <div className="grid gap-card-gap md:grid-cols-2">
          <MetricCard
            title="TOTAL WORKOUTS"
            value={dashboardMetrics.totalWorkouts}
            icon={Flame}
            onClick={() => navigate('/history')}
            className="relative overflow-hidden rounded-card bg-card-background shadow-medium hover:shadow-large transition-all"
            iconClassName="text-brass-gold"
            valueClassName="font-heading text-heading2 text-command-black"
            cornerElements={<MilitaryCorners />}
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
            className="relative overflow-hidden rounded-card bg-card-background shadow-medium hover:shadow-large transition-all"
            iconClassName="text-brass-gold"
            valueClassName="font-heading text-heading4 text-command-black"
            cornerElements={<MilitaryCorners />}
          />
        </div>
        
        <div className="grid gap-card-gap md:grid-cols-2">
          <MetricCard
            title="TOTAL REPETITIONS"
            value={dashboardMetrics.totalReps}
            icon={Repeat}
            unit="reps"
            onClick={() => navigate('/history')}
            className="relative overflow-hidden rounded-card bg-card-background shadow-medium hover:shadow-large transition-all"
            iconClassName="text-brass-gold"
            valueClassName="font-heading text-heading2 text-command-black"
            cornerElements={<MilitaryCorners />}
          />
          
          <MetricCard
            title="TOTAL DISTANCE"
            value={(dashboardMetrics.totalDistance / 1000).toFixed(1)}
            unit="km"
            icon={Flame}
            onClick={() => navigate('/history')}
            className="relative overflow-hidden rounded-card bg-card-background shadow-medium hover:shadow-large transition-all"
            iconClassName="text-brass-gold"
            valueClassName="font-heading text-heading2 text-command-black"
            cornerElements={<MilitaryCorners />}
          />
        </div>
      </div>

      {/* Enhanced Start Tracking Section */}
      <div className="relative overflow-hidden rounded-card bg-card-background shadow-medium">
        <MilitaryCorners />
        <div className="rounded-t-card bg-deep-ops p-content">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="font-heading text-heading3 text-cream uppercase tracking-wider">
                Start Tracking
              </h2>
              <p className="text-sm text-army-tan">
                Choose an exercise to begin a new session
              </p>
            </div>
            <Button 
              className="bg-brass-gold text-deep-ops hover:bg-brass-gold/90 shadow-small hover:shadow-medium transition-all"
              onClick={() => navigate('/exercises')}
            >
              <Play className="mr-2 size-4" />
              START SESSION
            </Button>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-item p-content lg:grid-cols-4">
          {exerciseLinks.map((exercise) => (
            <div
              key={exercise.name}
              className="group relative overflow-hidden rounded-card bg-cream/50 p-4 
                        transition-all hover:-translate-y-1 hover:border-brass-gold 
                        hover:shadow-medium active:bg-brass-gold/10"
              onClick={() => navigate(exercise.path)}
            >
              <div className="absolute inset-0 bg-gradient-to-b from-transparent to-brass-gold/5 group-hover:to-brass-gold/10 transition-all"></div>
              <div className="relative z-10 flex flex-col items-center justify-center">
                <img src={exercise.image} alt={exercise.name} className="mb-3 h-16 w-auto object-contain" />
                <span className="font-heading text-sm uppercase tracking-wider text-tactical-gray">{exercise.name}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Progress Section with design-system styling */}
      <div className="relative overflow-hidden rounded-card bg-card-background shadow-medium">
        <MilitaryCorners />
        <div className="rounded-t-card bg-deep-ops p-content">
          <h2 className="flex items-center font-heading text-heading3 text-cream uppercase tracking-wider">
            <AreaChart className="mr-2 size-5" />
            Progress Summary
          </h2>
          <p className="text-sm text-army-tan">
            Your training overview at a glance
          </p>
        </div>
        <div className="p-content">
          {leaderboardError && (
            <Alert variant="default" className="mb-4 bg-olive-mist/10 border-olive-mist">
              <AlertCircle className="h-5 w-5 text-tactical-gray" />
              <AlertTitle className="font-heading text-sm">Leaderboard data unavailable</AlertTitle>
              <AlertDescription className="text-tactical-gray">
                We're unable to load the leaderboard rankings right now. Your personal stats are still available.
              </AlertDescription>
            </Alert>
          )}

          <div className="grid grid-cols-1 gap-card-gap md:grid-cols-3">
            <div className="relative overflow-hidden rounded-card border-l-4 border-brass-gold bg-cream/30 p-content text-center shadow-small">
              <div className="absolute -left-1 top-1/2 h-8 w-1 -translate-y-1/2 rounded bg-brass-gold/40"></div>
              <Clock className="mb-2 size-10 text-brass-gold" />
              <span className="font-heading text-heading3 text-command-black">
                {Math.floor(dashboardMetrics.totalDuration / 3600)}h {Math.floor((dashboardMetrics.totalDuration % 3600) / 60)}m
              </span>
              <span className="text-xs font-semibold uppercase tracking-wider text-tactical-gray">Total Training Time</span>
            </div>
            
            <div className="relative overflow-hidden rounded-card border-l-4 border-brass-gold bg-cream/30 p-content text-center shadow-small">
              <div className="absolute -left-1 top-1/2 h-8 w-1 -translate-y-1/2 rounded bg-brass-gold/40"></div>
              <Flame className="mb-2 size-10 text-brass-gold" />
              <span className="font-heading text-heading3 text-command-black">
                {Math.floor(dashboardMetrics.totalDuration / 60 * 7)}
              </span>
              <span className="text-xs font-semibold uppercase tracking-wider text-tactical-gray">Est. Calories Burned</span>
            </div>
            
            <div className="relative overflow-hidden rounded-card border-l-4 border-brass-gold bg-cream/30 p-content text-center shadow-small">
              <div className="absolute -left-1 top-1/2 h-8 w-1 -translate-y-1/2 rounded bg-brass-gold/40"></div>
              <Trophy className="mb-2 size-10 text-brass-gold" />
              <span className="font-heading text-heading3 text-command-black">
                {isLeaderboardLoading ? (
                  <Loader2 className="mx-auto size-6 animate-spin text-brass-gold/70" />
                ) : dashboardMetrics.userRank > 0 ? (
                  `#${dashboardMetrics.userRank}` 
                ) : (
                  'Unranked'
                )}
              </span>
              <span className="text-xs font-semibold uppercase tracking-wider text-tactical-gray">Global Leaderboard Rank</span>
            </div>
          </div>
          
          <div className="mt-6 flex justify-center">
            <Button 
              className="bg-brass-gold text-deep-ops transition-all font-heading shadow-medium hover:shadow-large hover:-translate-y-1 hover:bg-brass-gold/90"
              onClick={() => navigate('/history')}
            >
              <ArrowRight className="mr-2 size-4" />
              VIEW DETAILED PROGRESS
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard; 