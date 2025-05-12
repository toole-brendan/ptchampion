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
      console.log('getToken (async) called, token exists from secureGet');
      return token;
    }
    
    // Fall back to regular localStorage if secure get failed
    const plainToken = localStorage.getItem(TOKEN_STORAGE_KEY);
    if (plainToken) {
      console.log('getToken (async) called, token exists from localStorage');
      return plainToken;
    }
    
    console.log('getToken (async) called, no token found');
    return null;
  } catch (error) {
    // If secure decryption fails, try regular localStorage
    console.error('Error in secure token retrieval:', error);
    const plainToken = localStorage.getItem(TOKEN_STORAGE_KEY);
    if (plainToken) {
      console.log('getToken (async) falling back to localStorage token');
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
  console.error('API Error:', error);
  
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
      console.log('Using dev mock token, bypassing actual API call');
      
      // Handle specific endpoints with mock data
      if (endpoint === '/users/me') {
        // Get mock user from localStorage
        try {
          const mockUserStr = localStorage.getItem(USER_STORAGE_KEY);
          if (mockUserStr) {
            const mockUser = JSON.parse(mockUserStr);
            console.log('Returning mock user:', mockUser);
            return mockUser as T;
          }
        } catch (e) {
          console.error('Error parsing mock user:', e);
        }
        
        // Fallback mock user if none in localStorage
        const fallbackUser: UserResponse = {
          id: 9999,
          username: 'devuser',
          display_name: 'Developer',
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
          console.log('Returning mock exercise:', mockExercise);
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
          console.log('Returning mock exercises:', mockExercises);
          return mockExercises as T;
        }
      }
      
      // Mock leaderboard data
      if (endpoint.startsWith('/leaderboard')) {
        const mockLeaderboard: LeaderboardEntry[] = [
          {
            user_id: 9999,
            username: 'devuser',
            display_name: 'Developer',
            max_grade: 100,
            last_attempt_date: new Date().toISOString(),
          },
          {
            user_id: 9998,
            username: 'user2',
            display_name: 'Mock User 2',
            max_grade: 90,
            last_attempt_date: new Date().toISOString(),
          },
          {
            user_id: 9997,
            username: 'user3',
            display_name: 'Mock User 3',
            max_grade: 80,
            last_attempt_date: new Date().toISOString(),
          }
        ];
        console.log('Returning mock leaderboard:', mockLeaderboard);
        return mockLeaderboard as T;
      }
      
      // Default mock response for any other endpoint
      console.log('No specific mock data for endpoint, returning generic response');
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
  console.log(`Making ${method} request to ${apiUrl}`, { body, headers });

  try {
    const response = await fetch(apiUrl, requestConfig);
    console.log(`Response status: ${response.status}`);

    // Check if the response is ok (status in the range 200-299)
    if (!response.ok) {
      const errorData = { message: `HTTP error ${response.status}` }; // Default error
      try {
        // Try to parse the error response body for a backend message
        const jsonError = await response.json();
        console.error('Error response:', jsonError);
        // Use backend error message if available, otherwise keep default
        if (jsonError && jsonError.error) { // Match backend's likely error format
           errorData.message = jsonError.error;
        }
      } catch (e) {
        // Ignore JSON parsing error, use default message
        console.warn('Could not parse error response JSON:', e);
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
    console.warn(`Received non-JSON response for ${method} ${endpoint}`);
    return null as T;

  } catch (error) {
    // Use our centralized error handler
    throw handleApiError(error);
  }
};

// --- Auth Endpoints ---

export const registerUser = (data: RegisterUserRequest): Promise<UserResponse> => {
  console.log('Registration request data:', data);
  // Changed from '/users/register' to '/auth/register' to match backend endpoint
  return apiRequest<UserResponse>('/auth/register', 'POST', data, false);
};

export const loginUser = async (data: LoginRequest): Promise<LoginResponse> => {
  console.log('loginUser function called');
  
  // Define type for backend response which might be different from frontend
  interface BackendLoginResponse {
    access_token?: string;
    user?: UserResponse;
  }
  
  const response = await apiRequest<BackendLoginResponse>('/auth/login', 'POST', data, false);
  
  // Log the full response object
  console.log('LOGIN RESPONSE FULL DETAILS:', response);
  console.log('response.access_token exists?', response && response.access_token ? true : false);
  console.log('response type:', typeof response);
  console.log('response keys:', response ? Object.keys(response) : 'null');
  
  // Convert backend response format to frontend expected format
  const normalizedResponse: LoginResponse = {
    token: response?.access_token || '',
    user: response?.user || {} as UserResponse
  };
  
  // Store the token securely upon successful login
  if (normalizedResponse.token) {
    console.log('Token received from API (access_token), about to store');
    
    try {
      // First store in regular localStorage for immediate access
      localStorage.setItem(TOKEN_STORAGE_KEY, normalizedResponse.token);
      console.log('Token stored in localStorage successfully');
      
      // Then try to store securely as well (as a backup)
      await secureSet(TOKEN_STORAGE_KEY, normalizedResponse.token).catch(err => {
        console.warn('Secure token storage failed, using regular localStorage only:', err);
      });
      
      // Log success for debugging
      console.log('Login successful, token stored');
    } catch (error) {
      console.error('Error storing token:', error);
      // Make sure at least the plain storage is attempted
      localStorage.setItem(TOKEN_STORAGE_KEY, normalizedResponse.token);
    }
  } else {
    console.warn('No token received in login response');
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
      console.log(`Retrying API call, ${attempts - 1} attempts remaining`);
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

export const getUserExercises = (page: number, pageSize: number): Promise<PaginatedExercisesResponse> => {
  // Use the correct endpoint from the backend router, add query params
  return apiRequest<PaginatedExercisesResponse>(`/exercises?page=${page}&pageSize=${pageSize}`, 'GET', null, true);
};

export const getExerciseById = (id: string): Promise<ExerciseResponse> => {
  return apiRequest<ExerciseResponse>(`/exercises/${id}`, 'GET', null, true);
};

// --- Leaderboard Endpoints ---

export const getLeaderboard = async (exerciseType: string): Promise<LeaderboardEntry[]> => {
  try {
    return await apiRequest<LeaderboardEntry[]>(`/leaderboard/${exerciseType}`, 'GET', null, true);
  } catch (error) {
    console.error(`Failed to fetch leaderboard for ${exerciseType}:`, error);
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
  console.log('Clearing token from storage');
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
    
    console.log('getSyncToken called, raw value exists:', !!tokenValue);
    
    if (!tokenValue) {
      console.log('getSyncToken: No token found in localStorage');
      return null;
    }
    
    // Return the token value if it exists
    console.log('getSyncToken: Token found in localStorage, returning it');
    return tokenValue;
  } catch (error) {
    console.error('Error in getSyncToken:', error);
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
          `/leaderboard/${exerciseType}?lat=${lat}&lng=${lng}&radius=${radius}`, 
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
    console.error('Server health check failed:', error);
    return { 
      status: 'error', 
      responseTime: Math.round(endTime - startTime) 
    };
  }
}; 