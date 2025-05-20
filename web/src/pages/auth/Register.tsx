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
  <img 
    src={logoImage} 
    alt="PT Champion Logo" 
    className={`${className} max-h-48 w-auto`} 
  />
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
      const registerResponse = await register({
        email: email,
        username: username,
        password: password,
        firstName: firstName,
        lastName: lastName,
        // Remove setting displayName separately as backend now uses username
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
        <div className="mb-4 flex flex-col items-center">
          <div className="relative mb-2">
            <div className="flex flex-col items-center">
              <LogoIcon className="relative z-10" />
              <div className="absolute inset-x-0 bottom-0 h-4 bg-brass-gold/10 blur-md"></div>
            </div>
          </div>
        </div>

        {(error || validationError) && (
          <Alert variant="destructive" className="mb-4">
            <ExclamationTriangleIcon className="size-4" />
            <AlertDescription>{error || validationError}</AlertDescription>
          </Alert>
        )}

        <div className="bg-card-background relative overflow-hidden rounded-md border border-army-tan/30 shadow-md">
          <form onSubmit={handleSubmit} className="space-y-4 p-5">
            <div className="mb-2">
              <h2 className="mb-2 text-center font-heading text-xl uppercase text-foreground">Create Account</h2>
              <div className="mx-auto h-0.5 w-24 bg-brass-gold"></div>
            </div>
          
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <label htmlFor="firstName" className="block text-sm font-medium uppercase tracking-wide text-tactical-gray font-jost">
                  FIRST NAME
                </label>
                <Input
                  id="firstName"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  required
                  className="w-full rounded border border-army-tan/50 p-2 font-sans text-sm"
                  placeholder=""
                  aria-label="First Name"
                />
              </div>
              
              <div className="space-y-1.5">
                <label htmlFor="lastName" className="block text-sm font-medium uppercase tracking-wide text-tactical-gray font-jost">
                  LAST NAME
                </label>
                <Input
                  id="lastName"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  required
                  className="w-full rounded border border-army-tan/50 p-2 font-sans text-sm"
                  placeholder=""
                  aria-label="Last Name"
                />
              </div>
            </div>
            
            <div className="space-y-1.5">
              <label htmlFor="email" className="block text-sm font-medium uppercase tracking-wide text-tactical-gray font-jost">
                EMAIL
              </label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full rounded border border-army-tan/50 p-2 font-sans text-sm"
                placeholder=""
                autoComplete="email"
                aria-label="Email"
              />
            </div>
            
            <div className="space-y-1.5">
              <label htmlFor="username" className="block text-sm font-medium uppercase tracking-wide text-tactical-gray font-jost">
                USERNAME
              </label>
              <Input
                id="username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                className="w-full rounded border border-army-tan/50 p-2 font-sans text-sm"
                placeholder=""
                autoComplete="username"
                aria-label="Username"
              />
            </div>
            
            <div className="space-y-1.5">
              <label htmlFor="password" className="block text-sm font-medium uppercase tracking-wide text-tactical-gray font-jost">
                PASSWORD
              </label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full rounded border border-army-tan/50 p-2 font-sans text-sm"
                placeholder=""
                autoComplete="new-password"
                aria-label="Password"
              />
            </div>
            
            <div className="space-y-1.5">
              <label htmlFor="confirmPassword" className="block text-sm font-medium uppercase tracking-wide text-tactical-gray font-jost">
                CONFIRM PASSWORD
              </label>
              <Input
                id="confirmPassword"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                className="w-full rounded border border-army-tan/50 p-2 font-sans text-sm"
                placeholder=""
                autoComplete="new-password"
                aria-label="Confirm Password"
              />
            </div>
            
            <Button 
              type="submit" 
              className="mt-2 w-full bg-brass-gold font-heading font-jost text-sm uppercase text-white shadow-sm transition-all hover:bg-brass-gold/90" 
              disabled={isLoading}
              aria-label="Create Account"
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

        <div className="mt-4 text-center">
          <p className="text-xs text-tactical-gray font-mono tracking-wider">
            Already have an account?{' '}
            <Link to="/login" className="font-mono text-brass-gold hover:underline">
              Sign in
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default RegisterPage; 