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
    <div className="min-h-screen flex flex-col items-center justify-center bg-cream-light">
      <div className="w-full max-w-sm">
        <div className="flex flex-col items-center space-y-6">
          {/* Logo */}
          <div className="pt-10">
            <LogoIcon className="w-[400px] h-[400px] object-contain" />
          </div>

          {/* Welcome Text */}
          <div className="flex flex-col items-center space-y-2 pb-4">
            <h1 className="font-heading text-4xl text-command-black text-center">
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
                className="block text-xs font-medium uppercase tracking-wider text-tactical-gray"
              >
                EMAIL
              </label>
              <div className="relative">
                <input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  autoComplete="email"
                  className="w-full pl-4 pr-12 py-3 rounded-lg bg-white text-deep-ops border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:border-transparent"
                />
                <svg className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-tactical-gray" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
              </div>
            </div>

            {/* Password Field */}
            <div className="space-y-1 mb-md">
              <div className="flex justify-between items-center">
                <label 
                  htmlFor="password" 
                  className="block text-xs font-medium uppercase tracking-wider text-tactical-gray"
                >
                  PASSWORD
                </label>
                <Link 
                  to="/forgot-password" 
                  className="text-xs text-tactical-gray hover:text-deep-ops hover:underline"
                >
                  Forgot password?
                </Link>
              </div>
              <div className="relative">
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  autoComplete="current-password"
                  className="w-full pl-4 pr-12 py-3 rounded-lg bg-white text-deep-ops border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:border-transparent"
                />
                <svg className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-tactical-gray" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
            </div>

            {/* Login Button */}
            <button
              type="submit"
              disabled={!email || !password || isLoading}
              className="w-full bg-tactical-gray text-white font-semibold py-3 px-4 rounded-lg hover:bg-tactical-gray/90 focus:outline-none focus:ring-2 focus:ring-brass-gold disabled:opacity-50 disabled:cursor-not-allowed transition-colors mt-6"
            >
              {isLoading ? 'LOGGING IN...' : 'LOG IN'}
            </button>

            {/* Register Link */}
            <p className="text-center text-sm mt-6 text-tactical-gray">
              Don't have an account?{' '}
              <Link to="/register" className="text-tactical-gray hover:text-deep-ops hover:underline">Sign up</Link>
            </p>

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
