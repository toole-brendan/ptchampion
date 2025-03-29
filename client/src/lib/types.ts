// Interface definitions matching the backend API types

// Auth types
export interface RegisterUserRequest {
  username: string;
  password: string;
  display_name?: string;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  user: UserResponse;
}

// User types
export interface UserResponse {
  id: number;
  username: string;
  display_name?: string;
  profile_picture_url?: string;
  location?: string;
  created_at: string;
  updated_at: string;
}

export interface UpdateUserRequest {
  username?: string;
  display_name?: string;
  profile_picture_url?: string;
  location?: string;
  latitude?: number;
  longitude?: number;
}

// Exercise types
export interface LogExerciseRequest {
  exercise_id: number;
  reps?: number;
  duration?: number; // in seconds
  distance?: number; // in meters
  notes?: string;
}

export interface ExerciseResponse {
  id: number;
  user_id: number;
  exercise_id: number;
  exercise_name: string;
  exercise_type: string;
  reps?: number;
  time_in_seconds?: number;
  distance?: number;
  notes?: string;
  grade: number;
  created_at: string;
}

// Leaderboard types
export interface LeaderboardEntry {
  user_id: number;
  username: string;
  display_name?: string;
  profile_picture_url?: string;
  max_grade: number;
  last_attempt_date: string;
}

// Auth state management
export interface AuthState {
  isAuthenticated: boolean;
  user: UserResponse | null;
  token: string | null;
  loading: boolean;
  error: string | null;
} 