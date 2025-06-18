import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { ChevronLeftIcon } from '@radix-ui/react-icons';
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
  const [gender, setGender] = useState<string>('');
  const [dateOfBirth, setDateOfBirth] = useState('');
  
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
        gender: gender || undefined,
        dateOfBirth: dateOfBirth || undefined,
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
    <div className="min-h-screen flex items-center justify-center bg-cream">
      <div className="w-full max-w-sm">
        <div className="flex flex-col items-center space-y-6">
          {/* Logo */}
          <div className="pt-5">
            <LogoIcon className="w-[150px] h-[150px] object-contain" />
          </div>

          {/* Heading */}
          <h1 className="font-heading text-heading1 uppercase text-brass-gold text-center mb-lg">
            CREATE ACCOUNT
          </h1>

          {/* Form */}
          <form onSubmit={handleSubmit} className="w-full space-y-4 px-6">
            {/* First Name */}
            <div className="space-y-1">
              <label 
                htmlFor="firstName" 
                className="label"
              >
                FIRST NAME
              </label>
              <input
                id="firstName"
                type="text"
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
                required
                className="w-full p-sm rounded-button bg-cream-dark text-deep-ops border border-deep-ops/50 focus:outline-none focus:ring-2 focus:ring-brass-gold"
              />
            </div>
            
            {/* Last Name */}
            <div className="space-y-1">
              <label 
                htmlFor="lastName" 
                className="label"
              >
                LAST NAME
              </label>
              <input
                id="lastName"
                type="text"
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
                required
                className="w-full p-sm rounded-button bg-cream-dark text-deep-ops border border-deep-ops/50 focus:outline-none focus:ring-2 focus:ring-brass-gold"
              />
            </div>
            
            {/* Email */}
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
            
            {/* Username */}
            <div className="space-y-1">
              <label 
                htmlFor="username" 
                className="label"
              >
                USERNAME
              </label>
              <input
                id="username"
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                autoComplete="username"
                className="w-full p-sm rounded-button bg-cream-dark text-deep-ops border border-deep-ops/50 focus:outline-none focus:ring-2 focus:ring-brass-gold"
              />
            </div>
            
            {/* Gender (Optional) */}
            <div className="space-y-1">
              <label 
                htmlFor="gender" 
                className="label"
              >
                GENDER (OPTIONAL - FOR USMC PFT SCORING)
              </label>
              <div className="flex items-center space-x-4 py-2">
                {['male', 'female'].map((option) => (
                  <button
                    key={option}
                    type="button"
                    onClick={() => setGender(option)}
                    className="flex items-center space-x-2"
                  >
                    <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                      gender === option 
                        ? 'border-brass-gold bg-brass-gold' 
                        : 'border-tactical-gray'
                    }`}>
                      {gender === option && (
                        <div className="w-2 h-2 rounded-full bg-cream"></div>
                      )}
                    </div>
                    <span className="label text-command-black capitalize">{option}</span>
                  </button>
                ))}
              </div>
            </div>
            
            {/* Date of Birth (Optional) */}
            <div className="space-y-1">
              <label 
                htmlFor="dateOfBirth" 
                className="label"
              >
                DATE OF BIRTH (OPTIONAL - FOR AGE-BASED SCORING)
              </label>
              <input
                id="dateOfBirth"
                type="date"
                value={dateOfBirth}
                onChange={(e) => setDateOfBirth(e.target.value)}
                max={new Date().toISOString().split('T')[0]}
                className="w-full p-sm rounded-button bg-cream-dark text-deep-ops border border-deep-ops/50 focus:outline-none focus:ring-2 focus:ring-brass-gold"
              />
            </div>
            
            {/* Password */}
            <div className="space-y-1">
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
                autoComplete="new-password"
                className="w-full p-sm rounded-button bg-cream-dark text-deep-ops border border-deep-ops/50 focus:outline-none focus:ring-2 focus:ring-brass-gold"
              />
              {passwordTooShort && (
                <p className="text-error text-sm mt-xs">
                  Password must be at least 8 characters.
                </p>
              )}
            </div>
            
            {/* Confirm Password */}
            <div className="space-y-1">
              <label 
                htmlFor="confirmPassword" 
                className="label"
              >
                CONFIRM PASSWORD
              </label>
              <input
                id="confirmPassword"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                autoComplete="new-password"
                className="w-full p-sm rounded-button bg-cream-dark text-deep-ops border border-deep-ops/50 focus:outline-none focus:ring-2 focus:ring-brass-gold"
              />
              {passwordMismatch && (
                <p className="text-error text-sm mt-xs">
                  Passwords do not match.
                </p>
              )}
            </div>
            
            {/* Error Message */}
            {error && (
              <p className="text-error text-sm mt-xs text-center">
                {error}
              </p>
            )}
            
            {/* Success Message */}
            {successMessage && (
              <div className="bg-success/10 text-success p-md rounded-card text-center font-semibold text-sm mt-xs">
                {successMessage}
              </div>
            )}
            
            {/* Register Button */}
            <button 
              type="submit" 
              disabled={!isFormValid || isLoading}
              className="btn-primary w-full mt-md uppercase font-semibold"
            >
              {isLoading ? 'CREATING ACCOUNT...' : 'CREATE ACCOUNT'}
            </button>
            
            {/* Back to Login Button */}
            <button
              type="button"
              onClick={() => navigate('/login')}
              className="btn-secondary w-full mt-sm flex items-center justify-center gap-2"
            >
              <ChevronLeftIcon className="w-4 h-4" />
              Back to Login
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default RegisterPage;
