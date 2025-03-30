import React, { createContext, useState, useEffect, useContext, ReactNode } from 'react';
import { 
  clearAuthData, 
  getStoredUser, 
  loginUser, 
  registerUser, 
  storeAuthData 
} from './apiClient';
import { 
  AuthState, 
  LoginRequest, 
  RegisterUserRequest, 
  UserResponse,
} from './types';

// Default auth state
const defaultAuthState: AuthState = {
  isAuthenticated: false,
  user: null,
  token: null,
  loading: true,
  error: null,
};

// Mock development user data
const DEV_USER: UserResponse = {
  id: 1,
  username: 'devuser',
  display_name: 'Development User',
  profile_picture_url: 'https://ui-avatars.com/api/?name=Dev+User&background=random',
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),
};

// Mock JWT token for development
const DEV_TOKEN = 'dev-jwt-token-for-local-development-only';

// Check if in development mode
const isDevelopment = import.meta.env.DEV || import.meta.env.MODE === 'development';

interface AuthContextType extends AuthState {
  login: (data: LoginRequest) => Promise<void>;
  register: (data: RegisterUserRequest) => Promise<void>;
  logout: () => void;
  clearError: () => void;
}

// Create the context with undefined default value
const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Provider component that wraps the app and makes auth available to child components
export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [state, setState] = useState<AuthState>(defaultAuthState);

  // Initialize auth state from localStorage on component mount
  useEffect(() => {
    const initializeAuth = () => {
      try {
        const token = localStorage.getItem('authToken');
        const user = getStoredUser();
        
        if (token && user) {
          setState({
            ...defaultAuthState,
            isAuthenticated: true,
            user,
            token,
            loading: false,
          });
        } else if (isDevelopment) {
          // Auto-login for development
          console.log('🔧 Development mode: Auto-logging in with dev user');
          
          // Store dev auth data
          storeAuthData(DEV_TOKEN, DEV_USER);
          
          setState({
            isAuthenticated: true,
            user: DEV_USER,
            token: DEV_TOKEN,
            loading: false,
            error: null,
          });
        } else {
          setState({
            ...defaultAuthState,
            loading: false,
          });
        }
      } catch (error) {
        setState({
          ...defaultAuthState,
          loading: false,
        });
      }
    };

    initializeAuth();
  }, []);

  // Login function
  const login = async (data: LoginRequest) => {
    setState(prev => ({ ...prev, loading: true, error: null }));
    try {
      // Skip actual API call in development mode
      if (isDevelopment) {
        console.log('🔧 Development mode: Simulating login for', data.username);
        
        // Create a custom dev user with the provided username
        const customDevUser = {
          ...DEV_USER,
          username: data.username,
          display_name: `${data.username} (Dev)`,
        };
        
        // Store auth data in localStorage
        storeAuthData(DEV_TOKEN, customDevUser);
        
        // Update state
        setState({
          isAuthenticated: true,
          user: customDevUser,
          token: DEV_TOKEN,
          loading: false,
          error: null,
        });
        
        return;
      }
      
      const response = await loginUser(data);
      const { token, user } = response;
      
      // Store auth data in localStorage
      storeAuthData(token, user);
      
      // Update state
      setState({
        isAuthenticated: true,
        user,
        token,
        loading: false,
        error: null,
      });
    } catch (error) {
      if (isDevelopment) {
        // Even if API call fails in dev, still log in with dev user
        console.log('🔧 Development mode: API call failed but still logging in');
        
        // Create a custom dev user with the provided username
        const customDevUser = {
          ...DEV_USER,
          username: data.username,
          display_name: `${data.username} (Dev)`,
        };
        
        storeAuthData(DEV_TOKEN, customDevUser);
        setState({
          isAuthenticated: true,
          user: customDevUser,
          token: DEV_TOKEN,
          loading: false,
          error: null,
        });
        return;
      }
      
      setState(prev => ({ 
        ...prev, 
        loading: false, 
        error: error instanceof Error ? error.message : 'Failed to login'
      }));
      throw error;
    }
  };

  // Register function
  const register = async (data: RegisterUserRequest) => {
    setState(prev => ({ ...prev, loading: true, error: null }));
    try {
      // Skip actual API call in development mode
      if (isDevelopment) {
        console.log('🔧 Development mode: Simulating registration for', data.username);
        
        // Auto login after simulated registration
        await login({
          username: data.username,
          password: data.password,
        });
        
        return;
      }
      
      // Register the user
      await registerUser(data);
      
      // Auto login after registration
      await login({
        username: data.username,
        password: data.password,
      });
    } catch (error) {
      if (isDevelopment) {
        // Even if API call fails in dev, still log in with dev user
        console.log('🔧 Development mode: API call failed but still registering and logging in');
        await login({
          username: data.username,
          password: data.password,
        });
        return;
      }
      
      setState(prev => ({ 
        ...prev, 
        loading: false, 
        error: error instanceof Error ? error.message : 'Failed to register'
      }));
      throw error;
    }
  };

  // Logout function
  const logout = () => {
    clearAuthData();
    setState({
      isAuthenticated: false,
      user: null,
      token: null,
      loading: false,
      error: null,
    });
    
    if (isDevelopment) {
      console.log('🔧 Development mode: Logged out. Refresh to auto-login again.');
    }
  };

  // Clear error function
  const clearError = () => {
    setState(prev => ({ ...prev, error: null }));
  };

  // Create the context value object
  const contextValue: AuthContextType = {
    ...state,
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