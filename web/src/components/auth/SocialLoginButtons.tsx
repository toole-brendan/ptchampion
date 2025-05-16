import React, { useEffect } from 'react';
import config from '../../lib/config';  // contains baseUrl, etc.

const SocialLoginButtons: React.FC = () => {
  useEffect(() => {
    // Listen for messages from the auth popup
    const handler = (event: MessageEvent) => {
      // Ensure the message comes from our origin
      if (event.origin !== window.location.origin) return;
      const { token, user } = event.data || {};
      if (token) {
        // Save token and user info (our app's auth context or local storage)
        localStorage.setItem(config.auth.storageKeys.token, token);
        localStorage.setItem(config.auth.storageKeys.user, JSON.stringify(user));
        // Optionally, update global auth state or redirect user
        window.location.href = '/';  // redirect to home/dashboard after login
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const openOAuthPopup = (provider: 'google' | 'apple') => {
    const url = `${config.api.baseUrl}/auth/${provider}`;
    // Open a centered popup window for OAuth
    const width = 500, height = 600;
    const left = window.screenX + (window.innerWidth - width) / 2;
    const top = window.screenY + (window.innerHeight - height) / 2;
    window.open(url, `${provider}-oauth`, `width=${width},height=${height},left=${left},top=${top}`);
  };

  return (
    <div className="space-y-2 my-4"> 
      {/* Google Sign-In Button */}
      <button 
        onClick={() => openOAuthPopup('google')} 
        className="w-full flex items-center justify-center border rounded px-4 py-2 bg-white text-gray-700"
      >
        <img src="/images/google-logo.png" alt="" className="w-5 h-5 mr-2" /> 
        Sign in with Google
      </button>
      {/* Apple Sign-In Button */}
      <button 
        onClick={() => openOAuthPopup('apple')} 
        className="w-full flex items-center justify-center border rounded px-4 py-2 bg-black text-white"
      >
        <img src="/images/apple-logo.svg" alt="" className="w-5 h-5 mr-2 filter invert" /> 
        Sign in with Apple
      </button>
    </div>
  );
};

export default SocialLoginButtons; 