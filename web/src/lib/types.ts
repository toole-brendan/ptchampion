// Interface definitions matching the backend API types

// Auth types
export interface RegisterUserRequest {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  username?: string;
  gender?: string; // 'male' or 'female'
  dateOfBirth?: string; // Format: YYYY-MM-DD
}

export interface LoginRequest {
  email: string;
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
  first_name?: string;
  last_name?: string;
  email?: string;
  profile_picture_url?: string;
  gender?: string; // 'male' or 'female'
  date_of_birth?: string; // Format: YYYY-MM-DD
  last_synced_at?: string;
  created_at: string;
  updated_at: string;
}

export interface UpdateUserRequest {
  username?: string;
  first_name?: string;
  last_name?: string;
  email?: string;
  password?: string;
  profile_picture_url?: string;
  gender?: string; // 'male' or 'female'
  date_of_birth?: string; // Format: YYYY-MM-DD
}

// Exercise types
export interface LogExerciseRequest {
  exercise_id: number;
  reps?: number;
  duration?: number; // Frontend might send duration, backend uses time_in_seconds
  distance?: number;
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
  grade?: number;
  created_at: string; // Assuming ISO string format
}

// Leaderboard types
export interface LeaderboardEntry {
  user_id: number;
  username: string;
  first_name?: string;
  last_name?: string;
  display_name?: string;
  profile_picture_url?: string;
  max_grade: number;
  last_attempt_date: string; // Assuming ISO string format
}

// Add the new paginated response type
export interface PaginatedExercisesResponse {
  items: ExerciseResponse[];
  total_count: number;
  page: number;
  page_size: number;
}

// Workout types (for new client-side grading)
export interface WorkoutRequest {
  exercise_type: 'pushup' | 'situp' | 'pullup' | 'run';
  repetitions?: number;      // For rep-based exercises
  duration_seconds?: number;  // For time-based exercises
  grade: number;             // APFT score (0-100)
  form_score?: number;       // Average form quality (0-100)
  completed_at: string;      // ISO timestamp
  is_public: boolean;        // For leaderboard
}

// Auth state management
export interface AuthState {
  isAuthenticated: boolean;
  user: UserResponse | null;
  token: string | null;
  loading: boolean;
  error: string | null;
}

/**
 * MediaPipe Normalized Landmark
 * Representation of a point in 3D space with visibility
 */
export interface NormalizedLandmark {
  x: number;
  y: number;
  z: number;
  visibility?: number;
}

/**
 * Exercise calibration data
 */
export interface CalibrationData {
  poseLandmarks: NormalizedLandmark[];
  poseWorldLandmarks: NormalizedLandmark[];
  timestamp: number;
  exerciseType: 'pushup' | 'situp' | 'pullup' | 'running';
}

/**
 * Basic form analysis components that all exercise analyzers share
 */
export interface BaseFormAnalysis {
  isUpPosition: boolean;
  isDownPosition: boolean;
  repProgress: number;
  isValidRep: boolean;
  timestamp: number;
}

// Note: HolisticResults and HolisticConfig interfaces have been removed
// as we're now using the PoseDetector service with the BlazePose model 

// Authentication types
export interface SocialSignInRequest {
  provider: 'google' | 'apple';
  token: string;
  code?: string; // For Apple authorization code
} 