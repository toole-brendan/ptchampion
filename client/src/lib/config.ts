// Import removed as unused

// Default configuration
const defaultConfig = {
  // API configuration
  api: {
    // Default base URL for API endpoints - updated to use port 8081 for Docker setup
    baseUrl: import.meta.env.VITE_API_URL || 'http://localhost:8081/api/v1',
    
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

// TEMPORARILY DISABLE PORT DISCOVERY - force using 8081
console.log("Port discovery disabled - using fixed URL:", config.api.baseUrl);

export default config; 