import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { Button } from '../../components/ui/button';
import { MilitaryTextField } from '../../components/ui/text-field';
import { ChevronLeftIcon, PersonIcon, EnvelopeClosedIcon, LockClosedIcon, LockOpen2Icon, PersonIcon as Person2Icon, IdCardIcon } from '@radix-ui/react-icons';
import logoImage from '../../assets/pt_champion_logo_2.png';

// Real logo component
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <img 
    src={logoImage} 
    alt="PT Champion Logo" 
    className={className} 
  />
);

const RegisterPage: React.FC = () => {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [passwordMismatch, setPasswordMismatch] = useState(false);
  const [passwordTooShort, setPasswordTooShort] = useState(false);
  
  const [successMessage, setSuccessMessage] = useState('');
  
  const { register, isAuthenticated, isLoading, error, clearError } = useAuth();
  const navigate = useNavigate();

  // Check if form is valid
  const isFormValid = Boolean(
    email && password && confirmPassword &&
    firstName && lastName && username &&
    password === confirmPassword && password.length >= 8
  );

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

  const validatePasswords = (): boolean => {
    setPasswordTooShort(false);
    setPasswordMismatch(false);

    if (password.length < 8 && password.length > 0) {
      setPasswordTooShort(true);
    }

    if (password && confirmPassword && password !== confirmPassword) {
      setPasswordMismatch(true);
      return false;
    }
    
    return !passwordTooShort;
  };

  // Validate passwords on change
  useEffect(() => {
    if (password || confirmPassword) {
      validatePasswords();
    }
  }, [password, confirmPassword]);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    
    // Clear error and success message before submission
    clearError();
    setSuccessMessage('');
    
    // Validate passwords
    if (!validatePasswords()) {
      return;
    }
    
    try {
      await register({
        email: email,
        username: username,
        password: password,
        firstName: firstName,
        lastName: lastName,
      });
      
      // If successful, show success message
      setSuccessMessage('Registration successful! Please log in.');
      
      // Navigate to login after 2 seconds
      setTimeout(() => {
        navigate('/login');
      }, 2000);
    } catch (err) {
      // Error handling is done by the auth context
      console.error('Registration failed:', err);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center py-12 px-4 bg-cream">
      <div className="w-full max-w-md">
        <div className="space-y-8">
          {/* Logo */}
          <div className="flex justify-center pt-5">
            <LogoIcon className="w-[300px] h-[300px] object-contain" />
          </div>

          {/* Heading */}
          <h1 className="text-xl font-heading font-bold text-center text-command-black uppercase pb-2">
            Create Account
          </h1>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4 px-4">
            {/* First Name */}
            <MilitaryTextField
              id="firstName"
              label="FIRST NAME"
              value={firstName}
              onChange={(e) => setFirstName(e.target.value)}
              required
              fullWidth
              icon={<PersonIcon className="w-5 h-5" />}
              aria-label="First Name"
            />
            
            {/* Last Name */}
            <MilitaryTextField
              id="lastName"
              label="LAST NAME"
              value={lastName}
              onChange={(e) => setLastName(e.target.value)}
              required
              fullWidth
              icon={<Person2Icon className="w-5 h-5" />}
              aria-label="Last Name"
            />
            
            {/* Email */}
            <MilitaryTextField
              id="email"
              label="EMAIL"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              fullWidth
              icon={<EnvelopeClosedIcon className="w-5 h-5" />}
              keyboardType="email"
              autoComplete="email"
              aria-label="Email"
            />
            
            {/* Username */}
            <MilitaryTextField
              id="username"
              label="USERNAME"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              fullWidth
              icon={<IdCardIcon className="w-5 h-5" />}
              autoComplete="username"
              aria-label="Username"
            />
            
            {/* Password */}
            <div>
              <MilitaryTextField
                id="password"
                label="PASSWORD"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                fullWidth
                icon={<LockClosedIcon className="w-5 h-5" />}
                autoComplete="new-password"
                aria-label="Password"
              />
              {passwordTooShort && (
                <p className="mt-1 text-xs text-error">
                  Password must be at least 8 characters.
                </p>
              )}
            </div>
            
            {/* Confirm Password */}
            <div>
              <MilitaryTextField
                id="confirmPassword"
                label="CONFIRM PASSWORD"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                fullWidth
                icon={<LockOpen2Icon className="w-5 h-5" />}
                autoComplete="new-password"
                aria-label="Confirm Password"
              />
              {passwordMismatch && (
                <p className="mt-1 text-xs text-error">
                  Passwords do not match.
                </p>
              )}
            </div>
            
            {/* Error Message */}
            {error && (
              <p className="text-sm text-error text-center pt-1">
                {error}
              </p>
            )}
            
            {/* Success Message */}
            {successMessage && (
              <div className="bg-success/10 text-success p-3 rounded-lg text-center font-semibold text-sm">
                {successMessage}
              </div>
            )}
            
            {/* Register Button */}
            <div className="pt-2">
              <Button 
                type="submit" 
                variant="primary"
                fullWidth
                loading={isLoading}
                disabled={!isFormValid || isLoading}
                className="uppercase font-semibold"
                aria-label="Create Account"
              >
                {isLoading ? 'Creating Account...' : 'CREATE ACCOUNT'}
              </Button>
            </div>
            
            {/* Back to Login Button */}
            <div className="pt-2">
              <Button
                type="button"
                variant="secondary"
                fullWidth
                icon={<ChevronLeftIcon className="w-4 h-4" />}
                onClick={() => navigate('/login')}
                className="font-medium"
              >
                Back to Login
              </Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default RegisterPage;
