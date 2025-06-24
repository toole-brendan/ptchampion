import { WorkoutRequest } from '../types/api';
import { apiRequest, getApiBaseUrl } from '../lib/apiClient';

// Define the backend workout response format
interface BackendWorkoutResponse {
  id: number;
  user_id: number;
  exercise_id: number;
  exercise_name: string;
  exercise_type: string;
  reps?: number;
  duration_seconds?: number;
  form_score?: number;
  grade: number;
  completed_at: string;
  created_at: string;
}

// Map frontend workout format to backend format
const transformWorkoutRequest = (workout: WorkoutRequest): any => {
  // Map exercise type to exercise ID (based on backend constants)
  const exerciseTypeToId: Record<string, number> = {
    'pushup': 1,
    'situp': 2,
    'pullup': 3,
    'run': 4
  };

  return {
    exercise_id: exerciseTypeToId[workout.exercise_type] || 1,
    reps: workout.repetitions,
    duration_seconds: workout.duration_seconds,
    form_score: workout.form_score,
    completed_at: workout.completed_at,
    // Note: grade is calculated server-side based on reps/duration
    // is_public is stored separately or as part of user preferences
  };
};

export const api = {
  workouts: {
    create: async (workout: WorkoutRequest): Promise<BackendWorkoutResponse> => {
      const transformedData = transformWorkoutRequest(workout);
      return apiRequest<BackendWorkoutResponse>('/workouts', 'POST', transformedData, true);
    },
    
    getRecent: async (limit: number = 10): Promise<BackendWorkoutResponse[]> => {
      // Get recent workouts for duplicate checking
      const response = await apiRequest<{
        items: BackendWorkoutResponse[];
        totalCount: number;
      }>(`/workouts?page=1&pageSize=${limit}`, 'GET', null, true);
      
      return response.items;
    }
  }
};