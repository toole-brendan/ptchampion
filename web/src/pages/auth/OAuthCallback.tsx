import React, { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { Alert, AlertDescription } from '../../components/ui/alert';
import { ExclamationTriangleIcon } from '@radix-ui/react-icons';

const OAuthCallback: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { loginWithSocial } = useAuth();
  const [error, setError] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(true);

  useEffect(() => {
    async function handleCallback() {
      try {
        // Parse the URL parameters from query string or form data
        const params = new URLSearchParams(location.search);
        const urlHash = location.hash.substring(1); // Remove the # character
        const hashParams = new URLSearchParams(urlHash);
        
        // For Apple Sign In (which uses form_post by default)
        const code = params.get('code');
        const idToken = params.get('id_token');
        const state = params.get('state');
        const storedState = localStorage.getItem('apple_auth_state');
        
        // Check if this is an Apple callback
        if (code && idToken) {
          // Verify state parameter to prevent CSRF
          if (state !== storedState) {
            throw new Error('Invalid state parameter');
          }
          
          // Clear stored state
          localStorage.removeItem('apple_auth_state');
          
          // Process Apple sign-in
          await loginWithSocial({
            provider: 'apple',
            token: idToken,
            code: code
          });
          
          // Redirect to dashboard on success
          navigate('/');
          return;
        }
        
        // Check for Google ID token in hash (used by some Google auth flows)
        const googleIdToken = hashParams.get('id_token');
        
        if (googleIdToken) {
          // Process Google sign-in from hash
          await loginWithSocial({
            provider: 'google',
            token: googleIdToken
          });
          
          // Redirect to dashboard on success
          navigate('/');
          return;
        }
        
        // If no auth data found, show error
        setError('No authentication data found in callback URL');
      } catch (err: any) {
        console.error('OAuth callback error:', err);
        setError(err.message || 'Authentication failed');
      } finally {
        setIsProcessing(false);
      }
    }
    
    handleCallback();
  }, [location, loginWithSocial, navigate]);
  
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background p-4">
      <div className="w-full max-w-md">
        {isProcessing ? (
          <div className="text-center">
            <div className="size-12 mx-auto animate-spin rounded-full border-4 border-brass-gold border-t-transparent"></div>
            <p className="mt-4 text-tactical-gray">Completing sign-in...</p>
          </div>
        ) : error ? (
          <Alert variant="destructive" className="mb-4">
            <ExclamationTriangleIcon className="size-4" />
            <AlertDescription>{error}</AlertDescription>
            <div className="mt-4">
              <button 
                className="text-brass-gold hover:underline"
                onClick={() => navigate('/login')}
              >
                Return to login
              </button>
            </div>
          </Alert>
        ) : (
          <div className="text-center">
            <p className="text-tactical-gray">Authentication successful! Redirecting...</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default OAuthCallback; 