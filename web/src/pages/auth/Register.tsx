import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { Button } from '../../components/ui/button';
import { Input } from '../../components/ui/input';
import { Alert, AlertDescription } from '../../components/ui/alert';
import { ExclamationTriangleIcon } from '@radix-ui/react-icons';
import logoImage from '../../assets/pt_champion_logo_2.png';

// Real logo component
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <img src={logoImage} alt="PT Champion Logo" className={`${className} h-80 w-auto`} />
);

const RegisterPage: React.FC = () => {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [validationError, setValidationError] = useState<string | null>(null);
  
  const { register, isAuthenticated, isLoading, error, clearError } = useAuth();
  const navigate = useNavigate();

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  // Clear error on unmount
  useEffect(() => {
    return () => {
      clearError();
    };
  }, [clearError]);

  const validateForm = (): boolean => {
    // Clear previous validation errors
    setValidationError(null);
    
    // Check if passwords match
    if (password !== confirmPassword) {
      setValidationError("Passwords don't match");
      return false;
    }
    
    // Validate password strength (basic check - can be enhanced)
    if (password.length < 8) {
      setValidationError('Password must be at least 8 characters');
      return false;
    }
    
    // Check if all required fields are filled
    if (!firstName || !lastName || !email || !username || !password) {
      setValidationError('All fields are required');
      return false;
    }
    
    return true;
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    
    // Validate form before submission
    if (!validateForm()) {
      return;
    }
    
    try {
      await register({
        username: username,
        password,
        displayName: `${firstName} ${lastName}`,
        // We still collect email but don't send it to the API since it's not in the type
      });
      // Redirect handled by effect when isAuthenticated changes
    } catch (err) {
      // Error handling is done by the auth context
      console.error('Registration failed:', err);
    }
  };

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 flex flex-col items-center">
          <div className="relative mb-4">
            <LogoIcon className="relative z-10" />
            <div className="absolute bottom-0 left-0 right-0 h-8 bg-brass-gold/10 blur-md"></div>
          </div>
          <h1 className="font-heading text-heading2 uppercase text-command-black tracking-wider mb-2">PT Champion</h1>
          <p className="text-tactical-gray font-semibold text-sm uppercase tracking-wider">Fitness Evaluation System</p>
        </div>

        {(error || validationError) && (
          <Alert variant="destructive" className="mb-6">
            <ExclamationTriangleIcon className="size-4" />
            <AlertDescription>{error || validationError}</AlertDescription>
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
              <h2 className="font-heading text-heading4 text-center uppercase mb-2">Create Account</h2>
              <div className="h-[1px] w-24 bg-brass-gold mx-auto"></div>
            </div>
          
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label htmlFor="firstName" className="block text-sm font-semibold text-tactical-gray uppercase tracking-wide">
                  First Name
                </label>
                <Input
                  id="firstName"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  required
                  className="w-full rounded-input border border-army-tan/50 bg-cream p-3 font-mono"
                  placeholder="John"
                />
              </div>
              
              <div className="space-y-2">
                <label htmlFor="lastName" className="block text-sm font-semibold text-tactical-gray uppercase tracking-wide">
                  Last Name
                </label>
                <Input
                  id="lastName"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  required
                  className="w-full rounded-input border border-army-tan/50 bg-cream p-3 font-mono"
                  placeholder="Doe"
                />
              </div>
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
              <label htmlFor="username" className="block text-sm font-semibold text-tactical-gray uppercase tracking-wide">
                Username
              </label>
              <Input
                id="username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                className="w-full rounded-input border border-army-tan/50 bg-cream p-3 font-mono"
                placeholder="username"
                autoComplete="username"
              />
            </div>
            
            <div className="space-y-2">
              <label htmlFor="password" className="block text-sm font-semibold text-tactical-gray uppercase tracking-wide">
                Password
              </label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full rounded-input border border-army-tan/50 bg-cream p-3 font-mono"
                placeholder="••••••••"
                autoComplete="new-password"
              />
            </div>
            
            <div className="space-y-2">
              <label htmlFor="confirmPassword" className="block text-sm font-semibold text-tactical-gray uppercase tracking-wide">
                Confirm Password
              </label>
              <Input
                id="confirmPassword"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                className="w-full rounded-input border border-army-tan/50 bg-cream p-3 font-mono"
                placeholder="••••••••"
                autoComplete="new-password"
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
                  <span className="ml-2">CREATING ACCOUNT...</span>
                </>
              ) : (
                'CREATE ACCOUNT'
              )}
            </Button>
          </form>
        </div>

        <div className="mt-6 text-center">
          <p className="text-tactical-gray">
            Already have an account?{' '}
            <Link to="/login" className="text-brass-gold hover:underline font-semibold">
              Sign in
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default RegisterPage; 