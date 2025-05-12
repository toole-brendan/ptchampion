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
import DeveloperMenu from '../../components/ui/DeveloperMenu';

// Get token storage key from config to ensure consistency
const TOKEN_STORAGE_KEY = config.auth.storageKeys.token;

// Is this a development build?
const IS_DEV = true; // Always enable for testing

// Real logo component
const LogoIcon: React.FC<{ className?: string; onClick?: () => void }> = ({ className, onClick }) => (
  <img 
    src={logoImage} 
    alt="PT Champion Logo" 
    className={`${className} max-h-80 w-auto cursor-pointer`} 
    onClick={onClick}
  />
);

const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [logoTaps, setLogoTaps] = useState(0);
  const [showDevMenu, setShowDevMenu] = useState(false);
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

  const handleLogoClick = () => {
    // Increment tap counter regardless of dev mode
    const newCount = logoTaps + 1;
    setLogoTaps(newCount);
    console.log(`Logo tapped ${newCount} times`);
    
    // Show developer menu after 5 taps
    if (newCount >= 5) {
      console.log('Activating developer menu');
      setShowDevMenu(true);
      setLogoTaps(0);
    }
  };

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
        <div className="mb-4 flex flex-col items-center">
          <div className="relative mb-2">
            <div 
              className="flex cursor-pointer flex-col items-center" 
              onClick={handleLogoClick}
              style={{ position: 'relative' }}
            >
              <LogoIcon className="relative z-10" />
              {logoTaps > 0 && (
                <div className="absolute right-0 top-0 z-20 flex size-8 items-center justify-center rounded-full bg-brass-gold text-white">
                  {logoTaps}
                </div>
              )}
              <div className="mt-1 text-center font-semibold text-xs text-brass-gold">
                Tap for developer menu ({logoTaps}/5)
              </div>
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
              <h2 className="mb-2 text-center font-heading text-xl uppercase text-foreground">Welcome Back</h2>
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
                className="w-full rounded border border-army-tan/50 p-2 font-mono text-sm"
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
                <Link to="/forgot-password" className="text-sm font-medium text-brass-gold hover:underline">
                  Forgot password?
                </Link>
              </div>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full rounded border border-army-tan/50 p-2 font-mono text-sm"
                placeholder="••••••••"
                autoComplete="current-password"
                aria-label="Password"
              />
            </div>
            
            <Button 
              type="submit" 
              className="mt-2 w-full bg-brass-gold font-heading text-sm uppercase text-white shadow-sm transition-all hover:bg-brass-gold/90" 
              disabled={isLoading}
              aria-label="Sign in"
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

        <div className="mt-4 text-center">
          <p className="text-tactical-gray">
            Don't have an account?{' '}
            <Link to="/register" className="font-medium text-brass-gold hover:underline">
              Sign up
            </Link>
          </p>
        </div>
      </div>
      
      {/* Developer Menu */}
      <DeveloperMenu isOpen={showDevMenu} onClose={() => setShowDevMenu(false)} />
    </div>
  );
};

export default LoginPage; 