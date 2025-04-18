import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { Loader2 } from 'lucide-react';

// Remove development mode check here, handle elsewhere if needed
// const isDevelopment = import.meta.env.DEV || import.meta.env.MODE === 'development';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate();

  // Get login function, loading state, and error state from context
  const { login, isLoading, error, clearError, isAuthenticated } = useAuth();

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  // Clear errors when component mounts or inputs change
  useEffect(() => {
    clearError();
  }, [clearError, email, password]);

  const handleInputChange = (setter: React.Dispatch<React.SetStateAction<string>>) => 
    (e: React.ChangeEvent<HTMLInputElement>) => {
      // clearError(); // Optional: Clear error immediately on typing
      setter(e.target.value);
    };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!email || !password) {
      // Basic client-side validation (can enhance)
      // Error from context will handle backend validation
      return; 
    }

    await login({ email, password });
    // AuthContext handles success (token set -> user query runs -> ProtectedRoute allows access)
    // AuthContext handles error state update
  };

  return (
    <div className="flex min-h-screen flex-col justify-center py-12 sm:px-6 lg:px-8 bg-gray-100">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <h2 className="mt-6 text-center text-3xl font-bold tracking-tight text-gray-900">
          PT Champion
        </h2>
        <h3 className="mt-2 text-center text-2xl font-semibold text-gray-700">
          Sign in to your account
        </h3>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white px-4 py-8 shadow sm:rounded-lg sm:px-10">
          {/* Remove development mode banner */}

          {error && (
            <div className="mb-4 rounded-md bg-red-50 p-4 border border-red-200">
              <p className="text-sm font-medium text-red-800">Login Failed</p>
              <p className="mt-1 text-sm text-red-700">{error}</p>
            </div>
          )}

          <form className="space-y-6" onSubmit={handleSubmit}>
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <div className="mt-1">
                <input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  required
                  value={email}
                  onChange={handleInputChange(setEmail)}
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
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={handleInputChange(setPassword)}
                  disabled={isLoading}
                  className="block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm disabled:opacity-50"
                />
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={isLoading || !email || !password}
                className="flex w-full items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isLoading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Signing in...
                  </>
                ) : 'Sign in'}
              </button>
            </div>
          </form>

          <div className="mt-6">
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-300" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="bg-white px-2 text-gray-500">
                  New to PT Champion?
                </span>
              </div>
            </div>

            <div className="mt-6 text-center">
              <Link
                to="/register"
                className={`font-medium text-indigo-600 hover:text-indigo-500 ${isLoading ? 'pointer-events-none opacity-50' : ''}`}
              >
                Create an account
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login; 