import { 
  LoginRequest, 
  RegisterUserRequest, 
  UpdateUserRequest, 
  LogExerciseRequest,
  LoginResponse,
  UserResponse,
  ExerciseResponse,
  LeaderboardEntry 
} from './types';
import config from './config';
import { secureGet, secureSet, secureRemove } from './secureStorage';
// Import the dev mock token constant
import { DEV_MOCK_TOKEN } from '../components/ui/DeveloperMenu';
import { logger } from './logger';

// Get the configured API base URL
const getApiBaseUrl = (): string => config.api.baseUrl; // Example: "http://localhost:8080/api/v1"

// Token storage key
const TOKEN_STORAGE_KEY = config.auth.storageKeys.token;
const USER_STORAGE_KEY = config.auth.storageKeys.user;

// Helper function to get the JWT token from storage
// This is now an async function that uses secure storage
const getToken = async (): Promise<string | null> => {
  try {
    // First try to get token from secureGet
    const token = await secureGet(TOKEN_STORAGE_KEY);
    if (token) {
      logger.debug('getToken (async) called, token exists from secureGet');
      return token;
    }
    
    // Fall back to regular localStorage if secure get failed
    const plainToken = localStorage.getItem(TOKEN_STORAGE_KEY);
    if (plainToken) {
      logger.debug('getToken (async) called, token exists from localStorage');
      return plainToken;
    }
    
    logger.debug('getToken (async) called, no token found');
    return null;
  } catch (error) {
    // If secure decryption fails, try regular localStorage
    logger.error('Error in secure token retrieval:', error);
    const plainToken = localStorage.getItem(TOKEN_STORAGE_KEY);
    if (plainToken) {
      logger.debug('getToken (async) falling back to localStorage token');
      return plainToken;
    }
    return null;
  }
};

// Add type for the paginated response
export interface PaginatedExercisesResponse {
  items: ExerciseResponse[];
  total_count: number;
  page: number;
  page_size: number;
}

// Add this function near the top of your file, before any API calls
const handleApiError = (error: unknown) => {
  logger.error('API Error:', error);
  
  if (error instanceof Error) {
    return error;
  }
  
  if (typeof error === 'string') {
    return new Error(error);
  }
  
  return new Error('An unknown error occurred');
};

/**
 * Helper function for making API requests.
 * Handles adding base URL, Content-Type, and Authorization header.
 * Error handling: Throws an error with backend message if response is not OK.
 *
 * @param endpoint API endpoint (e.g., '/users/login')
 * @param method HTTP method
 * @param body Request body (optional)
 * @param requiresAuth Whether authentication is required (adds Bearer token)
 * @returns Promise with the parsed JSON response data
 */
const apiRequest = async <T>(
  endpoint: string,
  method: string,
  body?: unknown, // Use unknown for stricter type checking
  requiresAuth: boolean = false
): Promise<T> => {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    'Accept': 'application/json', // Ensure we expect JSON back
  };

  if (requiresAuth) {
    const token = await getToken();
    
    // Special handling for dev mock token
    if (token === DEV_MOCK_TOKEN) {
      logger.debug('Using dev mock token, bypassing actual API call');
      
      // Handle specific endpoints with mock data
      if (endpoint === '/users/me') {
        // Get mock user from localStorage
        try {
          const mockUserStr = localStorage.getItem(USER_STORAGE_KEY);
          if (mockUserStr) {
            const mockUser = JSON.parse(mockUserStr);
            logger.debug('Returning mock user:', { id: mockUser.id, username: mockUser.username });
            return mockUser as T;
          }
        } catch (e) {
          logger.error('Error parsing mock user:', e);
        }
        
        // Fallback mock user if none in localStorage
        const fallbackUser: UserResponse = {
          id: 9999,
          username: 'devuser',
          first_name: 'Developer',
          last_name: 'User',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        };
        return fallbackUser as T;
      }
      
      // Mock response for exercises endpoint
      if (endpoint.startsWith('/exercises')) {
        if (method === 'POST') {
          // Mock exercise logging
          const mockExercise: ExerciseResponse = {
            id: 9999,
            user_id: 9999,
            exercise_id: (body as LogExerciseRequest)?.exercise_id || 1,
            exercise_name: 'Mock Exercise',
            exercise_type: 'pushup',
            reps: (body as LogExerciseRequest)?.reps || 0,
            time_in_seconds: (body as LogExerciseRequest)?.duration || 0,
            notes: (body as LogExerciseRequest)?.notes || '',
            created_at: new Date().toISOString(),
            grade: 90,
          };
          logger.debug('Returning mock exercise:', { id: mockExercise.id, exercise_name: mockExercise.exercise_name });
          return mockExercise as T;
        } else if (method === 'GET') {
          // Return mock exercise list
          const mockExercises: PaginatedExercisesResponse = {
            items: [
              {
                id: 9001,
                user_id: 9999,
                exercise_id: 1,
                exercise_name: 'Push-ups',
                exercise_type: 'pushup',
                reps: 20,
                time_in_seconds: 60,
                notes: 'Mock exercise 1',
                created_at: new Date().toISOString(),
                grade: 95,
              },
              {
                id: 9002,
                user_id: 9999,
                exercise_id: 2,
                exercise_name: 'Pull-ups',
                exercise_type: 'pullup',
                reps: 15,
                time_in_seconds: 45,
                notes: 'Mock exercise 2',
                created_at: new Date().toISOString(),
                grade: 85,
              }
            ],
            total_count: 2,
            page: 1,
            page_size: 10
          };
          logger.debug('Returning mock exercises:', { count: mockExercises.items.length });
          return mockExercises as T;
        }
      }
      
      // Mock leaderboard data
      if (endpoint.startsWith('/leaderboard')) {
        const mockLeaderboard: LeaderboardEntry[] = [
          {
            user_id: 9999,
            username: 'devuser',
            first_name: 'Developer',
            last_name: 'User',
            max_grade: 100,
            last_attempt_date: new Date().toISOString(),
          },
          {
            user_id: 9998,
            username: 'user2',
            first_name: 'Mock',
            last_name: 'User 2',
            max_grade: 90,
            last_attempt_date: new Date().toISOString(),
          },
          {
            user_id: 9997,
            username: 'user3',
            first_name: 'Mock',
            last_name: 'User 3',
            max_grade: 80,
            last_attempt_date: new Date().toISOString(),
          }
        ];
        logger.debug('Returning mock leaderboard:', { count: mockLeaderboard.length });
        return mockLeaderboard as T;
      }
      
      // Default mock response for any other endpoint
      logger.debug('No specific mock data for endpoint, returning generic response');
      return {} as T;
    }
    
    if (!token) {
      // Should ideally not happen if routing/UI checks are correct,
      // but throw error if auth is required and token is missing.
      // React Query's error handling will catch this.
      throw new Error('Authentication token missing.');
    }
    headers['Authorization'] = `Bearer ${token}`;
  }

  const requestConfig: RequestInit = {
    method: method,
    headers: headers,
  };

  if (body) {
    requestConfig.body = JSON.stringify(body);
  }

  const apiUrl = `${getApiBaseUrl()}${endpoint}`; // Construct full URL
  logger.info(`Making ${method} request to ${apiUrl}`);
  logger.debug('Request body:', body ? '(body present)' : 'null');
  logger.debug('Request method:', method);

  try {
    const response = await fetch(apiUrl, requestConfig);
    logger.debug(`Response status: ${response.status}`);
    logger.debug('Response content-type:', response.headers.get('content-type'));

    // Check if the response is ok (status in the range 200-299)
    if (!response.ok) {
      const errorData = { message: `HTTP error ${response.status}` }; // Default error
      try {
        // Try to parse the error response body for a backend message
        const jsonError = await response.json();
        logger.error('Error response:', { status: response.status, error: jsonError.error || jsonError.message });
        logger.debug('Error details:', {
          status: response.status,
          statusText: response.statusText,
          url: response.url
        });
        // Use backend error message if available, otherwise keep default
        if (jsonError && jsonError.error) { // Match backend's likely error format
           errorData.message = jsonError.error;
        }
      } catch (e) {
        // Ignore JSON parsing error, use default message
        logger.warn('Could not parse error response JSON:', e);
      }
      // Throw an error with a message
      throw new Error(errorData.message);
    }

    // Handle successful responses
    if (response.status === 204) {
      // Handle No Content response (e.g., successful DELETE)
      return null as T;
    }

    // Check content type before parsing
    const contentType = response.headers.get('content-type');
    if (contentType && contentType.includes('application/json')) {
      return await response.json() as T;
    }

    // Handle unexpected non-JSON responses if necessary, or return null/throw error
    logger.warn(`Received non-JSON response for ${method} ${endpoint}`);
    return null as T;

  } catch (error) {
    // Use our centralized error handler
    throw handleApiError(error);
  }
};

// --- Auth Endpoints ---

export const registerUser = (data: RegisterUserRequest): Promise<UserResponse> => {
  logger.debug('Registration request:', { email: data.email });
  // Changed from '/users/register' to '/auth/register' to match backend endpoint
  return apiRequest<UserResponse>('/auth/register', 'POST', data, false);
};

export const loginUser = async (data: LoginRequest): Promise<LoginResponse> => {
  logger.debug('loginUser function called');
  logger.debug('Login request data received:', {
    email: data.email,
    hasPassword: !!data.password
  });
  
  // Define type for backend response which might be different from frontend
  interface BackendLoginResponse {
    access_token?: string;
    user?: UserResponse;
  }
  
  // Use lowercase field names as expected by the backend JSON tags
  const transformedData = {
    email: data.email,
    password: data.password
  };
  
  logger.debug('Sending login request for email:', transformedData.email);
  
  const response = await apiRequest<BackendLoginResponse>('/auth/login', 'POST', transformedData, false);
  
  logger.debug('Login response received:', { hasToken: !!response?.access_token, hasUser: !!response?.user });
  
  // Convert backend response format to frontend expected format
  const normalizedResponse: LoginResponse = {
    token: response?.access_token || '',
    user: response?.user || {} as UserResponse
  };
  
  // Store the token securely upon successful login
  if (normalizedResponse.token) {
    logger.debug('Token received from API, storing');
    
    try {
      // First store in regular localStorage for immediate access
      localStorage.setItem(TOKEN_STORAGE_KEY, normalizedResponse.token);
      logger.debug('Token stored in localStorage successfully');
      
      // Then try to store securely as well (as a backup)
      // On mobile, skip secure storage to avoid delays
      const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
      if (!isMobile) {
        await secureSet(TOKEN_STORAGE_KEY, normalizedResponse.token).catch(err => {
          logger.warn('Secure token storage failed, using regular localStorage only:', err);
        });
      } else {
        logger.debug('Mobile device detected, using localStorage only');
      }
      
      // Log success for debugging
      logger.info('Login successful, token stored');
    } catch (error) {
      logger.error('Error storing token:', error);
      // Make sure at least the plain storage is attempted
      localStorage.setItem(TOKEN_STORAGE_KEY, normalizedResponse.token);
    }
  } else {
    logger.warn('No token received in login response');
  }
  return normalizedResponse;
};

// --- User Endpoints ---

// Added endpoint to fetch current user details
export const getCurrentUser = (): Promise<UserResponse> => {
  return apiRequest<UserResponse>('/users/me', 'GET', null, true);
};

export const updateCurrentUser = (data: UpdateUserRequest): Promise<UserResponse> => {
  return apiRequest<UserResponse>('/users/me', 'PATCH', data, true);
};

export const deleteCurrentUser = (): Promise<null> => {
  return apiRequest<null>('/users/me', 'DELETE', null, true);
};

// --- Exercise Endpoints ---

/**
 * Helper function to retry API calls for transient errors
 * @param fn The function to retry
 * @param attempts Maximum number of retry attempts
 * @returns Promise with the result of the function
 */
export const withRetry = async <T>(fn: () => Promise<T>, attempts: number = 3): Promise<T> => {
  try {
    return await fn();
  } catch (error: unknown) {
    // Only retry for server errors (5xx)
    const errorMessage = error instanceof Error ? error.message : String(error);
    if (attempts > 1 && errorMessage.includes('HTTP error 5')) {
      logger.debug(`Retrying API call, ${attempts - 1} attempts remaining`);
      // Wait with exponential backoff before retrying
      await new Promise(resolve => setTimeout(resolve, 1000 * (4 - attempts)));
      return withRetry(fn, attempts - 1);
    }
    throw error;
  }
};

/**
 * Type-safe helper to log exercise results
 * @param data Exercise result data
 * @returns Promise with exercise response
 */
export const logExerciseResult = (data: LogExerciseRequest): Promise<ExerciseResponse> => {
  return withRetry(() => apiRequest<ExerciseResponse>('/exercises', 'POST', data, true));
};

export const logExercise = (data: LogExerciseRequest): Promise<ExerciseResponse> => {
  return apiRequest<ExerciseResponse>('/exercises', 'POST', data, true);
};

// Interface for the backend's workout response format
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

interface BackendPaginatedWorkoutsResponse {
  items: BackendWorkoutResponse[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

// Function to transform backend workout format to frontend exercise format
const transformWorkoutToExercise = (workout: BackendWorkoutResponse): ExerciseResponse => {
  return {
    id: workout.id,
    user_id: workout.user_id,
    exercise_id: workout.exercise_id,
    exercise_name: workout.exercise_name,
    exercise_type: workout.exercise_type,
    reps: workout.reps,
    time_in_seconds: workout.duration_seconds,
    distance: undefined, // Not available in workout response
    notes: undefined, // Not available in workout response
    grade: workout.grade,
    created_at: workout.created_at
  };
};

export const getUserExercises = async (page: number, pageSize: number): Promise<PaginatedExercisesResponse> => {
  // Use the new /workouts endpoint that replaced /exercises
  const response = await apiRequest<BackendPaginatedWorkoutsResponse>(`/workouts?page=${page}&pageSize=${pageSize}`, 'GET', null, true);
  
  // Transform the backend response to match frontend format
  return {
    items: response.items.map(transformWorkoutToExercise),
    total_count: response.totalCount, // Convert camelCase to snake_case
    page: response.page,
    page_size: response.pageSize // Convert camelCase to snake_case
  };
};

export const getExerciseById = (id: string): Promise<ExerciseResponse> => {
  return apiRequest<ExerciseResponse>(`/exercises/${id}`, 'GET', null, true);
};

// --- Leaderboard Endpoints ---

export const getLeaderboard = async (exerciseType: string): Promise<LeaderboardEntry[]> => {
  try {
    return await apiRequest<LeaderboardEntry[]>(`/leaderboards/global/exercise/${exerciseType}`, 'GET', null, true);
  } catch (error) {
    logger.error(`Failed to fetch leaderboard for ${exerciseType}:`, error);
    // Return empty array instead of throwing to prevent UI breakage
    return [];
  }
};

// --- Helper functions for auth state ---

// Store the token securely
// export const storeToken = async (token: string): Promise<void> => {
//   await secureSet(TOKEN_STORAGE_KEY, token);
// };

// Clear the token
export const clearToken = (): void => {
  logger.debug('Clearing token from storage');
  // Remove from secure storage
  secureRemove(TOKEN_STORAGE_KEY);
  // Also remove from regular localStorage to ensure all remnants are gone
  localStorage.removeItem(TOKEN_STORAGE_KEY);
};

// For compatibility with existing code, make a synchronous token getter
export const getSyncToken = (): string | null => {
  try {
    // First check if there's any token in localStorage
    const tokenValue = localStorage.getItem(TOKEN_STORAGE_KEY);
    
    logger.debug('getSyncToken called, token exists:', !!tokenValue);
    
    if (!tokenValue) {
      logger.debug('getSyncToken: No token found');
      return null;
    }
    
    // Return the token value if it exists
    logger.debug('getSyncToken: Token found');
    return tokenValue;
  } catch (error) {
    logger.error('Error in getSyncToken:', error);
    return null;
  }
};

// React hook for API client
export const useApi = () => {
  return {
    auth: {
      register: registerUser,
      login: loginUser,
      getCurrentUser,
      updateCurrentUser,
    },
    exercises: {
      logExercise,
      getUserExercises,
    },
    leaderboard: {
      getLeaderboard,
      getLocalLeaderboard: (exerciseType: string, lat: number, lng: number, radius: number = 5): Promise<LeaderboardEntry[]> => {
        return apiRequest<LeaderboardEntry[]>(
          `/leaderboards/local/exercise/${exerciseType}?lat=${lat}&lng=${lng}&radius=${radius}`, 
          'GET', 
          null, 
          true
        );
      }
    },
    system: {
      checkHealth: checkServerHealth
    }
  };
};

// Export for use in other files
export { getToken, apiRequest };

// --- Server Health Check ---

export const checkServerHealth = async (): Promise<{ status: string, responseTime: number }> => {
  const startTime = performance.now();
  try {
    // Use a simple endpoint that should be fast to respond
    await apiRequest<{ status: string }>('/health', 'GET', null, false);
    const endTime = performance.now();
    return { 
      status: 'ok', 
      responseTime: Math.round(endTime - startTime) 
    };
  } catch (error) {
    const endTime = performance.now();
    logger.error('Server health check failed:', error);
    return { 
      status: 'error', 
      responseTime: Math.round(endTime - startTime) 
    };
  }
};

/**
 * Delete an exercise record by ID
 * @param id The exercise ID to delete
 * @returns Promise resolving to true if successful
 */
export const deleteExercise = async (id: string): Promise<boolean> => {
  try {
    const response = await fetch(`${getApiBaseUrl()}/exercises/${id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${await getToken()}`
      },
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Failed to delete exercise');
    }

    return true;
  } catch (error) {
    logger.error('Error deleting exercise:', error);
    throw error;
  }
};

/**
 * Log in with a social provider
 * @param data Social login data (provider and token)
 */
export const loginWithSocialProvider = async (data: import('./types').SocialSignInRequest): Promise<import('./types').LoginResponse> => {
  logger.debug(`Logging in with ${data.provider} provider`);
  
  try {
    const response = await fetch(`${getApiBaseUrl()}/auth/${data.provider}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ message: 'Unknown error' }));
      throw new Error(errorData.message || `Failed to login with ${data.provider}`);
    }

    const responseData = await response.json();
    
    // Store token
    if (responseData.token) {
      localStorage.setItem(TOKEN_STORAGE_KEY, responseData.token);
    }
    
    return responseData;
  } catch (error) {
    logger.error('Social login error:', error);
    throw error;
  }
};
