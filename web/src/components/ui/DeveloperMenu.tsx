import React, { useState } from 'react';
import { Button } from './button';
import { cleanAuthStorage } from '../../lib/secureStorage';
import config from '../../lib/config';
import { X } from 'lucide-react';

interface DeveloperMenuProps {
  isOpen: boolean;
  onClose: () => void;
}

// The special token that indicates a developer auth session
export const DEV_MOCK_TOKEN = 'dev-mock-token';

export const DeveloperMenu: React.FC<DeveloperMenuProps> = ({ isOpen, onClose }) => {
  const [apiInfo, setApiInfo] = useState<string>(`API URL: ${config.api.baseUrl}`);
  
  const clearAllStorage = () => {
    cleanAuthStorage();
    localStorage.clear();
    sessionStorage.clear();
    setApiInfo('All storage cleared');
  };

  // Function to set a mock auth token and navigate to a route
  const bypassAuthAndNavigate = (route: string) => {
    // Set a mock token in local storage to bypass authentication
    localStorage.setItem(config.auth.storageKeys.token, DEV_MOCK_TOKEN);
    
    // Set mock user data
    const mockUser = {
      id: 'dev-user-id',
      username: 'devuser',
      display_name: 'Developer',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    localStorage.setItem(config.auth.storageKeys.user, JSON.stringify(mockUser));
    
    // Close menu and navigate
    onClose();
    
    // Reload the page to the specified route to force auth context update
    window.location.href = route;
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70">
      <div 
        className="relative m-4 max-h-[90vh] w-full max-w-md overflow-auto rounded-lg border-4 border-brass-gold text-white shadow-2xl"
        style={{ 
          backgroundColor: '#1a1a1a', 
          boxShadow: '0 0 15px 5px rgba(205, 180, 130, 0.3)'
        }}
      >
        {/* Close button */}
        <button 
          onClick={onClose}
          className="absolute right-4 top-4 rounded-full border border-brass-gold/50 p-1 text-brass-gold hover:bg-brass-gold/20 hover:text-white"
        >
          <X size={24} />
        </button>
        
        {/* Header */}
        <div 
          className="border-b-2 border-brass-gold p-4" 
          style={{ backgroundColor: 'rgba(205, 180, 130, 0.2)' }}
        >
          <h2 className="text-center font-heading text-2xl uppercase text-brass-gold">
            Developer Options
          </h2>
        </div>
        
        <div className="space-y-6 p-6 text-base">
          {/* Environment Info */}
          <div 
            className="overflow-x-auto rounded-md border-2 border-brass-gold/70 p-4 font-mono text-sm"
            style={{ backgroundColor: 'rgba(20, 20, 30, 0.95)' }}
          >
            <p className="font-bold text-brass-gold">Environment: {import.meta.env.MODE}</p>
            <p className="text-brass-gold">{apiInfo}</p>
          </div>
          
          {/* Authentication Bypass */}
          <div className="space-y-3">
            <h3 className="border-b border-brass-gold/30 pb-1 font-heading text-xl uppercase text-brass-gold">
              Bypass Authentication
            </h3>
            <p className="text-sm text-white">Jump directly to authenticated pages without login:</p>
            <div className="grid grid-cols-2 gap-3">
              <Button 
                variant="default"
                className="bg-brass-gold py-3 font-bold text-base text-black hover:bg-brass-gold/90"
                onClick={() => bypassAuthAndNavigate('/')}
              >
                Go to Dashboard
              </Button>
              
              <Button 
                variant="outline" 
                className="border-2 border-brass-gold bg-transparent py-3 font-bold text-base text-brass-gold hover:bg-brass-gold/10"
                onClick={() => bypassAuthAndNavigate('/exercises')}
              >
                Go to Exercises
              </Button>
            </div>
          </div>
          
          {/* Storage Options */}
          <div className="space-y-3">
            <h3 className="border-b border-brass-gold/30 pb-1 font-heading text-xl uppercase text-brass-gold">
              Storage & App
            </h3>
            <div className="grid grid-cols-2 gap-3">
              <Button 
                variant="destructive" 
                className="py-3 font-bold text-base"
                onClick={clearAllStorage}
              >
                Clear Storage
              </Button>
              
              <Button 
                variant="secondary" 
                className="bg-army-tan py-3 font-bold text-base text-deep-ops"
                onClick={() => {
                  setApiInfo('Refreshing...');
                  window.location.reload();
                }}
              >
                Reload App
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DeveloperMenu; 