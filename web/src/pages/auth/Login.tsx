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

  // Initialize Google Sign-In
  useEffect(() => {
    // Load Google Identity Services script
    if (GOOGLE_CLIENT_ID) {
      const script = document.createElement('script');
      script.src = 'https://accounts.google.com/gsi/client';
      script.async = true;
      script.defer = true;
      script.onload = initializeGoogleSignIn;
      document.body.appendChild(script);

      return () => {
        document.body.removeChild(script);
      };
    }
  }, []);

  // Initialize Google Sign-In
  const initializeGoogleSignIn = useCallback(() => {
    if (window.google && GOOGLE_CLIENT_ID) {
      window.google.accounts.id.initialize({
        client_id: GOOGLE_CLIENT_ID,
        callback: handleGoogleSignIn,
        auto_select: false,
      });

      // Render the Google Sign-In button
      window.google.accounts.id.renderButton(
        document.getElementById('google-signin-button')!,
        { 
          type: 'standard', 
          theme: 'outline',
          size: 'large',
          width: document.getElementById('google-signin-button')!.offsetWidth,
          text: 'signin_with'
        }
      );
    }
  }, []);

  // Handle Google Sign-In response
  const handleGoogleSignIn = async (response: any) => {
    console.log('Google sign-in response:', response);
    if (response.credential) {
      try {
        setIsSocialSigningIn(true);
        await loginWithSocial({
          provider: 'google',
          token: response.credential,
        });
      } catch (error) {
        console.error('Google sign-in error:', error);
      } finally {
        setIsSocialSigningIn(false);
      }
    }
  };

  // Handle Apple Sign-In
  const initiateAppleSignIn = () => {
    if (!APPLE_SERVICE_ID) {
      console.error('Apple Service ID not configured');
      return;
    }

    setIsSocialSigningIn(true);
    
    // Build Apple OAuth URL
    const appleAuthUrl = new URL('https://appleid.apple.com/auth/authorize');
    appleAuthUrl.searchParams.append('client_id', APPLE_SERVICE_ID);
    appleAuthUrl.searchParams.append('redirect_uri', REDIRECT_URI);
    appleAuthUrl.searchParams.append('response_type', 'code id_token');
    appleAuthUrl.searchParams.append('scope', 'name email');
    appleAuthUrl.searchParams.append('response_mode', 'form_post');
    
    // Add state parameter for CSRF protection
    const state = Math.random().toString(36).substring(2, 15);
    localStorage.setItem('apple_auth_state', state);
    appleAuthUrl.searchParams.append('state', state);
    
    // Redirect to Apple's authentication page
    window.location.href = appleAuthUrl.toString();
  };

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
              <h2 className="mb-2 text-center font-heading text-xl uppercase text-foreground">Welcome Back</h2>
              <div className="mx-auto h-0.5 w-16 bg-brass-gold"></div>
            </div>
            
            {/* Social Sign-In Buttons */}
            <div className="space-y-3">
              {/* Google Sign-In Button (rendered by Google SDK) */}
              <div 
                id="google-signin-button"
                className="w-full h-10 rounded border border-army-tan/50"
              ></div>
              
              {/* Apple Sign-In Button */}
              <Button
                type="button"
                className="w-full h-10 bg-black text-white font-sans flex items-center justify-center gap-2 hover:bg-gray-800"
                onClick={initiateAppleSignIn}
                disabled={isLoading || isSocialSigningIn}
              >
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701z"/>
                </svg>
                Sign in with Apple
              </Button>
            </div>
            
            <div className="relative my-4">
              <Separator className="absolute inset-0" />
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-card-background px-2 text-tactical-gray">or continue with</span>
              </div>
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
                className="w-full rounded border border-army-tan/50 p-2 font-sans text-sm"
                placeholder="••••••••"
                autoComplete="current-password"
                aria-label="Password"
              />
            </div>
            
            <Button 
              type="submit" 
              className="mt-2 w-full bg-brass-gold font-heading text-sm uppercase text-white shadow-sm transition-all hover:bg-brass-gold/90" 
              disabled={isLoading || isSocialSigningIn}
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
    </div>
  );
};

// Add Google global type definition
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

export default LoginPage; 