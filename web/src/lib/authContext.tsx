import React, { createContext, useState, useEffect, useContext, ReactNode, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  clearToken,
  getSyncToken,
  storeToken,
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

  // Effect to update isAuthenticated state when token changes
  useEffect(() => {
    // No need to manually store/clear token here - that's handled by the apiClient methods
  }, [token]);

  // Query to fetch the current user data - enabled only if a token exists
  const { data: user, isLoading: isLoadingUser, error: userError } = useQuery<
    UserResponse,
    Error // Explicitly type Error
  >({ // Pass options object directly
    queryKey: userQueryKey,
    queryFn: getCurrentUser,
    enabled: !!token, // Only run query if token is truthy
    staleTime: Infinity, // User data is generally stable, refetch manually on updates
    gcTime: Infinity, // Keep user data cached indefinitely while authenticated (use gcTime)
    retry: 1, // Retry fetching user once on failure
  });

  // --- Mutations --- //

  // Login Mutation
  const { mutateAsync: performLogin, isPending: isLoggingIn } = useMutation<
    LoginResponse,
    Error, // Explicitly type Error
    LoginRequest
  >({
    mutationFn: loginUser, // mutationFn inside options
    onSuccess: (data: LoginResponse) => { // Explicitly type data
      setToken(data.token); // Update token state to trigger UI updates
      // Set user data directly in the cache for immediate UI update
      queryClient.setQueryData(userQueryKey, data.user);
      setMutationError(null);
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
  const isLoading = isLoadingUser || isLoggingIn || isRegistering;

  // Determine overall error state (prefer mutation errors over user fetch errors)
  const error = mutationError || (userError ? userError.message : null);

  // Create the context value object
  const contextValue: AuthContextType = {
    isAuthenticated: !!token && !!user, // Authenticated if token exists AND user data loaded
    user: user || null, // User data from the query
    token: token,
    isLoading: isLoading,
    error: error,
    login,
    register,
    logout,
    clearError,
  };

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