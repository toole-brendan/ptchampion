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

// REMOVE the static API_BASE_URL and replace with a function that gets the current value
// This ensures we always use the most up-to-date URL after port discovery completes
const getApiBaseUrl = (): string => config.api.baseUrl;

// Helper function to get the JWT token from storage
const getToken = (): string | null => {
  return localStorage.getItem(config.auth.storageKeys.token);
};

/**
 * Normalize the API endpoint to handle inconsistencies in path configuration
 * @param endpoint API endpoint path
 * @returns Normalized endpoint path
 */
const normalizeEndpoint = (endpoint: string): string => {
  // Try both with and without the /v1 prefix
  // This handles potential inconsistencies between port discovery and server routes
  const apiBaseUrl = getApiBaseUrl(); // Get current base URL
  const hasV1InBaseUrl = apiBaseUrl.includes('/v1');
  
  if (hasV1InBaseUrl && endpoint.startsWith('/v1/')) {
    // If base URL already has /v1 and endpoint also starts with /v1, remove from endpoint
    return endpoint.substring(3);
  }
  
  // Otherwise, just ensure endpoint starts with /
  return endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
};

/**
 * Helper function for making API requests with automatic retries
 * @param endpoint API endpoint
 * @param method HTTP method
 * @param body Request body (optional)
 * @param requiresAuth Whether authentication is required
 * @param retries Number of retries to attempt
 * @returns Promise with the response data
 */
const apiRequest = async <T>(
  endpoint: string, 
  method: string, 
  body?: any, 
  requiresAuth: boolean = false,
  retries: number = 1
): Promise<T> => {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
  };

  if (requiresAuth) {
    const token = getToken();
    if (!token) {
      // Handle cases where auth is required but no token is found
      throw new Error('Authentication required.');
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

  const makeRequest = async (): Promise<T> => {
    try {
      // Always get the current base URL for each request
      const apiBaseUrl = getApiBaseUrl();
      const normalizedEndpoint = normalizeEndpoint(endpoint);
      const apiUrl = `${apiBaseUrl}${normalizedEndpoint}`;
      
      console.log(`Making request to: ${apiUrl}`, { 
        method, 
        requiresAuth,
        hasToken: !!getToken()
      });
      
      const response = await fetch(apiUrl, requestConfig);

      // Check if the response is ok (status in the range 200-299)
      if (!response.ok) {
        let errorData;
        try {
          // Try to parse the error response body
          errorData = await response.json();
        } catch (e) {
          // If parsing fails, use the status text
          errorData = { error: response.statusText };
        }
        console.error(`API Error (${response.status}):`, errorData);
        // Throw an error with details from the backend if possible
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      // If response is OK, try to parse JSON, handle empty responses (e.g., 204 No Content)
      const contentType = response.headers.get('content-type');
      if (contentType && contentType.indexOf('application/json') !== -1) {
        if (response.status === 204) {
          return null as T; // Handle No Content response
        }
        return await response.json();
      } else {
        // Handle non-JSON responses if necessary
        return null as T;
      }
    } catch (error) {
      // Log the error
      console.error(`API request failed: ${method} ${endpoint}`, error);
      // Rethrow to allow caller to handle
      throw error;
    }
  };

  // Try the request with retries
  let lastError: Error | null = null;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await makeRequest();
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      
      // If this was our last retry, or it's an error we shouldn't retry (like auth errors)
      if (
        attempt === retries || 
        (error instanceof Error && error.message === 'Authentication required.')
      ) {
        throw lastError;
      }
      
      // Wait before retry with exponential backoff
      const delay = Math.pow(2, attempt) * 100; // 100ms, 200ms, 400ms, etc.
      console.log(`Retry ${attempt + 1}/${retries} after ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  // This should never be reached due to the throw in the loop
  throw lastError || new Error('Unknown API request error');
};

// --- Auth Endpoints ---

export const registerUser = (data: RegisterUserRequest): Promise<UserResponse> => {
  return apiRequest<UserResponse>('/users/register', 'POST', data, false, 2);
};

export const loginUser = (data: LoginRequest): Promise<LoginResponse> => {
  return apiRequest<LoginResponse>('/users/login', 'POST', data, false, 2);
};

// --- User Endpoints ---

export const updateCurrentUser = (data: UpdateUserRequest): Promise<UserResponse> => {
  return apiRequest<UserResponse>('/users/me', 'PATCH', data, true, 1);
};

// --- Exercise Endpoints ---

export const logExercise = (data: LogExerciseRequest): Promise<ExerciseResponse> => {
  return apiRequest<ExerciseResponse>('/exercises', 'POST', data, true, 1);
};

export const getUserExercises = (): Promise<ExerciseResponse[]> => {
  // Try both the standard and alternative endpoints
  return apiRequest<ExerciseResponse[]>('/user-exercises', 'GET', null, true, 1)
    .catch(error => {
      console.log('Failed with /user-exercises, trying fallback endpoint...');
      // Use the fallback endpoint that exists in routes.ts
      return apiRequest<ExerciseResponse[]>('/exercises/user', 'GET', null, true, 1);
    });
};

// --- Leaderboard Endpoints ---

export const getLeaderboard = (exerciseType: string): Promise<LeaderboardEntry[]> => {
  return apiRequest<LeaderboardEntry[]>(`/leaderboard/${exerciseType}`, 'GET', null, false, 1);
};

// --- Helper functions for auth state ---

export const storeAuthData = (token: string, user: UserResponse): void => {
  localStorage.setItem(config.auth.storageKeys.token, token);
  localStorage.setItem(config.auth.storageKeys.user, JSON.stringify(user));
};

export const clearAuthData = (): void => {
  localStorage.removeItem(config.auth.storageKeys.token);
  localStorage.removeItem(config.auth.storageKeys.user);
};

export const getStoredUser = (): UserResponse | null => {
  const userData = localStorage.getItem(config.auth.storageKeys.user);
  try {
    return userData ? JSON.parse(userData) : null;
  } catch (error) {
    console.error('Failed to parse stored user data:', error);
    return null;
  }
}; 