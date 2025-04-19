import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';

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
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

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
    // Save the attempted URL to redirect back after login
    const returnUrl = encodeURIComponent(location.pathname + location.search);
    return <Navigate to={`${redirectPath}?returnUrl=${returnUrl}`} replace />;
  }

  // If authenticated, render the protected content
  return <>{children}</>;
};

export default ProtectedRoute; 