import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { Button } from '../../components/ui/button';
import { TextField } from '../../components/ui/text-field';
import { Alert, AlertDescription } from '../../components/ui/alert';
import { Card, CardContent } from '../../components/ui/card';
import { Separator } from '../../components/ui/separator';
import { SectionContainer, ContentSection } from '../../components/ui/section-container';
import { ExclamationTriangleIcon } from '@radix-ui/react-icons';
import logoImage from '../../assets/pt_champion_logo_2.png';
import config from '../../lib/config';
import { cleanAuthStorage } from '../../lib/secureStorage';
import SocialLoginButtons from '../../components/auth/SocialLoginButtons';

// Get token storage key from config to ensure consistency
const TOKEN_STORAGE_KEY = config.auth.storageKeys.token;

// Real logo component
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <img 
    src={logoImage} 
    alt="PT Champion Logo" 
    className={className} 
  />
);

// OAuth configuration
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
    if (location.pathname === '/login' && localStorage.getItem(TOKEN_STORAGE_KEY) && !isAuthenticated) {
      console.log('Found potential stale token on login page (active path), clearing all tokens');
      cleanAuthStorage();
    }
    
    return () => {
      clearError();
    };
  }, [clearError, isAuthenticated, location.pathname]);

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
    } catch (err) {
      console.error('Login failed:', err);
    }
  };

  return (
    <div className="min-h-screen bg-cream flex items-center justify-center p-4">
      <div className="w-full max-w-sm">
        <div className="flex flex-col items-center space-y-6">
          {/* Logo */}
          <div className="pt-10">
            <LogoIcon className="w-[300px] h-[300px] object-contain" />
          </div>

          {/* Welcome Text */}
          <div className="flex flex-col items-center space-y-2 pb-2">
            <h1 className="font-heading text-2xl uppercase text-command-black">
              Welcome
            </h1>
            <div className="w-16 h-0.5 bg-brass-gold"></div>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="w-full space-y-4 px-6">
            {/* Email Field */}
            <div className="space-y-1">
              <label 
                htmlFor="email" 
                className="block text-xs font-medium uppercase tracking-wider text-command-black"
              >
                Email
              </label>
              <TextField
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                fullWidth
                autoComplete="email"
                placeholder=""
                className="border-tactical-gray/30 focus:border-brass-gold bg-white"
              />
            </div>

            {/* Password Field */}
            <div className="space-y-1">
              <div className="flex justify-between items-center">
                <label 
                  htmlFor="password" 
                  className="block text-xs font-medium uppercase tracking-wider text-command-black"
                >
                  Password
                </label>
                <Link 
                  to="/forgot-password" 
                  className="text-xs font-mono text-brass-gold hover:underline"
                >
                  Forgot password?
                </Link>
              </div>
              <TextField
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                fullWidth
                autoComplete="current-password"
                placeholder=""
                className="border-tactical-gray/30 focus:border-brass-gold bg-white"
              />
            </div>

            {/* Login Button */}
            <Button
              type="submit"
              variant="primary"
              fullWidth
              loading={isLoading}
              disabled={!email || !password}
              className="mt-4 uppercase"
            >
              Log In
            </Button>

            {/* Register Link */}
            <div className="flex justify-center items-center space-x-1 pt-2">
              <span className="text-xs font-mono text-tactical-gray">
                Don't have an account?
              </span>
              <Link
                to="/register"
                className="text-xs font-mono text-brass-gold hover:underline"
              >
                Sign up
              </Link>
            </div>

            {/* Separator */}
            <div className="relative py-4">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-tactical-gray/30"></div>
              </div>
              <div className="relative flex justify-center text-xs">
                <span className="bg-cream px-2 text-tactical-gray">
                  or continue with
                </span>
              </div>
            </div>

            {/* Social Login Buttons */}
            <div className="space-y-3">
              {/* Sign in with Apple */}
              <button
                type="button"
                className="w-full h-12 bg-black text-white rounded-lg font-medium flex items-center justify-center space-x-2 hover:bg-black/90 transition-colors"
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701"/>
                </svg>
                <span>Sign in with Apple</span>
              </button>

              {/* Sign in with Google */}
              <button
                type="button"
                className="w-full h-12 bg-white text-black/87 rounded-lg font-medium flex items-center justify-center space-x-2 border border-gray-200 hover:bg-gray-50 transition-colors"
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                </svg>
                <span>Sign in with Google</span>
              </button>
            </div>

            {/* Error message */}
            {error && (
              <Alert variant="destructive" className="mt-4">
                <ExclamationTriangleIcon className="size-4" />
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}
          </form>
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
