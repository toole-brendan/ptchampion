import React from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { Dumbbell, Activity, Zap, TrendingUp, PersonStanding, Clock, Repeat, Trophy, ArrowRight, Loader2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/lib/authContext'; // Import useAuth
// import { useQuery } from '@tanstack/react-query'; // Uncomment if fetching dashboard data
// import { getDashboardSummary } from '@/lib/apiClient'; // Uncomment if fetching dashboard data
import { cn } from "@/lib/utils";

// Define exercise types for quick start
const exercises = [
  { name: "Push-ups", icon: Activity, path: '/exercises/pushup' },
  { name: "Sit-ups", icon: Zap, path: '/exercises/situp' },
  { name: "Pull-ups", icon: PersonStanding, path: '/exercises/pullup' },
  { name: "Running", icon: TrendingUp, path: '/exercises/run' },
];

// Placeholder function for dashboard data fetching (replace with actual API call and useQuery)
// const useDashboardData = () => {
//   return useQuery({ 
//     queryKey: ['dashboardSummary'], 
//     queryFn: getDashboardSummary, // Assume getDashboardSummary exists in apiClient
//     staleTime: 1000 * 60 * 5, // 5 minutes 
//   });
// };

const Dashboard: React.FC = () => {
  const navigate = useNavigate();
  const { user, isLoading: isAuthLoading, error: authError } = useAuth(); // Get user, loading, and error state

  // Placeholder for dashboard-specific data loading
  // const { data: summaryData, isLoading: isSummaryLoading, error: summaryError } = useDashboardData();
  const isLoading = isAuthLoading; // || isSummaryLoading; // Combine loading states if fetching summary
  
  // Use the error state directly from useAuth (or combine if summaryError exists)
  const error = authError; // || summaryError?.message;

  // --- MOCK DATA (Remove when summaryData is available) ---
  const lastWorkout = {
    exercise: 'Push-ups',
    date: '2024-07-28',
    metric: '35 reps'
  };
  const performanceStats = {
    totalWorkouts: 5,
    bestPushups: 35
  };
  const leaderboardRank = 3;
  // --- END MOCK DATA ---

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (error) {
    // Display the error string directly from the context
    return <div className="text-destructive p-4 border border-destructive rounded-md">Error: {error}</div>;
  }

  // Get user name (fallback to username if display name isn't set)
  const userName = user?.display_name || user?.username || 'User';

  return (
    <div className="space-y-6">
      {/* Welcome Message */}
      <h1 className="text-2xl font-semibold text-foreground">Welcome back, <span className="text-primary font-semibold">{userName}</span>!</h1>

      {/* Start Workout Section */}
      <Card className="transition-shadow hover:shadow-md">
        <CardHeader>
          <CardTitle className="text-lg font-semibold flex items-center">
            <Dumbbell className="h-5 w-5 mr-2 text-muted-foreground" />
            Start New Workout
          </CardTitle>
          <CardDescription>Choose an exercise to begin tracking.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-3">
            {exercises.map((exercise) => (
              <Button
                key={exercise.name}
                variant="outline"
                className={cn(
                  "flex flex-col items-center justify-center h-24 p-4 space-y-2 text-center",
                  "transition-colors hover:bg-muted/50 hover:border-border focus:ring-primary/50"
                )}
                onClick={() => navigate(exercise.path)}
              >
                <exercise.icon className="h-6 w-6 text-primary" />
                <span className="text-sm font-medium text-foreground">{exercise.name}</span>
              </Button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Row for Summary Cards - Use summaryData when available */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {[
          {
            title: 'Last Workout',
            icon: Clock,
            // value: summaryData?.lastWorkout?.exercise || 'N/A',
            // description: summaryData?.lastWorkout ? `On ${summaryData.lastWorkout.date} - ${summaryData.lastWorkout.metric}` : 'Log your first workout!',
            value: lastWorkout.exercise, // MOCK
            description: `On ${lastWorkout.date} - ${lastWorkout.metric}`, // MOCK
            link: '/history',
            linkText: 'View History'
          },
          {
            title: 'Performance Snapshot',
            icon: Repeat,
            // value: `${summaryData?.performanceStats?.totalWorkouts || 0} Workouts`,
            // description: `Push-up PB: ${summaryData?.performanceStats?.bestPushups || 0} reps`,
            value: `${performanceStats.totalWorkouts} Workouts`, // MOCK
            description: `Push-up PB: ${performanceStats.bestPushups} reps`, // MOCK
            link: '/history',
            linkText: 'Full Analytics'
          },
          {
            title: 'Leaderboard Rank',
            icon: Trophy,
            // value: summaryData?.leaderboardRank ? `Rank #${summaryData.leaderboardRank}` : 'Unranked',
            value: `Rank #${leaderboardRank}`, // MOCK
            description: 'Overall global standing',
            link: '/leaderboard',
            linkText: 'View Leaderboard'
          }
        ].map((card, index) => (
          <Card key={index} className="transition-shadow hover:shadow-md">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">{card.title}</CardTitle>
              <card.icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold text-foreground mb-1">{card.value}</p>
              <p className="text-xs text-muted-foreground">{card.description}</p>
              <Button variant="link" size="sm" className="px-0 h-auto mt-2 text-primary hover:text-primary/80" onClick={() => navigate(card.link)}>
                {card.linkText} <ArrowRight className="ml-1 h-3 w-3" />
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
};

export default Dashboard; 