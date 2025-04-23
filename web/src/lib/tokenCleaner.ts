/**
 * Token Cleaner - Utility to ensure stale tokens are completely removed
 * This is imported and executed at the earliest point in the application
 */
import { cleanAuthStorage } from './secureStorage';

/**
 * Forcibly clear all tokens from localStorage to ensure a clean state
 * This runs immediately when this file is imported
 */
(() => {
  console.log('🧹 Token cleaner running');
  try {
    // Use the thorough cleaning function
    cleanAuthStorage();
    console.log('🧹 Token cleaner complete - storage cleared');
  } catch (error) {
    console.error('Error in token cleaner:', error);
  }
})();

export const clearAllTokens = cleanAuthStorage; 