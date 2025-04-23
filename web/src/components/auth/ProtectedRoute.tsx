import React, { useEffect } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import config from '../../lib/config';

// Get token storage key from config to ensure consistency
const TOKEN_STORAGE_KEY = config.auth.storageKeys.token;

interface ProtectedRouteProps {
  children: React.ReactNode;
  redirectPath?: string;
}

/**
 * Protected Route Component
 * 
 * Protects routes that require authentication. If user is not authenticated,
 * they are redirected to the login page. Shows loading state while checking auth.
 * 
 * @param children - The components to render when authenticated
 * @param redirectPath - Optional override for the redirect path (default: '/login')
 */
const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ 
  children, 
  redirectPath = '/login'
}) => {
  const { isAuthenticated, isLoading, token } = useAuth();
  const location = useLocation();

  // Additional check to ensure we don't have partially loaded states
  useEffect(() => {
    // If we detect a stale token in localStorage but no auth in memory,
    // refresh the page to trigger a clean auth check
    const hasLocalToken = localStorage.getItem(TOKEN_STORAGE_KEY) !== null;
    if (hasLocalToken && !token && !isLoading) {
      console.log('Detected stale token state, refreshing page');
      window.location.reload();
    }
  }, [isLoading, token]);

  // Show a loading state while checking authentication
  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-cream p-4">
        <div className="text-center">
          <div className="mx-auto size-8 animate-spin rounded-full border-4 border-brass-gold border-t-transparent"></div>
          <p className="mt-4 text-tactical-gray">Checking authentication...</p>
        </div>
      </div>
    );
  }

  // If not authenticated, redirect to login with return URL
  if (!isAuthenticated) {
    // Clean up any existing tokens to avoid stale state
    if (localStorage.getItem(TOKEN_STORAGE_KEY)) {
      localStorage.removeItem(TOKEN_STORAGE_KEY);
    }
    
    // Save the attempted URL to redirect back after login
    const returnUrl = encodeURIComponent(location.pathname + location.search);
    return <Navigate to={`${redirectPath}?returnUrl=${returnUrl}`} replace />;
  }

  // If authenticated, render the protected content
  return <>{children}</>;
};

export default ProtectedRoute; 