import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
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
    <div className="min-h-screen flex items-center justify-center bg-cream-light">
      <div className="w-full max-w-sm">
        <div className="flex flex-col items-center space-y-6">
          {/* Logo */}
          <div className="pt-5">
            <LogoIcon className="w-[150px] h-[150px] object-contain" />
          </div>

          {/* Heading */}
          <div className="flex flex-col items-center space-y-2 pb-4">
            <h1 className="font-heading text-4xl text-command-black text-center">
              Create Account
            </h1>
            <div className="w-16 h-0.5 bg-brass-gold"></div>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="w-full space-y-4 px-6">
            {/* First Name */}
            <div className="space-y-1">
              <label 
                htmlFor="firstName" 
                className="block text-xs font-medium uppercase tracking-wider text-tactical-gray"
              >
                FIRST NAME
              </label>
              <input
                id="firstName"
                type="text"
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
                required
                className="w-full px-4 py-3 rounded-lg bg-white text-deep-ops border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:border-transparent"
              />
            </div>
            
            {/* Last Name */}
            <div className="space-y-1">
              <label 
                htmlFor="lastName" 
                className="block text-xs font-medium uppercase tracking-wider text-tactical-gray"
              >
                LAST NAME
              </label>
              <input
                id="lastName"
                type="text"
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
                required
                className="w-full px-4 py-3 rounded-lg bg-white text-deep-ops border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:border-transparent"
              />
            </div>
            
            {/* Email */}
            <div className="space-y-1">
              <label 
                htmlFor="email" 
                className="block text-xs font-medium uppercase tracking-wider text-tactical-gray"
              >
                EMAIL
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                className="w-full px-4 py-3 rounded-lg bg-white text-deep-ops border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:border-transparent"
              />
            </div>
            
            {/* Username */}
            <div className="space-y-1">
              <label 
                htmlFor="username" 
                className="block text-xs font-medium uppercase tracking-wider text-tactical-gray"
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
                className="w-full px-4 py-3 rounded-lg bg-white text-deep-ops border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:border-transparent"
              />
            </div>
            
            {/* Gender (Optional) */}
            <div className="space-y-1">
              <label 
                htmlFor="gender" 
                className="block text-xs font-medium uppercase tracking-wider text-tactical-gray"
              >
                GENDER (OPTIONAL)
              </label>
              <select
                id="gender"
                value={gender}
                onChange={(e) => setGender(e.target.value)}
                className="w-full px-4 py-3 rounded-lg bg-white text-deep-ops border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:border-transparent"
              >
                <option value="">Select gender</option>
                <option value="male">Male</option>
                <option value="female">Female</option>
              </select>
            </div>
            
            {/* Date of Birth (Optional) */}
            <div className="space-y-1">
              <label 
                htmlFor="dateOfBirth" 
                className="block text-xs font-medium uppercase tracking-wider text-tactical-gray"
              >
                DATE OF BIRTH (OPTIONAL)
              </label>
              <input
                id="dateOfBirth"
                type="date"
                value={dateOfBirth}
                onChange={(e) => setDateOfBirth(e.target.value)}
                max={new Date().toISOString().split('T')[0]}
                className="w-full px-4 py-3 rounded-lg bg-white text-deep-ops border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:border-transparent"
              />
            </div>
            
            {/* Password */}
            <div className="space-y-1">
              <label 
                htmlFor="password" 
                className="block text-xs font-medium uppercase tracking-wider text-tactical-gray"
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
                className="w-full px-4 py-3 rounded-lg bg-white text-deep-ops border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:border-transparent"
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
                className="block text-xs font-medium uppercase tracking-wider text-tactical-gray"
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
                className="w-full px-4 py-3 rounded-lg bg-white text-deep-ops border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:border-transparent"
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
              <div className="bg-green-50 text-green-700 p-3 rounded-lg text-center font-semibold text-sm mt-2">
                {successMessage}
              </div>
            )}
            
            {/* Register Button */}
            <button 
              type="submit" 
              disabled={!isFormValid || isLoading}
              className="w-full bg-brass-gold text-white font-semibold py-3 px-4 rounded-lg hover:bg-brass-gold/90 focus:outline-none focus:ring-2 focus:ring-brass-gold disabled:opacity-50 disabled:cursor-not-allowed transition-colors mt-6"
            >
              {isLoading ? 'CREATING ACCOUNT...' : 'CREATE ACCOUNT'}
            </button>
            
            {/* Back to Login Button */}
            <p className="text-center text-sm mt-6 text-tactical-gray">
              Already have an account?{' '}
              <Link to="/login" className="text-brass-gold hover:underline">Log in</Link>
            </p>
          </form>
        </div>
      </div>
    </div>
  );
};

export default RegisterPage;
