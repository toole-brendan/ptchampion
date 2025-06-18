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
