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

// Get the configured API base URL
const getApiBaseUrl = (): string => config.api.baseUrl; // Example: "http://localhost:8080/api/v1"

// Helper function to get the JWT token from storage
const getToken = (): string | null => {
  return localStorage.getItem(config.auth.storageKeys.token);
};

// Add type for the paginated response
export interface PaginatedExercisesResponse {
  items: ExerciseResponse[];
  total_count: number;
  page: number;
  page_size: number;
}

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
    const token = getToken();
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

  try {
    const response = await fetch(apiUrl, requestConfig);

    // Check if the response is ok (status in the range 200-299)
    if (!response.ok) {
      let errorData = { message: `HTTP error ${response.status}` }; // Default error
      try {
        // Try to parse the error response body for a backend message
        const jsonError = await response.json();
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
    // Log the error and re-throw it for React Query or caller to handle
    console.error(`API request failed: ${method} ${endpoint}`, error);
    // Ensure we're throwing an actual Error object
    if (error instanceof Error) {
      throw error;
    } else {
      throw new Error(String(error));
    }
  }
};

// --- Auth Endpoints ---

export const registerUser = (data: RegisterUserRequest): Promise<UserResponse> => {
  // Assuming registration returns the created user directly (adjust if needed)
  return apiRequest<UserResponse>('/users/register', 'POST', data, false);
};

export const loginUser = (data: LoginRequest): Promise<LoginResponse> => {
  // Login returns { token, user }
  return apiRequest<LoginResponse>('/users/login', 'POST', data, false);
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

export const logExercise = (data: LogExerciseRequest): Promise<ExerciseResponse> => {
  return apiRequest<ExerciseResponse>('/exercises', 'POST', data, true);
};

export const getUserExercises = (page: number, pageSize: number): Promise<PaginatedExercisesResponse> => {
  // Use the correct endpoint from the backend router, add query params
  return apiRequest<PaginatedExercisesResponse>(`/exercises?page=${page}&pageSize=${pageSize}`, 'GET', null, true);
};

// --- Leaderboard Endpoints ---

export const getLeaderboard = (exerciseType: string): Promise<LeaderboardEntry[]> => {
  return apiRequest<LeaderboardEntry[]>(`/leaderboard/${exerciseType}`, 'GET', null, false);
};

// --- Helper functions for auth state ---

// Store only the token
export const storeToken = (token: string): void => {
  localStorage.setItem(config.auth.storageKeys.token, token);
};

// Clear only the token
export const clearToken = (): void => {
  localStorage.removeItem(config.auth.storageKeys.token);
};

// Keep getToken as it was (used internally by apiRequest)
export { getToken }; 