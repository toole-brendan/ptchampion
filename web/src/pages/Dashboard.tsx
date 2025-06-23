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
  
  // Base loading state only on auth and history
  const isLoading = isAuthLoading || isHistoryLoading;
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
        totalDistance: 0,
        recentWorkouts: []
      };
    }
    
    const items = exerciseHistory.items || [];
    const totalWorkouts = exerciseHistory.total_count || 0;
    const lastWorkout = items[0]; // Most recent workout
    
    // Calculate totals
    let totalReps = 0;
    let totalDistance = 0;
    
    items.forEach(workout => {
      if (workout.exercise_type === 'RUNNING') {
        totalDistance += workout.distance || 0;
      } else {
        totalReps += workout.reps || 0;
      }
    });
    
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
      recentWorkouts: items.slice(0, 5)
    };
  }, [exerciseHistory, user]);
  
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
        (dashboardMetrics.lastWorkoutType === 'RUNNING' ? 'Two-Mile Run' : 
         dashboardMetrics.lastWorkoutType === 'PUSHUP' ? 'Push-ups' :
         dashboardMetrics.lastWorkoutType === 'SITUP' ? 'Sit-ups' :
         dashboardMetrics.lastWorkoutType === 'PULLUP' ? 'Pull-ups' :
         dashboardMetrics.lastWorkoutType) : 'None',
      subtitle: dashboardMetrics.lastWorkoutDate ? 
        `${formattedLastWorkoutDate} - ${dashboardMetrics.lastWorkoutMetric}` : 
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
      title: "TOTAL DISTANCE",
      value: `${(dashboardMetrics.totalDistance / 1000).toFixed(1)} km`,
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
                {dashboardMetrics.recentWorkouts.map((workout, index) => (
                  <div key={workout.id || index}>
                    <button
                      className="flex items-center justify-between w-full py-3 px-4 hover:bg-black hover:bg-opacity-5 transition-colors duration-150 bg-white"
                      onClick={() => navigate(`/history/${workout.id}`)}
                    >
                      <div className="flex items-center">
                        <div className="mr-4 flex w-10 h-10 items-center justify-center rounded-full bg-brass-gold bg-opacity-10">
                          {workout.exercise_type && (
                            workout.exercise_type.toUpperCase().includes('PUSH') ? 
                              <img src={pushupImage} alt="Push-ups" className="w-5 h-5" /> :
                            workout.exercise_type.toUpperCase().includes('PULL') ? 
                              <img src={pullupImage} alt="Pull-ups" className="w-5 h-5" /> :
                            workout.exercise_type.toUpperCase().includes('SIT') ? 
                              <img src={situpImage} alt="Sit-ups" className="w-5 h-5" /> :
                            workout.exercise_type.toUpperCase().includes('RUN') ? 
                              <img src={runningImage} alt="Running" className="w-5 h-5" /> :
                              <Dumbbell className="w-5 h-5 text-brass-gold" />
                          )}
                        </div>
                        <div className="text-left">
                          <h3 className="font-medium text-base text-deep-ops">
                            {workout.exercise_type ? (
                              workout.exercise_type.toUpperCase().includes('PUSH') ? 'Push-ups' : 
                              workout.exercise_type.toUpperCase().includes('PULL') ? 'Pull-ups' :
                              workout.exercise_type.toUpperCase().includes('SIT') ? 'Sit-ups' :
                              workout.exercise_type.toUpperCase().includes('RUN') ? 'Two-Mile Run' : 
                              workout.exercise_type
                            ) : 'Unknown Exercise'}
                          </h3>
                          <p className="text-sm text-tactical-gray">
                            {new Date(workout.created_at).toLocaleDateString(undefined, {
                              month: 'short', 
                              day: 'numeric'
                            })}
                          </p>
                        </div>
                      </div>
                      <div className="font-heading text-lg font-bold text-brass-gold">
                        {workout.exercise_type && workout.exercise_type.toUpperCase().includes('RUN') 
                          ? `${((workout.distance || 0) / 1000).toFixed(1)} km` 
                          : `${workout.reps || 0} reps`}
                      </div>
                    </button>
                    {index < dashboardMetrics.recentWorkouts.length - 1 && (
                      <div className="h-px bg-gray-200 mx-4"></div>
                    )}
                  </div>
                ))}
                
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