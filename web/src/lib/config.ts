// Import removed as unused

// Default configuration
const defaultConfig = {
  // API configuration
  api: {
    // Use relative URL in production, absolute URL in development
    baseUrl: import.meta.env.PROD 
      ? '/api/v1'  // In production, use relative URL (served via Azure Front Door)
      : (import.meta.env.VITE_API_URL || 'http://localhost:8081/api/v1'),
    
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