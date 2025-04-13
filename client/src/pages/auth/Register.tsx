import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { Loader2 } from 'lucide-react';

const Register: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [validationError, setValidationError] = useState('');
  const navigate = useNavigate();

  const { register, isLoading, error: apiError, clearError, isAuthenticated } = useAuth();

  useEffect(() => {
    if (isAuthenticated) {
      navigate('/', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  useEffect(() => {
    clearError();
  }, [clearError, username, password, confirmPassword, displayName]);

  const handleInputChange = (setter: React.Dispatch<React.SetStateAction<string>>) =>
    (e: React.ChangeEvent<HTMLInputElement>) => {
      setValidationError('');
      setter(e.target.value);
    };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setValidationError('');

    if (!username || !password || !confirmPassword) {
      setValidationError('Username, password, and confirmation are required.');
      return;
    }
    if (password.length < 8) {
      setValidationError('Password must be at least 8 characters long.');
      return;
    }
    if (password !== confirmPassword) {
      setValidationError('Passwords do not match.');
      return;
    }

    await register({
      username,
      password,
      display_name: displayName || undefined
    });
  };

  const displayError = validationError || apiError;

  return (
    <div className="flex min-h-screen flex-col justify-center py-12 sm:px-6 lg:px-8 bg-gray-100">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <h2 className="mt-6 text-center text-3xl font-bold tracking-tight text-gray-900">
          PT Champion
        </h2>
        <h3 className="mt-2 text-center text-2xl font-semibold text-gray-700">
          Create your account
        </h3>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white px-4 py-8 shadow sm:rounded-lg sm:px-10">
          {displayError && (
            <div className="mb-4 rounded-md bg-red-50 p-4 border border-red-200">
               <p className="text-sm font-medium text-red-800">
                 {validationError ? 'Validation Error' : 'Registration Failed'}
               </p>
               <p className="mt-1 text-sm text-red-700">{displayError}</p>
            </div>
          )}

          <form className="space-y-6" onSubmit={handleSubmit}>
            <div>
              <label htmlFor="username" className="block text-sm font-medium text-gray-700">
                Username
              </label>
              <div className="mt-1">
                <input
                  id="username"
                  name="username"
                  type="text"
                  autoComplete="username"
                  required
                  value={username}
                  onChange={handleInputChange(setUsername)}
                  disabled={isLoading}
                  className="block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm disabled:opacity-50"
                />
              </div>
            </div>
            
            <div>
              <label htmlFor="display-name" className="block text-sm font-medium text-gray-700">
                Display Name (optional)
              </label>
              <div className="mt-1">
                <input
                  id="display-name"
                  name="display-name"
                  type="text"
                  autoComplete="name"
                  value={displayName}
                  onChange={handleInputChange(setDisplayName)}
                  disabled={isLoading}
                  className="block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm disabled:opacity-50"
                />
              </div>
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                Password
              </label>
              <div className="mt-1">
                <input
                  id="password"
                  name="password"
                  type="password"
                  autoComplete="new-password"
                  required
                  value={password}
                  onChange={handleInputChange(setPassword)}
                  disabled={isLoading}
                  className="block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm disabled:opacity-50"
                />
              </div>
              <p className="mt-1 text-xs text-gray-500">
                Must be at least 8 characters long.
              </p>
            </div>
            
            <div>
              <label htmlFor="confirm-password" className="block text-sm font-medium text-gray-700">
                Confirm Password
              </label>
              <div className="mt-1">
                <input
                  id="confirm-password"
                  name="confirm-password"
                  type="password"
                  autoComplete="new-password"
                  required
                  value={confirmPassword}
                  onChange={handleInputChange(setConfirmPassword)}
                  disabled={isLoading}
                  className="block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm disabled:opacity-50"
                />
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={isLoading || !username || !password || !confirmPassword}
                className="flex w-full items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isLoading ? (
                   <>
                     <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                     Creating account...
                   </>
                 ) : 'Create account'}
              </button>
            </div>
          </form>

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              Already have an account?{' '}
              <Link
                to="/login"
                className={`font-medium text-indigo-600 hover:text-indigo-500 ${isLoading ? 'pointer-events-none opacity-50' : ''}`}
              >
                Sign in
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Register; 