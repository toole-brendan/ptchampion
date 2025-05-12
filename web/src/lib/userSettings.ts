export interface AppSettings {
  geolocation: boolean;
  notifications: boolean;
  // other settings can be added here
}

const SETTINGS_STORAGE_KEY = 'pt_app_settings';

// Helper to load settings from localStorage
export const loadSettings = (): AppSettings => {
  const defaultSettings: AppSettings = {
    geolocation: false,
    notifications: false
  };
  
  try {
    const storedSettings = localStorage.getItem(SETTINGS_STORAGE_KEY);
    if (!storedSettings) return defaultSettings;
    
    const parsedSettings = JSON.parse(storedSettings);
    return { ...defaultSettings, ...parsedSettings };
  } catch (error) {
    console.error('Failed to load settings:', error);
    return defaultSettings;
  }
};

// Helper to save settings to localStorage
export const saveSettings = (settings: AppSettings): void => {
  try {
    localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(settings));
  } catch (error) {
    console.error('Failed to save settings:', error);
  }
}; 