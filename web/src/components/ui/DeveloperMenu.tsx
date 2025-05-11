import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from './dialog';
import { Button } from './button';
import { cleanAuthStorage } from '../../lib/secureStorage';
import config from '../../lib/config';

interface DeveloperMenuProps {
  isOpen: boolean;
  onClose: () => void;
}

export const DeveloperMenu: React.FC<DeveloperMenuProps> = ({ isOpen, onClose }) => {
  const [apiInfo, setApiInfo] = useState<string>(`API URL: ${config.api.baseUrl}`);
  
  const clearAllStorage = () => {
    cleanAuthStorage();
    localStorage.clear();
    sessionStorage.clear();
    setApiInfo('All storage cleared');
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="text-center font-heading uppercase">Developer Options</DialogTitle>
        </DialogHeader>
        <div className="space-y-4 p-4">
          <div className="overflow-x-auto rounded border border-army-tan/30 bg-cream p-2 font-mono text-xs">
            <p>Environment: {import.meta.env.MODE}</p>
            <p>{apiInfo}</p>
          </div>
          
          <div className="grid grid-cols-2 gap-2">
            <Button 
              variant="outline" 
              className="border-army-tan/50 bg-card-background text-sm"
              onClick={clearAllStorage}
            >
              Clear Storage
            </Button>
            
            <Button 
              variant="outline" 
              className="border-army-tan/50 bg-card-background text-sm"
              onClick={() => {
                setApiInfo('Refreshing...');
                window.location.reload();
              }}
            >
              Reload App
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default DeveloperMenu; 