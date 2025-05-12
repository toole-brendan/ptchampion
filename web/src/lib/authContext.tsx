import React, { createContext, useState, useEffect, useContext, ReactNode, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  clearToken,
  getSyncToken,
  // storeToken, // Removed as it's unused and commented out in apiClient
  loginUser,
  registerUser,
  getCurrentUser,
} from './apiClient';
import {
  LoginRequest,
  RegisterUserRequest,
  UserResponse,
  LoginResponse,
} from './types';
// Import the dev mock token constant
import { DEV_MOCK_TOKEN } from '../components/ui/DeveloperMenu';

// Define the shape of the authentication context
interface AuthContextType {
  isAuthenticated: boolean;
  user: UserResponse | null;
  token: string | null;
  isLoading: boolean; // Represents loading state of user fetch or auth mutations
  error: string | null; // Represents error from user fetch or auth mutations
  login: (data: LoginRequest) => Promise<void>;
  register: (data: RegisterUserRequest) => Promise<void>;
  logout: () => void;
  clearError: () => void; // Optional: To clear mutation errors manually if needed
}

// Query key for the current user data
const userQueryKey = ['currentUser'];

// Create the context with undefined default value
const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Provider component
export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const queryClient = useQueryClient();
  // We now initialize from the sync getter, but will update asynchronously
  const [token, setToken] = useState<string | null>(getSyncToken());
  const [mutationError, setMutationError] = useState<string | null>(null);
  
  // Check if we have a developer mock token
  const isDevToken = token === DEV_MOCK_TOKEN;
  
  // If we have a dev token, get the mock user from localStorage
  const [mockUser, setMockUser] = useState<UserResponse | null>(() => {
    if (isDevToken) {
      try {
        // Get the mock user data from localStorage
        const storedUser = localStorage.getItem('pt_auth_user');
        if (storedUser) {
          return JSON.parse(storedUser);
        }
      } catch (e) {
        console.error('Failed to parse mock user:', e);
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
    console.log('Auth context token effect triggered:', { 
      hasToken: !!token, 
      hasUser: !!user, 
      isDevToken 
    });
    
    // If we have a dev token, we can skip the API call and just use the mock user
    if (isDevToken) {
      console.log('Using dev mock token with mock user:', mockUser);
      return;
    }
    
    // Normal token validation logic for real tokens
    async function validateTokenAndUser() {
      try {
        if (token) {
          console.log('Token exists, checking user data');
          // If we have a token state, attempt to fetch user data if not already fetched
          if (!user) {
            console.log('No user data, prefetching');
            try {
              await queryClient.prefetchQuery({
                queryKey: userQueryKey,
                queryFn: getCurrentUser,
                retry: 1,
              });
              console.log('User data prefetch complete');
            } catch (error) {
              console.error('Failed to fetch user data, clearing token:', error);
              // If the token is invalid (401, 403, 404), clear it
              clearToken();
              setToken(null);
              // Also clear user data cache
              queryClient.removeQueries({ queryKey: userQueryKey });
              throw error;
            }
          } else {
            console.log('User data already exists');
          }
        }
      } catch (error) {
        console.error('Token validation error:', error);
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
      console.log('Login mutation success', { token: !!data.token, user: !!data.user });
      // Make sure we log if a token actually exists
      if (!data.token) {
        console.error('Token missing in login response after normalization');
      }
      setToken(data.token); // Update token state to trigger UI updates
      // Set user data directly in the cache for immediate UI update
      queryClient.setQueryData(userQueryKey, data.user);
      setMutationError(null);
      console.log('Auth state after login success:', { token: !!data.token, user: !!data.user });
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
      // Use username from registration variables for login
      await performLogin({ username: variables.username, password: variables.password });
      // Error state will be handled by performLogin's onError
    },
    onError: (error: Error) => { // Explicitly type error
      setMutationError(error.message || 'Registration failed');
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
      console.error('Login mutation failed:', error);
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
      console.error('Register mutation failed:', error);
    }
  }, [performRegister]);

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
  const isLoading = isDevToken ? false : (isLoadingUser || isLoggingIn || isRegistering);

  // Determine overall error state (prefer mutation errors over user fetch errors)
  const error = mutationError || (userError ? userError.message : null);

  // For dev tokens, we use the mock user instead of the API-fetched user
  const effectiveUser = isDevToken ? mockUser : user;

  // Create the context value object
  const contextValue: AuthContextType = {
    isAuthenticated: isDevToken ? true : (!!token && !!user), // Dev tokens are always authenticated
    user: effectiveUser ?? null, // Use mock user for dev tokens
    token: token,
    isLoading: isLoading,
    error: error,
    login,
    register,
    logout,
    clearError,
  };

  console.log('Auth context state:', { 
    isAuthenticated: contextValue.isAuthenticated,
    hasToken: !!token,
    isDevToken,
    hasUser: !!effectiveUser,
    isLoading
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