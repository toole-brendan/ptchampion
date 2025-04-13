/**
 * Port discovery service for finding the running backend server
 */

// List of ports to check in priority order - put port 3000 first based on server logs
const commonPorts = [3000, 5000, 3001, 4000, 8000, 8080, 9000, 3333];

/**
 * Attempts to find a running backend server by checking common ports
 * @param basePath The API path to check (e.g., "/api/health")
 * @param hostname The hostname (defaults to localhost)
 * @returns Promise resolving to the full working URL or null if none found
 */
export const discoverBackendPort = async (
  basePath: string = "/api/health", // Use a simpler health endpoint for checking
  hostname: string = "localhost"
): Promise<string | null> => {
  console.log("Starting backend port discovery...");
  
  // First try the configured port from environment
  const configuredPort = import.meta.env.VITE_API_PORT;
  if (configuredPort) {
    const url = `http://${hostname}:${configuredPort}`;
    console.log(`Trying configured port: ${url}${basePath}`);
    if (await isServerAvailable(`${url}${basePath}`)) {
      console.log(`✅ Backend discovered on configured port: ${url}`);
      return url;
    }
  }

  console.log("No configured port found or it's not responding. Checking common ports...")

  // If configured port doesn't work, try common ports
  for (const port of commonPorts) {
    const url = `http://${hostname}:${port}`;
    console.log(`Trying port: ${url}${basePath}`);
    
    // Try with CORS mode: no-cors to avoid CORS issues during discovery
    if (await isServerAvailable(`${url}${basePath}`, true)) {
      console.log(`✅ Backend discovered on port: ${url}`);
      return url;
    }
  }

  console.warn("⚠️ Could not discover backend server on any common ports");
  console.log("⚠️ Falling back to port 3000 (based on server logs)");
  // Default fallback to port 3000
  return `http://${hostname}:3000`;
};

/**
 * Check if a server is available at the given URL
 * @param url URL to check
 * @param useNoCors Whether to use 'no-cors' mode for the fetch
 * @returns Promise resolving to boolean indicating if server is available
 */
const isServerAvailable = async (url: string, useNoCors: boolean = false): Promise<boolean> => {
  try {
    // Set a short timeout to avoid long waits
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 500);
    
    const fetchOptions: RequestInit = { 
      method: 'GET',
      signal: controller.signal
    };
    
    // Use no-cors mode if specified (helps with discovery but won't actually get a successful response)
    if (useNoCors) {
      fetchOptions.mode = 'no-cors';
      
      // With no-cors, we can't check response.ok, so we just check if the fetch resolves without error
      await fetch(url, fetchOptions);
      clearTimeout(timeoutId);
      
      // If we got this far without error, the server is probably there
      return true;
    } else {
      const response = await fetch(url, fetchOptions);
      clearTimeout(timeoutId);
      return response.ok;
    }
  } catch (error) {
    if (error instanceof Error) {
      // Filter out abort errors during discovery
      if (error.name !== 'AbortError') {
        console.log(`Failed to connect to ${url}: ${error.message}`);
      }
    }
    return false;
  }
}; 