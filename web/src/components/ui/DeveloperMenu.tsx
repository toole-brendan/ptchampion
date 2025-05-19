import React, { useState } from 'react';
import { 
  Cog, 
  X,
  ToggleLeft,
  ToggleRight,
  Smartphone,
  RefreshCw,
  Trash2,
  Bookmark,
  LayoutDashboard,
  Save,
  LogIn,
  Dumbbell
} from 'lucide-react';
import { Button } from './button';
import { Card, CardHeader, CardTitle, CardDivider, CardContent } from './card';
import { Switch } from './switch';
import { Label } from './label';
import { useSettings } from '@/lib/SettingsContext';
import { useFeatureFlags } from '@/lib/featureFlags';
import config from '@/lib/config';

// The special token that indicates a developer auth session
export const DEV_MOCK_TOKEN = 'dev-mock-token';

// Extend the Settings context with our additional methods
type ExtendedSettingsContext = ReturnType<typeof useSettings> & {
  clearLocalStorage: () => void;
  resetIndexedDB: () => Promise<void>;
};

// Extend the FeatureFlags context with our additional methods
type ExtendedFeaturesContext = ReturnType<typeof useFeatureFlags> & {
  setFlag: (key: string, value: boolean) => void;
};

// Centered modal style instead of corner panel
const modalStyles = "fixed inset-0 z-50 flex items-center justify-center bg-black/70";
const contentStyles = "relative max-h-[90vh] w-full max-w-md overflow-auto rounded-lg border-4 border-brass-gold bg-cream-dark p-4 shadow-2xl";

type Props = {
  onClose: () => void;
  isOpen?: boolean; // For backward compatibility with Login.tsx
  visible?: boolean; // New property name
};

export function DeveloperMenu({ onClose, isOpen, visible }: Props) {
  const [activeTab, setActiveTab] = useState<'debug' | 'flags' | 'device' | 'storage'>('debug');
  const { clearLocalStorage, resetIndexedDB } = useSettings() as ExtendedSettingsContext;
  const { flags, setFlag } = useFeatureFlags() as ExtendedFeaturesContext;

  // Use either isOpen or visible prop (for backward compatibility)
  const isVisible = isOpen !== undefined ? isOpen : visible;

  const handleClearLocalStorage = () => {
    if (confirm('Are you sure you want to clear all local storage data?')) {
      clearLocalStorage();
      alert('Local storage cleared');
    }
  };

  const handleResetDatabase = () => {
    if (confirm('Are you sure you want to reset the IndexedDB database?')) {
      resetIndexedDB()
        .then(() => alert('IndexedDB reset complete'))
        .catch((err: Error) => alert(`Error: ${err.message}`));
    }
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

  // Return null if not visible
  if (!isVisible) return null;

  return (
    <div className={modalStyles}>
      <div className={contentStyles}>
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-heading text-heading3 text-brass-gold uppercase tracking-wider flex items-center">
            <Cog className="mr-2 size-5" />
            Developer Menu
          </h2>
          <Button variant="ghost" size="icon" onClick={onClose} className="text-tactical-gray hover:text-brass-gold">
            <X className="size-5" />
            <span className="sr-only">Close</span>
          </Button>
        </div>

        <CardDivider className="mb-4" />

        <div className="tabs flex overflow-x-auto pb-2 mb-4">
          <Button 
            variant={activeTab === 'debug' ? 'default' : 'outline'} 
            className="mr-2 whitespace-nowrap bg-brass-gold text-deep-ops" 
            size="sm"
            onClick={() => setActiveTab('debug')}
          >
            <LayoutDashboard className="mr-1 size-4" />
            Debug Controls
          </Button>
          <Button 
            variant={activeTab === 'flags' ? 'default' : 'outline'} 
            className="mr-2 whitespace-nowrap bg-brass-gold text-deep-ops" 
            size="sm"
            onClick={() => setActiveTab('flags')}
          >
            <Bookmark className="mr-1 size-4" />
            Feature Flags
          </Button>
          <Button 
            variant={activeTab === 'device' ? 'default' : 'outline'} 
            className="mr-2 whitespace-nowrap bg-brass-gold text-deep-ops" 
            size="sm"
            onClick={() => setActiveTab('device')}
          >
            <Smartphone className="mr-1 size-4" />
            Device Info
          </Button>
          <Button 
            variant={activeTab === 'storage' ? 'default' : 'outline'} 
            className="mr-2 whitespace-nowrap bg-brass-gold text-deep-ops" 
            size="sm"
            onClick={() => setActiveTab('storage')}
          >
            <Save className="mr-1 size-4" />
            Storage
          </Button>
        </div>

        {activeTab === 'debug' && (
          <Card className="bg-cream">
            <CardHeader>
              <CardTitle className="text-brass-gold">Debug Controls</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Authentication Bypass */}
              <div className="space-y-3">
                <h3 className="font-heading text-sm uppercase tracking-wider text-tactical-gray border-b border-brass-gold/30 pb-1">
                  Authentication Bypass
                </h3>
                <div className="grid grid-cols-2 gap-3">
                  <Button 
                    variant="default"
                    className="bg-brass-gold py-3 font-bold text-base text-black hover:bg-brass-gold/90"
                    onClick={() => bypassAuthAndNavigate('/')}
                  >
                    <LogIn className="mr-2 size-4" />
                    Go to Dashboard
                  </Button>
                  
                  <Button 
                    variant="outline" 
                    className="border-2 border-brass-gold bg-transparent py-3 font-bold text-base text-brass-gold hover:bg-brass-gold/10"
                    onClick={() => bypassAuthAndNavigate('/exercises')}
                  >
                    <Dumbbell className="mr-2 size-4" />
                    Go to Exercises
                  </Button>
                </div>
              </div>

              {/* Storage Controls */}
              <div className="space-y-3">
                <h3 className="font-heading text-sm uppercase tracking-wider text-tactical-gray border-b border-brass-gold/30 pb-1">
                  Storage Management
                </h3>
                <div className="flex flex-col space-y-2">
                  <Button 
                    variant="outline" 
                    size="sm" 
                    className="justify-start text-left border-brass-gold border-opacity-30 hover:border-brass-gold hover:border-opacity-60"
                    onClick={handleClearLocalStorage}
                  >
                    <Trash2 className="mr-2 size-4 text-error" />
                    Clear Local Storage
                  </Button>
                  <Button 
                    variant="outline" 
                    size="sm" 
                    className="justify-start text-left border-brass-gold border-opacity-30 hover:border-brass-gold hover:border-opacity-60"
                    onClick={handleResetDatabase}
                  >
                    <RefreshCw className="mr-2 size-4 text-warning" />
                    Reset IndexedDB
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {activeTab === 'flags' && (
          <Card className="bg-cream">
            <CardHeader>
              <CardTitle className="text-brass-gold">Feature Flags</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {Object.entries(flags).map(([key, value]) => (
                  <div key={key} className="flex items-center justify-between">
                    <div className="space-y-0.5">
                      <Label htmlFor={key} className="text-sm font-medium">
                        {key}
                      </Label>
                      <div className="text-xs text-tactical-gray">
                        {value ? <ToggleRight className="inline mr-1 size-3 text-success" /> : <ToggleLeft className="inline mr-1 size-3 text-tactical-gray" />}
                        {value ? 'Enabled' : 'Disabled'}
                      </div>
                    </div>
                    <Switch
                      id={key}
                      checked={!!value}
                      onCheckedChange={(checked) => setFlag(key, checked)}
                    />
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {activeTab === 'device' && (
          <Card className="bg-cream">
            <CardHeader>
              <CardTitle className="text-brass-gold">Device Information</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2 text-sm">
                <div>
                  <span className="font-semibold">User Agent:</span>
                  <div className="text-tactical-gray text-xs mt-1 break-words">
                    {navigator.userAgent}
                  </div>
                </div>
                <div>
                  <span className="font-semibold">Screen:</span>
                  <div className="text-tactical-gray text-xs mt-1">
                    {window.screen.width}×{window.screen.height}, 
                    {window.devicePixelRatio}x pixel ratio
                  </div>
                </div>
                <div>
                  <span className="font-semibold">Platform:</span>
                  <div className="text-tactical-gray text-xs mt-1">
                    {navigator.platform}
                  </div>
                </div>
                <div>
                  <span className="font-semibold">Features:</span>
                  <div className="text-tactical-gray text-xs mt-1 space-y-1">
                    <div>
                      <span className="font-medium">Camera:</span> {navigator.mediaDevices ? "Available" : "Unavailable"}
                    </div>
                    <div>
                      <span className="font-medium">Bluetooth:</span> {navigator.bluetooth ? "Available" : "Unavailable"}
                    </div>
                    <div>
                      <span className="font-medium">Service Worker:</span> {'serviceWorker' in navigator ? "Supported" : "Unsupported"}
                    </div>
                    <div>
                      <span className="font-medium">IndexedDB:</span> {window.indexedDB ? "Supported" : "Unsupported"}
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {activeTab === 'storage' && (
          <Card className="bg-cream">
            <CardHeader>
              <CardTitle className="text-brass-gold">Storage Usage</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3 text-sm">
                <div className="grid grid-cols-[1fr_auto] gap-2">
                  <div className="font-semibold">Local Storage Keys:</div>
                  <div className="text-tactical-gray">{Object.keys(localStorage).length}</div>
                  <div className="font-semibold">Local Storage Size:</div>
                  <div className="text-tactical-gray">
                    {(() => {
                      let size = 0;
                      for (let i = 0; i < localStorage.length; i++) {
                        const key = localStorage.key(i) || '';
                        const value = localStorage.getItem(key) || '';
                        size += key.length + value.length;
                      }
                      return `~${(size / 1024).toFixed(2)} KB`;
                    })()}
                  </div>
                  
                  <div className="font-semibold">Session Storage Keys:</div>
                  <div className="text-tactical-gray">{Object.keys(sessionStorage).length}</div>
                </div>
                
                <div className="mt-4 pt-4 border-t border-brass-gold border-opacity-20">
                  <div className="font-semibold mb-2">Local Storage Contents:</div>
                  <div className="max-h-36 overflow-y-auto text-xs bg-cream-light rounded-md p-2 font-mono">
                    {Object.keys(localStorage).length > 0 ? (
                      Object.keys(localStorage).map((key) => (
                        <div key={key} className="mb-1">
                          <span className="text-brass-gold">{key}:</span>{' '}
                          <span className="text-tactical-gray truncate">
                            {localStorage.getItem(key)?.substring(0, 30)}
                            {(localStorage.getItem(key)?.length || 0) > 30 ? '...' : ''}
                          </span>
                        </div>
                      ))
                    ) : (
                      <span className="text-tactical-gray">No items in local storage</span>
                    )}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        <div className="text-xs text-tactical-gray text-center mt-4">
          This menu is only visible in development builds
        </div>
      </div>
    </div>
  );
}

// Default export for backward compatibility
export default DeveloperMenu; 