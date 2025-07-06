import { useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/services/api';
import { WorkoutRequest } from '@/types/api';
import { logger } from '@/lib/logger';

interface WorkoutMutationContext {
  previousData?: any;
}

export function useOptimisticWorkout() {
  const queryClient = useQueryClient();

  return useMutation<any, Error, WorkoutRequest, WorkoutMutationContext>({
    mutationFn: (workout: WorkoutRequest) => api.workouts.create(workout),
    
    // Optimistically update the cache before the request completes
    onMutate: async (newWorkout) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['exerciseHistory'] });
      await queryClient.cancelQueries({ queryKey: ['dashboardStats'] });

      // Snapshot the previous values
      const previousHistory = queryClient.getQueryData(['exerciseHistory']);
      const previousStats = queryClient.getQueryData(['dashboardStats']);

      // Create optimistic workout data
      const optimisticWorkout = {
        id: Date.now(), // Temporary ID
        exercise_name: newWorkout.exercise_type,
        exercise_type: newWorkout.exercise_type,
        reps: newWorkout.repetitions,
        time_in_seconds: newWorkout.duration_seconds,
        grade: newWorkout.grade,
        form_score: newWorkout.form_score,
        created_at: newWorkout.completed_at,
        _optimistic: true, // Flag for optimistic data
      };

      // Optimistically update exercise history
      queryClient.setQueryData(['exerciseHistory'], (old: any) => {
        if (!old) return old;
        return {
          ...old,
          items: [optimisticWorkout, ...(old.items || [])],
          total_count: (old.total_count || 0) + 1,
        };
      });

      // Optimistically update dashboard stats
      queryClient.setQueryData(['dashboardStats'], (old: any) => {
        if (!old) return old;
        return {
          ...old,
          totalWorkouts: (old.totalWorkouts || 0) + 1,
          totalReps: (old.totalReps || 0) + (newWorkout.repetitions || 0),
          recentWorkouts: [
            {
              id: Date.now(),
              exerciseName: newWorkout.exercise_type,
              reps: newWorkout.repetitions || 0,
              duration: newWorkout.duration_seconds || 0,
              score: newWorkout.grade || 0,
              createdAt: newWorkout.completed_at,
            },
            ...(old.recentWorkouts || []).slice(0, 4), // Keep only 5 recent
          ],
          lastWorkoutDate: newWorkout.completed_at,
          exerciseCounts: {
            ...old.exerciseCounts,
            [newWorkout.exercise_type]: (old.exerciseCounts?.[newWorkout.exercise_type] || 0) + 1,
          },
        };
      });

      // Return context with previous data for rollback
      return { previousData: { history: previousHistory, stats: previousStats } };
    },

    // On error, roll back to the previous values
    onError: (err, newWorkout, context) => {
      logger.error('Failed to save workout:', err);
      
      if (context?.previousData) {
        queryClient.setQueryData(['exerciseHistory'], context.previousData.history);
        queryClient.setQueryData(['dashboardStats'], context.previousData.stats);
      }
    },

    // After success or error, sync with server data
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['exerciseHistory'] });
      queryClient.invalidateQueries({ queryKey: ['dashboardStats'] });
    },
  });
}