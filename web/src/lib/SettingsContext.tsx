import React, { createContext, useState, useContext, ReactNode } from 'react';
import { AppSettings, loadSettings, saveSettings } from './userSettings';

// Define the shape of the settings context
interface SettingsContextType {
  settings: AppSettings;
  updateSetting: <K extends keyof AppSettings>(key: K, value: AppSettings[K]) => Promise<void>;
  isUpdating: boolean;
}

// Create the context with undefined default value
const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

// Provider component
export const SettingsProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [settings, setSettings] = useState<AppSettings>(() => loadSettings());
  const [isUpdating, setIsUpdating] = useState(false);

  // Update a single setting with optimistic update pattern
  const updateSetting = async <K extends keyof AppSettings>(key: K, value: AppSettings[K]) => {
    setIsUpdating(true);
    
    // Optimistically update the state immediately
    setSettings(prev => {
      const newSettings = { ...prev, [key]: value };
      return newSettings;
    });

    // Simulate async operation (in real app, this could be API call)
    try {
      await new Promise(resolve => setTimeout(resolve, 300));
      
      // Save to localStorage
      const newSettings = { ...settings, [key]: value };
      saveSettings(newSettings);
    } catch (error) {
      // On error, revert the optimistic update
      setSettings(loadSettings());
      throw error;
    } finally {
      setIsUpdating(false);
    }
  };

  // Create the context value object
  const contextValue: SettingsContextType = {
    settings,
    updateSetting,
    isUpdating,
  };

  return (
    <SettingsContext.Provider value={contextValue}>
      {children}
    </SettingsContext.Provider>
  );
};

// Custom hook to use the settings context
export const useSettings = (): SettingsContextType => {
  const context = useContext(SettingsContext);
  if (context === undefined) {
    throw new Error('useSettings must be used within a SettingsProvider');
  }
  return context;
}; 