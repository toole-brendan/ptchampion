import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { Button } from '../../components/ui/button';
import { MilitaryTextField } from '../../components/ui/text-field';
import { Alert, AlertDescription } from '../../components/ui/alert';
import { Card, CardContent } from '../../components/ui/card';
import { MilitarySeparator } from '../../components/ui/separator';
import { SectionContainer, ContentSection } from '../../components/ui/section-container';
import { Badge } from '../../components/ui/badge';
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
      });
      // Redirect handled by effect when isAuthenticated changes
    } catch (err) {
      // Error handling is done by the auth context
      console.error('Registration failed:', err);
    }
  };

  return (
    <SectionContainer className="min-h-screen flex items-center justify-center py-12">
      <ContentSection className="w-full max-w-md">
        <div className="mb-6 flex flex-col items-center">
          <div className="relative mb-2">
            <div className="flex flex-col items-center">
              <LogoIcon className="relative z-10" />
              <div className="absolute inset-x-0 bottom-0 h-4 bg-brass-gold/10 blur-md"></div>
            </div>
          </div>
          <Badge variant="military" className="mt-2">
            FITNESS EVALUATION SYSTEM
          </Badge>
        </div>

        {(error || validationError) && (
          <Alert variant="destructive" className="mb-4">
            <ExclamationTriangleIcon className="size-4" />
            <AlertDescription>{error || validationError}</AlertDescription>
          </Alert>
        )}

        <Card variant="elevated" className="border-tactical-gray/20">
          <CardContent className="p-0">
            <form onSubmit={handleSubmit} className="space-y-4 p-6">
              <div className="mb-6">
                <h2 className="mb-2 text-center font-heading text-2xl uppercase text-command-black">
                  Create Account
                </h2>
                <MilitarySeparator className="mx-auto w-32" />
              </div>
            
              <div className="grid grid-cols-2 gap-3">
                <MilitaryTextField
                  id="firstName"
                  label="First Name"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  required
                  fullWidth
                  aria-label="First Name"
                />
                
                <MilitaryTextField
                  id="lastName"
                  label="Last Name"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  required
                  fullWidth
                  aria-label="Last Name"
                />
              </div>
              
              <MilitaryTextField
                id="email"
                label="Service Email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                fullWidth
                autoComplete="email"
                aria-label="Email"
              />
              
              <MilitaryTextField
                id="username"
                label="Username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                fullWidth
                autoComplete="username"
                aria-label="Username"
                helperText="This will be your display name"
              />
              
              <MilitaryTextField
                id="password"
                label="Password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                fullWidth
                autoComplete="new-password"
                aria-label="Password"
                helperText="Minimum 8 characters"
              />
              
              <MilitaryTextField
                id="confirmPassword"
                label="Confirm Password"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                fullWidth
                autoComplete="new-password"
                aria-label="Confirm Password"
              />
              
              <Button 
                type="submit" 
                variant="primary"
                fullWidth
                loading={isLoading}
                className="mt-6"
                aria-label="Create Account"
              >
                {isLoading ? 'Creating Account...' : 'Create Account'}
              </Button>
            </form>

            <div className="border-t border-tactical-gray/10 bg-cream/50 p-6 text-center">
              <p className="text-sm text-tactical-gray font-mono tracking-wider">
                Already have an account?{' '}
                <Link 
                  to="/login" 
                  className="text-brass-gold hover:text-brass-gold/80 font-semibold transition-colors"
                >
                  Sign In
                </Link>
              </p>
            </div>
          </CardContent>
        </Card>
      </ContentSection>
    </SectionContainer>
  );
};

export default RegisterPage;
