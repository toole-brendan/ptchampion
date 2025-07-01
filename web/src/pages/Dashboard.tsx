import React, { useEffect, useState } from 'react';
import { 
  CalendarClock, 
  Flame,
  Route,
  Dumbbell,
  Repeat,
  Loader2,
  AlertCircle,
  ArrowRight,
  Play
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/lib/authContext';
import { useHeaderContext } from '@/dashboard-message-context';
import { useQuery } from '@tanstack/react-query';
import { useApi } from '@/lib/apiClient';
import { Alert, AlertTitle, AlertDescription } from "@/components/ui/alert";
import { Button } from '@/components/ui/button';

// Import new iOS-style components
import { PTChampionHeader } from '@/components/ui/pt-champion-header';
import { IOSSection } from '@/components/ui/ios-section';
import { IOSQuickLinkCard } from '@/components/ui/ios-quick-link-card';
import { ScoringRubricSection } from '@/components/ui/scoring-rubric-section';
import { UserProfileSection } from '@/components/ui/user-profile-section';

// Import the exercise PNG images with explicit paths to ensure they're found
import pushupImage from '../assets/pushup.png';
import pullupImage from '../assets/pullup.png';
import situpImage from '../assets/situp.png';
import runningImage from '../assets/running.png';

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
  
  // Fetch ALL run workouts to calculate accurate average
  const { 
    data: runHistory,
    isLoading: isRunHistoryLoading
  } = useQuery({
    queryKey: ['runHistory', user?.id],
    queryFn: async () => {
      // Fetch all pages to get complete run history
      const allRuns: any[] = [];
      let page = 1;
      let hasMore = true;
      
      while (hasMore) {
        const response = await api.exercises.getUserExercises(page, 50);
        
        // Debug logging
        if (page === 1) {
          console.log('First page items:', response.items.map(item => ({
            name: item.exercise_name,
            duration: item.duration_seconds
          })));
        }
        
        const runs = response.items.filter(item => {
          const name = item.exercise_name?.toLowerCase() || '';
          // Check for various running exercise names (case-insensitive)
          return name.includes('run') || name === 'running' || name.includes('mile');
        });
        allRuns.push(...runs);
        
        // Check if we have more pages
        hasMore = page * response.page_size < response.total_count;
        page++;
        
        // Safety limit to prevent infinite loops
        if (page > 20) break;
      }
      
      console.log('Total runs found:', allRuns.length);
      return allRuns;
    },
    enabled: !!user,
    staleTime: 1000 * 60 * 5, // 5 minutes
  });
  
  // Base loading state only on auth and history
  const isLoading = isAuthLoading || isHistoryLoading || isRunHistoryLoading;
  const error = authError || historyError;
  
  // Calculate dashboard metrics from history data
  const dashboardMetrics = React.useMemo(() => {
    if (!exerciseHistory || !exerciseHistory.items) {
      return {
        totalWorkouts: 0,
        lastWorkoutDate: null,
        lastWorkoutType: null,
        lastWorkoutMetric: null,
        totalReps: 0,
        averageRunTime: 0,
        recentWorkouts: []
      };
    }
    
    const items = exerciseHistory.items || [];
    const totalWorkouts = exerciseHistory.total_count || 0;
    const lastWorkout = items[0]; // Most recent workout
    
    // Calculate totals from recent workouts (for display)
    let totalReps = 0;
    
    items.forEach(workout => {
      // Use exercise_name since exercise_type is empty in the API response
      const exerciseName = workout.exercise_name?.toLowerCase() || '';
      // Check for various running exercise names (case-insensitive)
      if (!exerciseName.includes('run') && exerciseName !== 'running' && !exerciseName.includes('mile')) {
        totalReps += workout.reps || 0;
      }
    });
    
    // Calculate average run time from ALL runs (using runHistory)
    let averageRunTime = 0;
    if (runHistory && runHistory.length > 0) {
      const totalRunTime = runHistory.reduce((sum, run) => {
        return sum + (run.duration_seconds || 0);
      }, 0);
      averageRunTime = totalRunTime / runHistory.length;
      console.log('Average run time calculation:', {
        runCount: runHistory.length,
        totalTime: totalRunTime,
        average: averageRunTime
      });
    }
    
    return {
      totalWorkouts,
      lastWorkoutDate: lastWorkout ? new Date(lastWorkout.created_at) : null,
      lastWorkoutType: lastWorkout ? lastWorkout.exercise_name : null,
      lastWorkoutMetric: lastWorkout ? 
        (() => {
          const name = lastWorkout.exercise_name?.toLowerCase() || '';
          // Check for various running exercise names (case-insensitive)
          return (name.includes('run') || name === 'running' || name.includes('mile')) ? 
            `${Math.floor((lastWorkout.duration_seconds || 0) / 60)}:${String((lastWorkout.duration_seconds || 0) % 60).padStart(2, '0')}` : 
            `${lastWorkout.reps || 0} reps`;
        })()
        : null,
      totalReps,
      averageRunTime,
      recentWorkouts: items.slice(0, 5)
    };
  }, [exerciseHistory, runHistory, user]);
  
  // Set username in context when it changes
  useEffect(() => {
    if (user && setUserName) {
      // Use same logic as iOS: firstName → username → "User"
      const displayName = user.first_name || user.username || 'User';
      setUserName(displayName);
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

  // Format display name properly - same logic as iOS: firstName → username → "User"
  const formatDisplayName = () => {
    if (!user) return 'User';
    return user.first_name || user.username || 'User';
  };
  
  // Format the last workout date
  const formattedLastWorkoutDate = dashboardMetrics.lastWorkoutDate ? 
    dashboardMetrics.lastWorkoutDate.toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : 'Never';

  // Define exercise links for quick start
  const exerciseLinks = [
    { name: "PUSH-UPS", image: pushupImage, path: '/exercises/pushups' },
    { name: "PULL-UPS", image: pullupImage, path: '/exercises/pullups' },
    { name: "SIT-UPS", image: situpImage, path: '/exercises/situps' },
    { name: "TWO-MILE RUN", image: runningImage, path: '/exercises/running' },
  ];

  // Define rubric options
  const rubricOptions = [
    { title: "Push-Ups", onClick: () => navigate('/rubrics/pushups') },
    { title: "Sit-Ups", onClick: () => navigate('/rubrics/situps') },
    { title: "Pull-Ups", onClick: () => navigate('/rubrics/pullups') },
    { title: "Two-Mile Run", onClick: () => navigate('/rubrics/running') },
  ];

  // Define stats for user profile section
  const userStats = [
    {
      title: "TOTAL WORKOUTS",
      value: dashboardMetrics.totalWorkouts.toString(),
      icon: <Flame className="w-6 h-6" />,
      onPress: () => navigate('/history')
    },
    {
      title: "LAST ACTIVITY",
      value: dashboardMetrics.lastWorkoutType ? 
        (() => {
          const name = dashboardMetrics.lastWorkoutType.toLowerCase();
          return name === 'run' ? 'Two-Mile Run' : 
                 name === 'push-up' ? 'Push-ups' :
                 name === 'sit-up' ? 'Sit-ups' :
                 name === 'pull-up' ? 'Pull-ups' :
                 dashboardMetrics.lastWorkoutType;
        })() : 'None',
      subtitle: dashboardMetrics.lastWorkoutDate ? 
        (() => {
          const date = dashboardMetrics.lastWorkoutDate;
          const day = date.getDate();
          const month = date.toLocaleDateString('en-US', { month: 'short' }).toUpperCase();
          const year = date.getFullYear();
          return `${day}${month}${year} - ${dashboardMetrics.lastWorkoutMetric}`;
        })() : 
        'No workouts yet',
      icon: <CalendarClock className="w-6 h-6" />,
      onPress: () => dashboardMetrics.lastWorkoutDate && navigate('/history')
    },
    {
      title: "TOTAL REPETITIONS",
      value: `${dashboardMetrics.totalReps} reps`,
      icon: <Repeat className="w-6 h-6" />,
      onPress: () => navigate('/history')
    },
    {
      title: "AVERAGE RUN TIME",
      value: dashboardMetrics.averageRunTime > 0 ? 
        `${Math.floor(dashboardMetrics.averageRunTime / 60)}:${String(Math.round(dashboardMetrics.averageRunTime % 60)).padStart(2, '0')}` : 
        'No runs',
      icon: <Route className="w-6 h-6" />,
      onPress: () => navigate('/history')
    }
  ];

  return (
    <div className="bg-cream min-h-screen">
      {/* Radial gradient background matching iOS */}
      <div 
        className="min-h-screen"
        style={{
          background: `radial-gradient(circle at center, rgba(244, 241, 230, 0.9) 0%, rgba(244, 241, 230, 1) 60%)`
        }}
      >
        <div className="flex flex-col space-y-4 max-w-4xl mx-auto px-4 py-6">
          {/* PT Champion header with separator */}
          <PTChampionHeader />

          {/* Quick Links Section (Start Tracking) */}
          <IOSSection
            title="Start Tracking"
            description="Choose an exercise to begin a new session"
          >
            <div className="grid grid-cols-2 gap-4">
              {exerciseLinks.map((exercise) => (
                <IOSQuickLinkCard
                  key={exercise.name}
                  title={exercise.name}
                  icon={<img 
                    src={exercise.image} 
                    alt={exercise.name} 
                    className="h-10 w-auto object-contain" 
                  />}
                  onPress={() => navigate(exercise.path)}
                />
              ))}
            </div>
          </IOSSection>

          {/* Scoring Rubric Section */}
          <ScoringRubricSection rubricOptions={rubricOptions} />

          {/* User Profile Section */}
          <UserProfileSection
            userName={formatDisplayName()}
            totalWorkouts={dashboardMetrics.totalWorkouts}
            stats={userStats}
            onViewProfile={() => navigate('/profile')}
          />

          {/* Recent Activity Section */}
          <IOSSection
            title="Recent Activity"
            description="Your latest workout sessions"
            contentClassName="p-0 bg-white"
          >
            {dashboardMetrics.recentWorkouts.length > 0 ? (
              <div className="space-y-0">
                {dashboardMetrics.recentWorkouts.map((workout, index) => {
                  // Use exercise_name since exercise_type is empty in API
                  const exerciseName = workout.exercise_name?.toLowerCase() || '';
                  
                  return (
                  <div key={workout.id || index}>
                    <button
                      className="flex items-center justify-between w-full py-3 px-4 hover:bg-black hover:bg-opacity-5 transition-colors duration-150 bg-white"
                      onClick={() => navigate(`/history/${workout.id}`)}
                    >
                      <div className="flex items-center space-x-4">
                        {/* Exercise icon without background circle to match style */}
                        <div className="flex-shrink-0">
                          <img 
                            src={
                              exerciseName === 'push-up' ? pushupImage :
                              exerciseName === 'pull-up' ? pullupImage :
                              exerciseName === 'sit-up' ? situpImage :
                              exerciseName === 'run' ? runningImage :
                              pushupImage
                            }
                            alt={workout.exercise_name || 'Exercise'}
                            className="w-11 h-11 object-contain"
                          />
                        </div>
                        <div className="flex-1 text-left">
                          <h3 className="text-base font-semibold text-command-black">
                            {workout.exercise_name || 'Unknown Exercise'}
                          </h3>
                          <p className="text-sm text-gray-600">
                            {(() => {
                              const date = new Date(workout.created_at);
                              const day = date.getDate();
                              const month = date.toLocaleDateString('en-US', { month: 'short' }).toUpperCase();
                              const year = date.getFullYear();
                              return `${day}${month}${year}`;
                            })()}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-baseline space-x-1">
                        <span className="text-xl font-bold text-command-black font-mono">
                          {exerciseName === 'run'
                            ? (workout.duration_seconds 
                                ? `${Math.floor(workout.duration_seconds / 60)}:${String(workout.duration_seconds % 60).padStart(2, '0')}`
                                : '--')
                            : workout.reps || '--'}
                        </span>
                        <span className="text-sm text-gray-600">
                          {exerciseName === 'run' ? '' : 'reps'}
                        </span>
                      </div>
                    </button>
                    {index < dashboardMetrics.recentWorkouts.length - 1 && (
                      <div className="h-px bg-gray-200 mx-4"></div>
                    )}
                  </div>
                  );
                })}
                
                {/* View All button */}
                <button
                  className="flex items-center justify-center w-full py-3 bg-brass-gold bg-opacity-10 hover:bg-opacity-15 transition-colors duration-150"
                  onClick={() => navigate('/history')}
                >
                  <span className="font-semibold text-sm text-deep-ops mr-2">
                    VIEW DETAILED HISTORY
                  </span>
                  <ArrowRight className="w-3 h-3 text-deep-ops" />
                </button>
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center py-10 text-center bg-white">
                <div className="mb-4 rounded-full bg-brass-gold bg-opacity-10 p-4">
                  <Flame className="w-8 h-8 text-brass-gold" />
                </div>
                <h3 className="mb-2 font-heading text-xl font-bold text-deep-ops">No Workouts Yet</h3>
                <p className="text-tactical-gray mb-4">
                  Start your fitness journey by completing your first workout.
                </p>
                <Button
                  className="bg-brass-gold text-deep-ops hover:bg-brass-gold hover:bg-opacity-90"
                  onClick={() => navigate('/exercises')}
                >
                  <Play className="mr-2 w-4 h-4" />
                  Start First Workout
                </Button>
              </div>
            )}
          </IOSSection>
        </div>
      </div>
    </div>
  );
}

export default Dashboard; 