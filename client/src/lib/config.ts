// Import removed as unused

// Default configuration
const defaultConfig = {
  // API configuration
  api: {
    // Default base URL for API endpoints - use port 3000 as default
    baseUrl: import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1',
    
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

// TEMPORARILY DISABLE PORT DISCOVERY - force using 3000
console.log("Port discovery disabled - using fixed URL:", config.api.baseUrl);

export default config; 