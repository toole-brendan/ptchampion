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
    <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50">
      <div 
        className="relative w-full max-w-md border-4 border-brass-gold rounded-lg shadow-2xl m-4 overflow-auto max-h-[90vh] text-white"
        style={{ 
          backgroundColor: '#1a1a1a', 
          boxShadow: '0 0 15px 5px rgba(205, 180, 130, 0.3)'
        }}
      >
        {/* Close button */}
        <button 
          onClick={onClose}
          className="absolute right-4 top-4 text-brass-gold hover:text-white rounded-full p-1 border border-brass-gold/50 hover:bg-brass-gold/20"
        >
          <X size={24} />
        </button>
        
        {/* Header */}
        <div 
          className="p-4 border-b-2 border-brass-gold" 
          style={{ backgroundColor: 'rgba(205, 180, 130, 0.2)' }}
        >
          <h2 className="text-center font-heading text-2xl uppercase text-brass-gold font-bold">
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
            <h3 className="font-heading text-xl uppercase text-brass-gold font-bold pb-1 border-b border-brass-gold/30">
              Bypass Authentication
            </h3>
            <p className="text-sm text-white">Jump directly to authenticated pages without login:</p>
            <div className="grid grid-cols-2 gap-3">
              <Button 
                variant="default"
                className="bg-brass-gold text-base font-bold text-black hover:bg-brass-gold/90 py-3"
                onClick={() => bypassAuthAndNavigate('/')}
              >
                Go to Dashboard
              </Button>
              
              <Button 
                variant="outline" 
                className="border-2 border-brass-gold bg-transparent text-base font-bold text-brass-gold hover:bg-brass-gold/10 py-3"
                onClick={() => bypassAuthAndNavigate('/exercises')}
              >
                Go to Exercises
              </Button>
            </div>
          </div>
          
          {/* Storage Options */}
          <div className="space-y-3">
            <h3 className="font-heading text-xl uppercase text-brass-gold font-bold pb-1 border-b border-brass-gold/30">
              Storage & App
            </h3>
            <div className="grid grid-cols-2 gap-3">
              <Button 
                variant="destructive" 
                className="text-base font-bold py-3"
                onClick={clearAllStorage}
              >
                Clear Storage
              </Button>
              
              <Button 
                variant="secondary" 
                className="bg-army-tan text-base font-bold text-deep-ops py-3"
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