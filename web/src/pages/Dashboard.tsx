import React, { useEffect } from 'react';
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
  Play,
  Route
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/lib/authContext';
import { useHeaderContext } from '@/dashboard-message-context';
import { useQuery } from '@tanstack/react-query';
import { useApi } from '@/lib/apiClient';
import { Alert, AlertTitle, AlertDescription } from "@/components/ui/alert";
import { 
  QuickLinkCard, 
  SectionCard, 
  WelcomeCard 
} from '@/components/ui/card';

// Import the exercise PNG images with explicit paths to ensure they're found
import pushupImage from '../assets/pushup.png';
import pullupImage from '../assets/pullup.png';
import situpImage from '../assets/situp.png';
import runningImage from '../assets/running.png';

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
      // Since we're using Option A (username = display_name), just use username directly
      let displayText = 'Hello';
      
      if (user.username) {
        // Extract a friendly name from the username if possible
        const usernameWithoutSpecialChars = user.username.replace(/[^a-zA-Z0-9]/g, ' ');
        displayText = `Hello, ${usernameWithoutSpecialChars}`;
      }
      
      console.log('Setting header username:', displayText, 'from user:', user);
      setUserName(displayText);
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
        <AlertCircle className="size-5" />
        <AlertTitle className="font-heading text-heading4">Error Loading Dashboard</AlertTitle>
        <AlertDescription>
          {error instanceof Error ? error.message : String(error)}
        </AlertDescription>
      </Alert>
    );
  }

  // Format display name properly
  const formatDisplayName = () => {
    if (!user) return 'Soldier';
    
    // Use username which is now the same as display_name (Option A)
    return user.username || 'Soldier';
  };
  
  // Format the last workout date
  const formattedLastWorkoutDate = dashboardMetrics.lastWorkoutDate ? 
    dashboardMetrics.lastWorkoutDate.toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : 'Never';

  // Define metrics for grid
  const metrics = [
    {
      title: "TOTAL WORKOUTS",
      value: dashboardMetrics.totalWorkouts,
      icon: Flame,
      iconClassName: "text-brass-gold",
      valueClassName: "font-heading text-heading2 text-command-black",
      onClick: () => navigate('/history')
    },
    {
      title: "LAST ACTIVITY",
      value: dashboardMetrics.lastWorkoutType ? 
        dashboardMetrics.lastWorkoutType === 'RUNNING' ? 'Running' : 
        dashboardMetrics.lastWorkoutType === 'PUSHUP' ? 'Push-ups' :
        dashboardMetrics.lastWorkoutType === 'SITUP' ? 'Sit-ups' :
        dashboardMetrics.lastWorkoutType === 'PULLUP' ? 'Pull-ups' :
        dashboardMetrics.lastWorkoutType : 'None',
      description: dashboardMetrics.lastWorkoutDate ? 
        `${formattedLastWorkoutDate} - ${dashboardMetrics.lastWorkoutMetric}` : 
        'No workouts yet',
      icon: CalendarClock,
      iconClassName: "text-brass-gold",
      valueClassName: "font-heading text-heading4 text-command-black",
      onClick: () => dashboardMetrics.lastWorkoutDate && navigate('/history')
    },
    {
      title: "TOTAL REPETITIONS",
      value: dashboardMetrics.totalReps,
      icon: Repeat,
      unit: "reps",
      iconClassName: "text-brass-gold",
      valueClassName: "font-heading text-heading2 text-command-black",
      onClick: () => navigate('/history')
    },
    {
      title: "TOTAL DISTANCE",
      value: (dashboardMetrics.totalDistance / 1000).toFixed(1),
      unit: "km",
      icon: Route,
      iconClassName: "text-brass-gold",
      valueClassName: "font-heading text-heading2 text-command-black",
      onClick: () => navigate('/history')
    }
  ];

  // Progress summary metrics
  const progressMetrics = [
    {
      title: "TOTAL TRAINING TIME",
      value: `${Math.floor(dashboardMetrics.totalDuration / 3600)}h ${Math.floor((dashboardMetrics.totalDuration % 3600) / 60)}m`,
      icon: Clock,
      iconClassName: "text-brass-gold",
      valueClassName: "font-heading text-heading3 text-command-black",
      index: 0
    },
    {
      title: "EST. CALORIES BURNED",
      value: Math.floor(dashboardMetrics.totalDuration / 60 * 7),
      icon: Flame,
      iconClassName: "text-brass-gold",
      valueClassName: "font-heading text-heading3 text-command-black",
      index: 1
    }
  ];

  // Get the rank display value as a string
  const rankDisplayValue = isLeaderboardLoading 
    ? "Loading..." 
    : dashboardMetrics.userRank > 0 
      ? `#${dashboardMetrics.userRank}` 
      : 'Unranked';

  return (
    <div className="bg-cream min-h-screen px-4 py-section md:py-12 lg:px-8">
      <div className="flex flex-col space-y-section max-w-7xl mx-auto">
        {/* Welcome Card */}
        <WelcomeCard
          className="animate-fade-in"
          profileSection={
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
              >
                View Profile
              </Button>
            </div>
          }
        />

        {/* Metrics Section - Flattened grid with responsive columns */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-card-gap animate-fade-in animation-delay-100">
          {metrics.map((metric, index) => (
            <MetricCard
              key={metric.title}
              {...metric}
              index={index}
            />
          ))}
        </div>

        {/* Enhanced Start Tracking Section */}
        <SectionCard
          title="Start Tracking"
          description="Choose an exercise to begin a new session"
          icon={<Play className="size-5" />}
          className="animate-fade-in animation-delay-200"
          headerClassName="flex items-center justify-between"
          showDivider
        >
          <div className="flex justify-end mb-4">
            <Button 
              className="bg-brass-gold text-deep-ops shadow-small"
              onClick={() => navigate('/exercises')}
            >
              <Play className="mr-2 size-4" />
              START SESSION
            </Button>
          </div>
          
          <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
            {exerciseLinks.map((exercise) => (
              <QuickLinkCard
                key={exercise.name}
                title={exercise.name}
                icon={<img 
                  src={exercise.image} 
                  alt={exercise.name} 
                  className="h-10 w-auto object-contain" 
                />}
                onClick={() => navigate(exercise.path)}
                className="bg-cream p-4"
              />
            ))}
          </div>
        </SectionCard>

        {/* Progress Section with design-system styling */}
        <SectionCard
          title="Progress Summary"
          description="Your training overview at a glance"
          icon={<AreaChart className="size-5" />}
          className="animate-fade-in animation-delay-300"
          showDivider
        >
          {leaderboardError && (
            <Alert variant="default" className="mb-4 border-olive-mist bg-olive-mist bg-opacity-10">
              <AlertCircle className="size-5 text-tactical-gray" />
              <AlertTitle className="font-heading text-sm">Leaderboard data unavailable</AlertTitle>
              <AlertDescription className="text-tactical-gray">
                We're unable to load the leaderboard rankings right now. Your personal stats are still available.
              </AlertDescription>
            </Alert>
          )}

          <div className="grid grid-cols-1 gap-card-gap md:grid-cols-3">
            {progressMetrics.map((metric) => (
              <MetricCard
                key={metric.title}
                {...metric}
              />
            ))}
            <MetricCard
              title="GLOBAL LEADERBOARD RANK"
              value={rankDisplayValue}
              icon={Trophy}
              iconClassName="text-brass-gold"
              valueClassName="font-heading text-heading3 text-command-black"
              index={2}
            />
          </div>
          
          <div className="mt-6 flex justify-center">
            <Button 
              className="bg-brass-gold text-deep-ops shadow-medium"
              onClick={() => navigate('/history')}
            >
              <ArrowRight className="mr-2 size-4" />
              VIEW DETAILED PROGRESS
            </Button>
          </div>
        </SectionCard>

        {/* Recent Activity Section */}
        <SectionCard
          title="Recent Activity"
          description="Your latest workout sessions"
          icon={<CalendarClock className="size-5" />}
          className="animate-fade-in animation-delay-400"
          showDivider
        >
          {(exerciseHistory?.items?.length ?? 0) > 0 ? (
            <div className="divide-y divide-tactical-gray divide-opacity-20">
              {exerciseHistory?.items?.slice(0, 5).map((workout, index) => (
                <div 
                  key={workout.id || index} 
                  className="animate-slide-up flex items-center justify-between rounded-card px-2 py-3 transition-colors hover:bg-brass-gold hover:bg-opacity-5 focus-visible:outline-none focus-visible:ring-[var(--ring-focus)]"
                  onClick={() => navigate(`/history/${workout.id}`)}
                  tabIndex={0}
                  style={{ animationDelay: `${index * 100}ms` }}
                >
                  <div className="flex items-center">
                    <div className="mr-4 flex size-10 items-center justify-center rounded-full border border-brass-gold border-opacity-30 bg-brass-gold bg-opacity-10">
                      {workout.exercise_type === 'PUSHUP' && <img src={pushupImage} alt="Push-ups" className="size-6" />}
                      {workout.exercise_type === 'PULLUP' && <img src={pullupImage} alt="Pull-ups" className="size-6" />}
                      {workout.exercise_type === 'SITUP' && <img src={situpImage} alt="Sit-ups" className="size-6" />}
                      {workout.exercise_type === 'RUNNING' && <img src={runningImage} alt="Running" className="size-6" />}
                    </div>
                    <div>
                      <h3 className="mb-0 font-heading text-sm uppercase text-command-black">
                        {workout.exercise_type === 'PUSHUP' ? 'Push-ups' : 
                         workout.exercise_type === 'PULLUP' ? 'Pull-ups' :
                         workout.exercise_type === 'SITUP' ? 'Sit-ups' :
                         workout.exercise_type === 'RUNNING' ? 'Running' : 
                         workout.exercise_type}
                      </h3>
                      <p className="text-xs text-tactical-gray">
                        {new Date(workout.created_at).toLocaleDateString(undefined, {
                          month: 'short', 
                          day: 'numeric',
                          hour: 'numeric',
                          minute: '2-digit'
                        })}
                      </p>
                    </div>
                  </div>
                  <div className="flex-shrink-0 font-heading text-heading4 text-brass-gold">
                    {workout.exercise_type === 'RUNNING' 
                      ? `${((workout.distance || 0) / 1000).toFixed(2)} km` 
                      : `${workout.reps || 0}`}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center py-8 text-center">
              <div className="mb-4 rounded-full bg-brass-gold bg-opacity-10 p-4">
                <Flame className="size-8 text-brass-gold" />
              </div>
              <h3 className="mb-2 font-heading text-heading4">No Workouts Yet</h3>
              <p className="text-tactical-gray">
                Start your fitness journey by completing your first workout.
              </p>
              <Button
                variant="default"
                className="mt-4 bg-brass-gold text-deep-ops"
                onClick={() => navigate('/exercises')}
              >
                <Play className="mr-2 size-4" />
                Start First Workout
              </Button>
            </div>
          )}
        </SectionCard>
      </div>
    </div>
  );
}

export default Dashboard; 