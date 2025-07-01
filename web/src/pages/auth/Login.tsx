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
  const [logoClickCount, setLogoClickCount] = useState(0);
  const [demoLoading, setDemoLoading] = useState(false);
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
    // Only clear tokens if we're not loading and still not authenticated
    // This prevents clearing valid tokens while the user data is being fetched
    if (location.pathname === '/login' && localStorage.getItem(TOKEN_STORAGE_KEY) && !isAuthenticated && !isLoading) {
      console.log('Found potential stale token on login page (not loading), clearing all tokens');
      cleanAuthStorage();
    }
    
    return () => {
      clearError();
    };
  }, [clearError, isAuthenticated, isLoading, location.pathname]);

  // Handle logo click for secret login
  const handleLogoClick = async () => {
    const newCount = logoClickCount + 1;
    setLogoClickCount(newCount);
    
    if (newCount === 5) {
      console.log('Secret login activated!');
      try {
        // Login as test user
        await login({
          email: 'testuser@ptchampion.ai',
          password: 'TestUser123!',
        });
        console.log('Mock user login completed');
      } catch (err) {
        console.error('Mock login failed:', err);
      }
      // Reset count after attempting login
      setLogoClickCount(0);
    }
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
    } catch (err) {
      console.error('Login failed:', err);
    }
  };

  // Handle demo login
  const handleDemoLogin = async () => {
    console.log('Demo login initiated');
    setDemoLoading(true);
    
    // Set demo credentials
    const demoEmail = 'john.smith@example.com';
    const demoPassword = 'DemoUser123!';
    
    setEmail(demoEmail);
    setPassword(demoPassword);
    
    try {
      console.log('Calling login with demo credentials');
      await login({
        email: demoEmail,
        password: demoPassword,
      });
      console.log('Demo login completed');
    } catch (err) {
      console.error('Demo login failed:', err);
    } finally {
      setDemoLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-cream-light">
      <div className="w-full max-w-sm">
        <div className="flex flex-col items-center space-y-6">
          {/* Logo */}
          <div className="pt-10 cursor-pointer" onClick={handleLogoClick}>
            <LogoIcon className="w-[300px] h-[300px] object-contain" />
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="w-full space-y-4 px-6 pb-10">
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

            {/* Buttons Container */}
            <div className="space-y-3 mt-6">
              {/* Sign In Button */}
              <button
                type="submit"
                className="w-full bg-brass-gold text-white font-semibold py-3 px-4 rounded-lg hover:bg-brass-gold/90 focus:outline-none focus:ring-2 focus:ring-brass-gold transition-colors"
              >
                {isLoading ? 'SIGNING IN...' : 'SIGN IN'}
              </button>

              {/* Demo Button */}
              <button
                type="button"
                onClick={handleDemoLogin}
                disabled={isLoading || demoLoading}
                className="w-full border-2 border-brass-gold text-brass-gold font-semibold py-3 px-4 rounded-lg hover:bg-brass-gold/10 focus:outline-none focus:ring-2 focus:ring-brass-gold disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {demoLoading ? 'LOADING DEMO...' : 'DEMO'}
              </button>
            </div>

            {/* Error message */}
            {error && (
              <p className="text-error text-sm mt-2 text-center">{error}</p>
            )}
          </form>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
