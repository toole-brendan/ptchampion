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

interface LocationState {
  from?: string;
}

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
            <div className="absolute bottom-0 left-0 right-0 h-8 bg-brass-gold/10 blur-md"></div>
          </div>
          <h1 className="font-heading text-heading2 uppercase text-command-black tracking-wider mb-2">PT Champion</h1>
          <p className="text-tactical-gray font-semibold text-sm uppercase tracking-wider">Fitness Evaluation System</p>
        </div>

        {error && (
          <Alert variant="destructive" className="mb-6">
            <ExclamationTriangleIcon className="size-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        <div className="bg-card-background rounded-card shadow-medium overflow-hidden relative">
          {/* Military corner cutouts - top left and right */}
          <div className="absolute top-0 left-0 w-[15px] h-[15px] bg-background"></div>
          <div className="absolute top-0 right-0 w-[15px] h-[15px] bg-background"></div>
          
          {/* Military corner cutouts - bottom left and right */}
          <div className="absolute bottom-0 left-0 w-[15px] h-[15px] bg-background"></div>
          <div className="absolute bottom-0 right-0 w-[15px] h-[15px] bg-background"></div>
          
          {/* Diagonal lines for corners */}
          <div className="absolute top-0 left-0 w-[15px] h-[1px] bg-tactical-gray/50 rotate-45 origin-top-left"></div>
          <div className="absolute top-0 right-0 w-[15px] h-[1px] bg-tactical-gray/50 -rotate-45 origin-top-right"></div>
          <div className="absolute bottom-0 left-0 w-[15px] h-[1px] bg-tactical-gray/50 -rotate-45 origin-bottom-left"></div>
          <div className="absolute bottom-0 right-0 w-[15px] h-[1px] bg-tactical-gray/50 rotate-45 origin-bottom-right"></div>
          
          <form onSubmit={handleSubmit} className="space-y-6 p-content">
            <div className="mb-2">
              <h2 className="font-heading text-heading4 text-center uppercase mb-2">Sign In</h2>
              <div className="h-[1px] w-16 bg-brass-gold mx-auto"></div>
            </div>
            
            <div className="space-y-2">
              <label htmlFor="email" className="block text-sm font-semibold text-tactical-gray uppercase tracking-wide">
                Email
              </label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full rounded-input border border-army-tan/50 bg-cream p-3 font-mono"
                placeholder="you@example.com"
                autoComplete="email"
              />
            </div>
            
            <div className="space-y-2">
              <div className="flex justify-between">
                <label htmlFor="password" className="block text-sm font-semibold text-tactical-gray uppercase tracking-wide">
                  Password
                </label>
                <Link to="/forgot-password" className="text-sm text-brass-gold hover:underline font-semibold">
                  Forgot password?
                </Link>
              </div>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full rounded-input border border-army-tan/50 bg-cream p-3 font-mono"
                placeholder="••••••••"
                autoComplete="current-password"
              />
            </div>
            
            <Button 
              type="submit" 
              className="w-full shadow-medium hover:shadow-large transition-all font-heading" 
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
            <Link to="/register" className="text-brass-gold hover:underline font-semibold">
              Sign up
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage; 