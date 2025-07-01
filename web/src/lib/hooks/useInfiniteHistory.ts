import { useMemo } from 'react';
import { useInfiniteQuery } from '@tanstack/react-query';
import { getUserExercises } from '../apiClient';
import { ExerciseResponse, PaginatedExercisesResponse } from '../types';
import { DateRange } from '@/components/workout-history/HistoryFilterBar';

interface InfiniteHistoryParams {
  pageSize?: number;
  exerciseFilter?: string;
  dateRange?: DateRange;
}

export const useInfiniteHistory = ({
  pageSize = 20,
  exerciseFilter = 'All',
  dateRange
}: InfiniteHistoryParams = {}) => {
  // Fetch workout history with infinite pagination
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    status,
    error,
    refetch
  } = useInfiniteQuery<PaginatedExercisesResponse>({
    queryKey: ['infiniteHistory', { pageSize, exerciseFilter, dateRange }],
    queryFn: ({ pageParam }) => {
      return getUserExercises(pageParam as number, pageSize);
    },
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      const nextPage = lastPage.page + 1;
      const hasMore = lastPage.page * lastPage.page_size < lastPage.total_count;
      return hasMore ? nextPage : undefined;
    },
    staleTime: 1000 * 60, // 1 minute
  });

  // Flatten all pages into a single array of workout items
  const historyItems = useMemo(() => {
    if (!data) return [];
    return data.pages.flatMap(page => page.items);
  }, [data]);

  // Apply exercise type filter (client-side)
  const filteredItems = useMemo(() => {
    console.log('[useInfiniteHistory] Filtering with:', {
      exerciseFilter,
      totalItems: historyItems.length,
      version: 'v9-HISTORY-FIXES'
    });

    if (exerciseFilter === 'All') {
      return historyItems;
    }
    
    // Map filter values to exercise names as they appear in the API
    const filterMap: Record<string, string[]> = {
      'pushup': ['push-up', 'push up', 'pushup'],
      'situp': ['sit-up', 'sit up', 'situp'],
      'pullup': ['pull-up', 'pull up', 'pullup'],
      'run': ['run', 'running', 'two-mile run', '2-mile run']
    };
    
    const acceptableNames = filterMap[exerciseFilter] || [exerciseFilter];
    
    const filtered = historyItems.filter(item => {
      // Use exercise_name since exercise_type is empty in API response
      const exerciseName = item.exercise_name?.toLowerCase() || '';
      return acceptableNames.some(name => exerciseName.includes(name));
    });

    console.log('[useInfiniteHistory] Filter results:', {
      exerciseFilter,
      acceptableNames,
      filteredCount: filtered.length,
      sampleItem: historyItems[0] ? {
        exercise_name: historyItems[0].exercise_name,
        exercise_type: historyItems[0].exercise_type
      } : 'no items'
    });

    return filtered;
  }, [historyItems, exerciseFilter]);

  // Apply date range filter (client-side)
  const dateFilteredItems = useMemo(() => {
    if (!dateRange?.from) {
      return filteredItems;
    }
    return filteredItems.filter((workout) => {
      try {
        const workoutDate = new Date(workout.created_at);
        const from = dateRange.from;
        const to = dateRange.to || new Date();
        const startOfDayFrom = new Date(from);
        startOfDayFrom.setHours(0, 0, 0, 0);
        const endOfDayTo = new Date(to);
        endOfDayTo.setHours(23, 59, 59, 999);
        
        return workoutDate >= startOfDayFrom && workoutDate <= endOfDayTo;
      } catch (e) {
        console.error("Error parsing date:", workout.created_at, e);
        return false;
      }
    });
  }, [filteredItems, dateRange]);

  // Calculate streak (consecutive days with workouts)
  const streakCount = useMemo(() => {
    if (historyItems.length === 0) return 0;
    
    // Sort workouts by date (newest first)
    const sortedWorkouts = [...historyItems].sort(
      (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );
    
    let currentStreak = 1;
    let currentDate = new Date(sortedWorkouts[0].created_at);
    currentDate.setHours(0, 0, 0, 0); // Normalize to start of day
    
    // Traverse through dates, looking for consecutive days
    for (let i = 1; i < sortedWorkouts.length; i++) {
      const workoutDate = new Date(sortedWorkouts[i].created_at);
      workoutDate.setHours(0, 0, 0, 0);
      
      // Calculate difference in days
      const timeDiff = currentDate.getTime() - workoutDate.getTime();
      const dayDiff = Math.floor(timeDiff / (1000 * 60 * 60 * 24));
      
      if (dayDiff === 1) {
        // Consecutive day
        currentStreak++;
        currentDate = workoutDate;
      } else if (dayDiff === 0) {
        // Same day, continue checking
        continue;
      } else {
        // Streak broken
        break;
      }
    }
    
    return currentStreak;
  }, [historyItems]);

  // Calculate summary stats from filtered items
  const summaryStats = useMemo(() => {
    const totalWorkouts = dateFilteredItems.length;
    let totalReps = 0;
    let totalSeconds = 0;
    let totalDistance = 0;

    dateFilteredItems.forEach((workout) => {
      if (workout.reps) {
        totalReps += workout.reps;
      }
      
      if (workout.time_in_seconds) {
        totalSeconds += workout.time_in_seconds;
      }
      
      if (workout.distance) {
        totalDistance += workout.distance / 1000; // Convert to km
      }
    });

    return {
      totalWorkouts,
      totalReps,
      totalSeconds,
      totalDistance: totalDistance.toFixed(1)
    };
  }, [dateFilteredItems]);

  // Track personal bests for each exercise type
  const personalBests = useMemo(() => {
    const bests: Record<string, ExerciseResponse> = {};
    
    dateFilteredItems.forEach((workout) => {
      // Use exercise_name since exercise_type is empty in API response
      const exerciseName = workout.exercise_name || workout.exercise_type || '';
      const exerciseLower = exerciseName.toLowerCase();
      const isRunning = exerciseLower.includes('run');
      
      // For running, compare distance (higher is better)
      if (isRunning && workout.distance) {
        if (!bests[exerciseName] || (bests[exerciseName].distance || 0) < workout.distance) {
          bests[exerciseName] = workout;
        }
      } 
      // For everything else, compare reps (higher is better)
      else if (workout.reps) {
        if (!bests[exerciseName] || (bests[exerciseName].reps || 0) < workout.reps) {
          bests[exerciseName] = workout;
        }
      }
    });
    
    return Object.values(bests);
  }, [dateFilteredItems]);

  return {
    historyItems: dateFilteredItems,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    status,
    error,
    refetch,
    summaryStats,
    streakCount,
    personalBests
  };
};

export default useInfiniteHistory; 