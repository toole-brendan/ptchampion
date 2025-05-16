import React, { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { Button } from '../../components/ui/button';
import { Input } from '../../components/ui/input';
import { Alert, AlertDescription } from '../../components/ui/alert';
import { ExclamationTriangleIcon } from '@radix-ui/react-icons';
import logoImage from '../../assets/pt_champion_logo_2.png';
import config from '../../lib/config';
import { cleanAuthStorage } from '../../lib/secureStorage';
import { Separator } from '../../components/ui/separator';
import SocialLoginButtons from '../../components/auth/SocialLoginButtons';

// Get token storage key from config to ensure consistency
const TOKEN_STORAGE_KEY = config.auth.storageKeys.token;

// Development mode is controlled by environment config

// Real logo component
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <img 
    src={logoImage} 
    alt="PT Champion Logo" 
    className={`${className} max-h-80 w-auto`} 
  />
);

// OAuth configuration (these should be environment variables in production)
const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID || '';
const APPLE_SERVICE_ID = import.meta.env.VITE_APPLE_SERVICE_ID || '';
const REDIRECT_URI = `${window.location.origin}/auth/callback`;

const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { login, loginWithSocial, isAuthenticated, isLoading, error, clearError } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [isSocialSigningIn, setIsSocialSigningIn] = useState(false);
  
  // Extract return URL from query params
  const searchParams = new URLSearchParams(location.search);
  const returnUrl = searchParams.get('returnUrl') || '/';

  // Redirect if already authenticated
  useEffect(() => {
    console.log('Login page redirect effect triggered', { isAuthenticated, returnUrl });
    if (isAuthenticated) {
      console.log('User is authenticated, navigating to:', returnUrl);
      navigate(returnUrl, { replace: true });
    }
  }, [isAuthenticated, navigate, returnUrl]);

  // Clear error on unmount and check for stale tokens on mount
  useEffect(() => {
    // Clear any potential stale token only when actively on the login page
    // and auth context has not yet confirmed authentication.
    // This helps prevent clearing tokens set by dev bypass immediately after a redirect.
    if (location.pathname === '/login' && localStorage.getItem(TOKEN_STORAGE_KEY) && !isAuthenticated) {
      console.log('Found potential stale token on login page (active path), clearing all tokens');
      cleanAuthStorage();
    }
    
    return () => {
      clearError();
    };
  }, [clearError, isAuthenticated, location.pathname]); // Added location.pathname to dependencies

  // Handle form submission for email/password login
  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    
    console.log('Login form submitted', { email });
    
    try {
      console.log('Calling login function');
      await login({
        email: email,
        password,
      });
      console.log('Login function completed');
      // Redirect handled by effect when isAuthenticated changes
    } catch (err) {
      // Error handling is done by the auth context
      console.error('Login failed:', err);
    }
  };

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background p-4">
      <div className="w-full max-w-md">
        <div className="mb-4 flex flex-col items-center">
          <div className="relative mb-2">
            <div className="flex flex-col items-center">
              <LogoIcon className="relative z-10" />
              <div className="absolute inset-x-0 bottom-0 h-4 bg-brass-gold/10 blur-md"></div>
            </div>
          </div>
        </div>

        {error && (
          <Alert variant="destructive" className="mb-4">
            <ExclamationTriangleIcon className="size-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        <div className="bg-card-background relative overflow-hidden rounded-md border border-army-tan/30 shadow-md">
          <form onSubmit={handleSubmit} className="space-y-4 p-5">
            <div className="mb-2">
              <h2 className="mb-2 text-center font-heading text-xl uppercase text-foreground">Welcome</h2>
              <div className="mx-auto h-0.5 w-16 bg-brass-gold"></div>
            </div>
            
            <div className="space-y-1.5">
              <label htmlFor="email" className="block text-sm font-medium uppercase tracking-wide text-tactical-gray">
                Email
              </label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full rounded border border-army-tan/50 p-2 font-sans text-sm"
                placeholder="you@example.com"
                autoComplete="email"
                aria-label="Email"
              />
            </div>
            
            <div className="space-y-1.5">
              <div className="flex justify-between">
                <label htmlFor="password" className="block text-sm font-medium uppercase tracking-wide text-tactical-gray">
                  Password
                </label>
                <Link to="/forgot-password" className="text-sm font-medium text-brass-gold hover:underline font-mono">
                  Forgot password?
                </Link>
              </div>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full rounded border border-army-tan/50 p-2 font-sans text-sm"
                placeholder="••••••••"
                autoComplete="current-password"
                aria-label="Password"
              />
            </div>

            <Button
              type="submit"
              className="w-full font-heading"
              disabled={isLoading}
            >
              {isLoading ? 'Signing in...' : 'Sign In'}
            </Button>
            
            <div className="relative my-4">
              <Separator className="absolute inset-0" />
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-card-background px-2 text-tactical-gray">or</span>
              </div>
            </div>
            
            {/* Social Login Buttons moved below regular login */}
            <SocialLoginButtons />
          </form>

          <div className="p-5 pt-0 text-center">
            <p className="text-sm text-muted-foreground font-mono">
              Don't have an account?{' '}
              <Link
                to="/register"
                className="text-brass-gold hover:underline font-mono"
              >
                Sign up
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;

// Add TypeScript interface for Google
declare global {
  interface Window {
    google: {
      accounts: {
        id: {
          initialize: (config: any) => void;
          renderButton: (element: HTMLElement, options: any) => void;
          prompt: () => void;
        };
      };
    };
  }
} 