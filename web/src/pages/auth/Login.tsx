import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import logoImage from '../../assets/pt_champion_logo_2.png';
import config from '../../lib/config';
import { cleanAuthStorage } from '../../lib/secureStorage';

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
    <div className="min-h-screen flex flex-col items-center justify-center bg-cream">
      <div className="w-full max-w-sm">
        <div className="flex flex-col items-center space-y-6">
          {/* Logo */}
          <div className="pt-10">
            <LogoIcon className="w-[200px] h-[200px] object-contain" />
          </div>

          {/* Welcome Text */}
          <div className="flex flex-col items-center space-y-2 pb-2">
            <h1 className="font-heading text-heading1 uppercase text-brass-gold text-center mb-lg">
              SIGN IN
            </h1>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="w-full space-y-4 px-6">
            {/* Email Field */}
            <div className="space-y-1">
              <label 
                htmlFor="email" 
                className="label"
              >
                EMAIL ADDRESS
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                className="w-full p-sm rounded-button bg-cream-dark text-deep-ops border border-deep-ops/50 focus:outline-none focus:ring-2 focus:ring-brass-gold"
              />
            </div>

            {/* Password Field */}
            <div className="space-y-1 mb-md">
              <label 
                htmlFor="password" 
                className="label"
              >
                PASSWORD
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="current-password"
                className="w-full p-sm rounded-button bg-cream-dark text-deep-ops border border-deep-ops/50 focus:outline-none focus:ring-2 focus:ring-brass-gold"
              />
              <div className="w-full text-right mt-xs">
                <Link 
                  to="/forgot-password" 
                  className="text-sm text-olive-mist hover:text-brass-gold hover:underline"
                >
                  Forgot Password?
                </Link>
              </div>
            </div>

            {/* Login Button */}
            <button
              type="submit"
              disabled={!email || !password || isLoading}
              className="btn-primary w-full mt-md uppercase font-semibold"
            >
              {isLoading ? 'SIGNING IN...' : 'SIGN IN'}
            </button>

            {/* Register Link */}
            <p className="text-center text-sm mt-sm text-deep-ops">
              Don't have an account? 
              <Link to="/register" className="text-brass-gold font-semibold hover:underline"> Sign Up</Link>
            </p>

            {/* Separator */}
            <div className="flex items-center my-md">
              <div className="h-px flex-1 bg-olive-mist opacity-50"></div>
              <span className="px-sm text-olive-mist text-sm font-semibold">OR</span>
              <div className="h-px flex-1 bg-olive-mist opacity-50"></div>
            </div>

            {/* Social Login Buttons */}
            <div className="space-y-3">
              {/* Sign in with Apple */}
              <button
                type="button"
                className="w-full flex items-center justify-center bg-deep-ops text-cream font-semibold py-sm px-md rounded-button shadow-small hover:bg-deep-ops/90 focus-visible:ring-2 focus-visible:ring-brass-gold"
              >
                <svg className="h-5 w-5 mr-sm fill-current" viewBox="0 0 24 24">
                  <path d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701"/>
                </svg>
                Continue with Apple
              </button>

              {/* Sign in with Google */}
              <button
                type="button"
                className="w-full flex items-center justify-center bg-cream text-deep-ops font-semibold py-sm px-md rounded-button border border-tactical-gray hover:bg-olive-mist/20 focus-visible:ring-2 focus-visible:ring-brass-gold mt-sm"
              >
                <svg className="h-5 w-5 mr-sm" viewBox="0 0 24 24">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                </svg>
                Continue with Google
              </button>
            </div>

            {/* Error message */}
            {error && (
              <p className="text-error text-sm mt-xs text-center">{error}</p>
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
