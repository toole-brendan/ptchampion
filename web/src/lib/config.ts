// Import removed as unused

// Default configuration
const defaultConfig = {
  // API configuration
  api: {
    // Use the correct API URL based on environment
    baseUrl: import.meta.env.DEV
      ? '/api/v1'
      : import.meta.env.VITE_API_BASE_URL || 'https://ptchampion-api-westus.azurewebsites.net/api/v1',
    
    // Timeout for API requests in milliseconds
    timeout: 10000,  // 10 seconds
  },
  
  // Authentication configuration
  auth: {
    // Local storage keys
    storageKeys: {
      token: 'authToken',
      user: 'userData',
    },
    
    // Token expiration handling
    tokenRefreshThreshold: 5 * 60 * 1000,  // 5 minutes in milliseconds
  },
};

// Export the config object for immediate use
const config = { ...defaultConfig };

// Log the API URL to help with debugging
console.log(`API URL: ${config.api.baseUrl} (${import.meta.env.PROD ? 'production' : 'development'} mode)`);

export default config;
