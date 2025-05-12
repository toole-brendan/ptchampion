import React, { useEffect } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import config from '../../lib/config';
import Layout from '../layout/Layout';

// Get token storage key from config to ensure consistency
const TOKEN_STORAGE_KEY = config.auth.storageKeys.token;

// Check if dev auth bypass is enabled via environment variable
const DEV_AUTH_BYPASS = import.meta.env.DEV && import.meta.env.VITE_DEV_AUTH_BYPASS === 'true';

interface ProtectedRouteProps {
  children?: React.ReactNode;
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
    // Skip this check if DEV_AUTH_BYPASS is enabled
    if (DEV_AUTH_BYPASS) {
      return;
    }
    
    // If we detect a stale token in localStorage but no auth in memory,
    // refresh the page to trigger a clean auth check
    const hasLocalToken = localStorage.getItem(TOKEN_STORAGE_KEY) !== null;
    if (hasLocalToken && !token && !isLoading) {
      console.log('Detected stale token state, refreshing page');
      window.location.reload();
    }
  }, [isLoading, token]);

  // If dev auth bypass is enabled and we're in development, always render the protected content
  if (DEV_AUTH_BYPASS) {
    console.log('DEV_AUTH_BYPASS enabled, bypassing authentication check');
    return children ? <>{children}</> : <Layout />;
  }

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

  // If authenticated, render the Layout component with Outlet if children is not provided
  return children ? <>{children}</> : <Layout />;
};

export default ProtectedRoute; 