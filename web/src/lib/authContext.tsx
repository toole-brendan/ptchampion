import React, { createContext, useState, useEffect, useContext, ReactNode, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  clearToken,
  getSyncToken,
  // storeToken, // Removed as it's unused and commented out in apiClient
  loginUser,
  registerUser,
  getCurrentUser,
  loginWithSocialProvider,
} from './apiClient';
import {
  LoginRequest,
  RegisterUserRequest,
  UserResponse,
  LoginResponse,
  SocialSignInRequest,
} from './types';
// Import the dev mock token constant
import { DEV_MOCK_TOKEN } from '../components/ui/DeveloperMenu';
import { logger } from './logger';
import config from './config';

// Define the shape of the authentication context
interface AuthContextType {
  isAuthenticated: boolean;
  user: UserResponse | null;
  token: string | null;
  isLoading: boolean; // Represents loading state of user fetch or auth mutations
  error: string | null; // Represents error from user fetch or auth mutations
  login: (data: LoginRequest) => Promise<void>;
  loginWithSocial: (data: SocialSignInRequest) => Promise<void>;
  register: (data: RegisterUserRequest) => Promise<void>;
  logout: () => void;
  clearError: () => void; // Optional: To clear mutation errors manually if needed
}

// Query key for the current user data
const userQueryKey = ['currentUser'];

// ENV-based dev bypass settings
const DEV_AUTH_BYPASS = import.meta.env.DEV && import.meta.env.VITE_DEV_AUTH_BYPASS === 'true';
const DEV_AUTH_USER = import.meta.env.VITE_DEV_AUTH_USER 
  ? JSON.parse(import.meta.env.VITE_DEV_AUTH_USER as string) 
  : null;

// Debug environment variables
logger.debug('Environment Variable Debug:', {
  'import.meta.env.DEV': import.meta.env.DEV,
  'import.meta.env.VITE_DEV_AUTH_BYPASS': import.meta.env.VITE_DEV_AUTH_BYPASS,
  'DEV_AUTH_BYPASS': DEV_AUTH_BYPASS,
  'DEV_AUTH_USER': DEV_AUTH_USER ? 'Present' : 'Not set' // Sanitize user data
});

// Create the context with undefined default value
const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Provider component
export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const queryClient = useQueryClient();
  // We now initialize from the sync getter, but will update asynchronously
  const [token, setToken] = useState<string | null>(() => {
    // If DEV_AUTH_BYPASS is true, set the token to DEV_MOCK_TOKEN automatically
    if (DEV_AUTH_BYPASS) {
      localStorage.setItem(config.auth.storageKeys.token, DEV_MOCK_TOKEN);
      logger.debug('Using dev auth bypass from environment variables');
      return DEV_MOCK_TOKEN;
    }
    return getSyncToken();
  });
  const [mutationError, setMutationError] = useState<string | null>(null);
  
  // Check if we have a developer mock token
  const isDevToken = token === DEV_MOCK_TOKEN;
  
  // If we have a dev token, get the mock user from localStorage or env var
  const [mockUser, setMockUser] = useState<UserResponse | null>(() => {
    if (isDevToken) {
      try {
        // First try to use the environment variable mock user if available
        if (DEV_AUTH_BYPASS && DEV_AUTH_USER) {
          logger.debug('Using mock user from environment variables');
          // Also update localStorage for consistency
          localStorage.setItem(config.auth.storageKeys.user, JSON.stringify(DEV_AUTH_USER));
          return DEV_AUTH_USER;
        }
        
        // If not, try to get from localStorage
        const storedUser = localStorage.getItem(config.auth.storageKeys.user);
        if (storedUser) {
          return JSON.parse(storedUser);
        }
      } catch (e) {
        logger.error('Failed to parse mock user:', e);
      }
    }
    return null;
  });

  // Query to fetch the current user data - enabled only if a token exists and it's not a dev token
  const { data: user, isLoading: isLoadingUser, error: userError } = useQuery<
    UserResponse,
    Error // Explicitly type Error
  >({ // Pass options object directly
    queryKey: userQueryKey,
    queryFn: getCurrentUser,
    enabled: !!token && !isDevToken, // Only run query if we have a real token
    staleTime: Infinity, // User data is generally stable, refetch manually on updates
    gcTime: Infinity, // Keep user data cached indefinitely while authenticated (use gcTime)
    retry: 1, // Retry fetching user once on failure
  });

  // Effect to update isAuthenticated state when token changes
  useEffect(() => {
    logger.debug('Auth context token effect triggered:', { 
      hasToken: !!token, 
      hasUser: !!user, 
      isDevToken,
      isDevBypass: DEV_AUTH_BYPASS
    });
    
    // If we have a dev token, we can skip the API call and just use the mock user
    if (isDevToken) {
      logger.debug('Using dev mock token with mock user:', mockUser ? { id: mockUser.id, email: mockUser.email } : null);
      return;
    }
    
    // Normal token validation logic for real tokens
    async function validateTokenAndUser() {
      try {
        if (token) {
          logger.debug('Token exists, checking user data');
          // If we have a token state, attempt to fetch user data if not already fetched
          if (!user) {
            logger.debug('No user data, prefetching');
            try {
              await queryClient.prefetchQuery({
                queryKey: userQueryKey,
                queryFn: getCurrentUser,
                retry: 1,
              });
              logger.debug('User data prefetch complete');
            } catch (error) {
              logger.error('Failed to fetch user data, clearing token:', error);
              // If the token is invalid (401, 403, 404), clear it
              clearToken();
              setToken(null);
              // Also clear user data cache
              queryClient.removeQueries({ queryKey: userQueryKey });
              throw error;
            }
          } else {
            logger.debug('User data already exists');
          }
        }
      } catch (error) {
        logger.error('Token validation error:', error);
        // Clear token if validation fails
        clearToken();
        setToken(null);
      }
    }
    
    // Only validate real tokens
    if (!isDevToken) {
      validateTokenAndUser();
    }
  }, [token, user, queryClient, isDevToken, mockUser]);

  // --- Mutations --- //

  // Login Mutation
  const { mutateAsync: performLogin, isPending: isLoggingIn } = useMutation<
    LoginResponse,
    Error, // Explicitly type Error
    LoginRequest
  >({
    mutationFn: loginUser, // mutationFn inside options
    onSuccess: (data: LoginResponse) => { // Explicitly type data
      logger.debug('Login mutation success', { hasToken: !!data.token, hasUser: !!data.user });
      // Make sure we log if a token actually exists
      if (!data.token) {
        logger.error('Token missing in login response after normalization');
      }
      setToken(data.token); // Update token state to trigger UI updates
      // Set user data directly in the cache for immediate UI update
      queryClient.setQueryData(userQueryKey, data.user);
      setMutationError(null);
      logger.debug('Auth state after login success:', { hasToken: !!data.token, hasUser: !!data.user });
    },
    onError: (error: Error) => { // Explicitly type error
      clearToken(); // Ensure token is cleared on login failure
      setToken(null); // Update token state to match
      // Correct usage of removeQueries
      queryClient.removeQueries({ queryKey: userQueryKey });
      setMutationError(error.message || 'Login failed');
    },
  });

  // Register Mutation
  const { mutateAsync: performRegister, isPending: isRegistering } = useMutation<
    UserResponse,
    Error, // Explicitly type Error
    RegisterUserRequest
  >({
    mutationFn: registerUser, // mutationFn inside options
    onSuccess: async (_registeredUser: UserResponse, variables: RegisterUserRequest) => { // Explicitly type params
      // After successful registration, automatically log the user in
      // Use email from registration variables for login
      await performLogin({ email: variables.email, password: variables.password });
      // Error state will be handled by performLogin's onError
    },
    onError: (error: Error) => { // Explicitly type error
      setMutationError(error.message || 'Registration failed');
    },
  });

  // Social Login Mutation
  const { mutateAsync: performSocialLogin, isPending: isSocialLoggingIn } = useMutation<
    LoginResponse,
    Error,
    SocialSignInRequest
  >({
    mutationFn: loginWithSocialProvider,
    onSuccess: (data: LoginResponse) => {
      logger.debug('Social login mutation success', { hasToken: !!data.token, hasUser: !!data.user });
      if (!data.token) {
        logger.error('Token missing in social login response after normalization');
      }
      setToken(data.token);
      queryClient.setQueryData(userQueryKey, data.user);
      setMutationError(null);
      logger.debug('Auth state after social login success:', { hasToken: !!data.token, hasUser: !!data.user });
    },
    onError: (error: Error) => {
      clearToken();
      setToken(null);
      queryClient.removeQueries({ queryKey: userQueryKey });
      setMutationError(error.message || 'Social login failed');
    },
  });

  // --- Context Methods --- //

  // Login method exposed by context
  const login = useCallback(async (data: LoginRequest) => {
    try {
      setMutationError(null); // Clear previous errors before attempting
      await performLogin(data);
      // Success is handled by mutation's onSuccess
    } catch (error) {
      // Error is now set by mutation's onError
      logger.error('Login mutation failed:', error);
    }
  }, [performLogin]);

  // Register method exposed by context
  const register = useCallback(async (data: RegisterUserRequest) => {
    try {
      setMutationError(null); // Clear previous errors before attempting
      await performRegister(data);
      // Success includes auto-login handled by mutation's onSuccess
    } catch (error) {
      // Error is now set by mutation's onError
      logger.error('Register mutation failed:', error);
    }
  }, [performRegister]);

  // Social login method exposed by context
  const loginWithSocial = useCallback(async (data: SocialSignInRequest) => {
    try {
      setMutationError(null);
      await performSocialLogin(data);
      // Success is handled by mutation's onSuccess
    } catch (error) {
      logger.error('Social login mutation failed:', error);
    }
  }, [performSocialLogin]);

  // Logout method
  const logout = useCallback(() => {
    clearToken(); // Clear token from storage
    setToken(null); // Clear token state
    setMockUser(null); // Clear any mock user
    queryClient.removeQueries({ queryKey: userQueryKey }); // Use correct signature
    setMutationError(null); // Clear any lingering mutation errors
  }, [queryClient]);

  // Method to clear mutation errors manually if needed
  const clearError = useCallback(() => {
    setMutationError(null);
  }, []);

  // Determine overall loading state
  // Loading is true if we don't have a token yet but are initializing (handled by token state),
  // or if we have a token but are fetching the user (isLoadingUser),
  // or if a login/registration mutation is in progress (isPending...).
  // Dev tokens are never in a loading state.
  const isLoading = isDevToken ? false : (isLoadingUser || isLoggingIn || isRegistering || isSocialLoggingIn);

  // Determine overall error state (prefer mutation errors over user fetch errors)
  const error = mutationError || (userError ? userError.message : null);

  // For dev tokens, we use the mock user instead of the API-fetched user
  const effectiveUser = isDevToken ? mockUser : user;

  // Create the context value object
  const contextValue: AuthContextType = {
    // Consider authenticated if we have a token, even if user data is still loading
    // This prevents redirect to login while user data is being fetched after page refresh
    isAuthenticated: isDevToken ? true : !!token,
    user: effectiveUser ?? null, // Use mock user for dev tokens
    token: token,
    isLoading: isLoading,
    error: error,
    login,
    loginWithSocial,
    register,
    logout,
    clearError,
  };

  logger.debug('Auth context state:', { 
    isAuthenticated: contextValue.isAuthenticated,
    hasToken: !!token,
    isDevToken,
    hasUser: !!effectiveUser,
    isLoading,
    isDevBypass: DEV_AUTH_BYPASS
  });

  return (
    <AuthContext.Provider value={contextValue}>
      {children}
    </AuthContext.Provider>
  );
};

// Custom hook to use the auth context
export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
