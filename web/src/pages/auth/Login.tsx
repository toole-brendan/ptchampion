import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { Button } from '../../components/ui/button';
import { Input } from '../../components/ui/input';
import { Alert, AlertDescription } from '../../components/ui/alert';
import { ExclamationTriangleIcon } from '@radix-ui/react-icons';
import logoImage from '../../assets/pt_champion_logo_2.png';
import config from '../../lib/config';
import { cleanAuthStorage } from '../../lib/secureStorage';

// Get token storage key from config to ensure consistency
const TOKEN_STORAGE_KEY = config.auth.storageKeys.token;

// Real logo component
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <img src={logoImage} alt="PT Champion Logo" className={`${className} h-80 w-auto`} />
);

const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { login, isAuthenticated, isLoading, error, clearError } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  
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
    // Clear any potential stale token when login page is loaded
    if (localStorage.getItem(TOKEN_STORAGE_KEY) && !isAuthenticated) {
      console.log('Found potential stale token on login page, clearing all tokens');
      cleanAuthStorage();
    }
    
    return () => {
      clearError();
    };
  }, [clearError, isAuthenticated]);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    
    console.log('Login form submitted', { email });
    
    try {
      console.log('Calling login function');
      await login({
        username: email,
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
        <div className="mb-10 flex flex-col items-center">
          <div className="relative mb-4">
            <LogoIcon className="relative z-10" />
            <div className="bg-brass-gold/10 absolute inset-x-0 bottom-0 h-8 blur-md"></div>
          </div>
        </div>

        {error && (
          <Alert variant="destructive" className="mb-6">
            <ExclamationTriangleIcon className="size-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        <div className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
          {/* Military corner cutouts - top left and right */}
          <div className="absolute left-0 top-0 size-[15px] bg-background"></div>
          <div className="absolute right-0 top-0 size-[15px] bg-background"></div>
          
          {/* Military corner cutouts - bottom left and right */}
          <div className="absolute bottom-0 left-0 size-[15px] bg-background"></div>
          <div className="absolute bottom-0 right-0 size-[15px] bg-background"></div>
          
          {/* Diagonal lines for corners */}
          <div className="bg-tactical-gray/50 absolute left-0 top-0 h-px w-[15px] origin-top-left rotate-45"></div>
          <div className="bg-tactical-gray/50 absolute right-0 top-0 h-px w-[15px] origin-top-right -rotate-45"></div>
          <div className="bg-tactical-gray/50 absolute bottom-0 left-0 h-px w-[15px] origin-bottom-left -rotate-45"></div>
          <div className="bg-tactical-gray/50 absolute bottom-0 right-0 h-px w-[15px] origin-bottom-right rotate-45"></div>
          
          <form onSubmit={handleSubmit} className="space-y-6 p-content">
            <div className="mb-2">
              <h2 className="mb-2 text-center font-heading text-heading4 uppercase">Sign In</h2>
              <div className="mx-auto h-px w-16 bg-brass-gold"></div>
            </div>
            
            <div className="space-y-2">
              <label htmlFor="email" className="block font-semibold text-sm uppercase tracking-wide text-tactical-gray">
                Email
              </label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="border-army-tan/50 w-full rounded-input border bg-cream p-3 font-mono"
                placeholder="you@example.com"
                autoComplete="email"
              />
            </div>
            
            <div className="space-y-2">
              <div className="flex justify-between">
                <label htmlFor="password" className="block font-semibold text-sm uppercase tracking-wide text-tactical-gray">
                  Password
                </label>
                <Link to="/forgot-password" className="font-semibold text-sm text-brass-gold hover:underline">
                  Forgot password?
                </Link>
              </div>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="border-army-tan/50 w-full rounded-input border bg-cream p-3 font-mono"
                placeholder="••••••••"
                autoComplete="current-password"
              />
            </div>
            
            <Button 
              type="submit" 
              className="w-full font-heading shadow-medium transition-all hover:shadow-large" 
              disabled={isLoading}
            >
              {isLoading ? (
                <>
                  <div className="size-4 animate-spin rounded-full border-2 border-t-transparent" />
                  <span className="ml-2">SIGNING IN...</span>
                </>
              ) : (
                'SIGN IN'
              )}
            </Button>
          </form>
        </div>

        <div className="mt-6 text-center">
          <p className="text-tactical-gray">
            Don't have an account?{' '}
            <Link to="/register" className="font-semibold text-brass-gold hover:underline">
              Sign up
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage; 