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
    <div className="space-y-3"> 
      {/* Apple Sign-In Button */}
      <button 
        onClick={() => openOAuthPopup('apple')} 
        className="w-full flex items-center justify-center rounded-lg px-4 py-3 bg-black text-white font-medium"
      >
        <svg className="w-5 h-5 mr-3" viewBox="0 0 24 24" fill="white">
          <path d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701z" />
        </svg>
        Sign in with Apple
      </button>

      {/* Google Sign-In Button */}
      <button 
        onClick={() => openOAuthPopup('google')} 
        className="w-full flex items-center justify-center rounded-lg px-4 py-3 bg-white text-gray-700 border border-gray-200 font-medium"
      >
        <img 
          src="/assets/signin-assets/iOS/png@3x/light/ios_light_rd_na@3x.png" 
          alt="" 
          className="w-5 h-5 mr-3" 
        /> 
        Sign in with Google
      </button>
    </div>
  );
};

export default SocialLoginButtons; 