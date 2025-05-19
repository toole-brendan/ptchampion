/**
 * Secure storage implementation using Web Crypto API
 * Encrypts values before storing them in localStorage
 * and decrypts them when retrieving
 */

// We derive a key from this salt and the hostname
const SALT_PREFIX = 'PT_CHAMPION_SECURE_';

/**
 * Generate a cryptographic key based on the hostname
 * This ensures that tokens stored on one domain can't be used on another
 */
async function getEncryptionKey(): Promise<CryptoKey> {
  const hostname = window.location.hostname;
  const salt = SALT_PREFIX + hostname;
  
  // Convert the salt to an ArrayBuffer
  const encoder = new TextEncoder();
  const saltBuffer = encoder.encode(salt);
  
  // Import the salt as a raw key
  const baseKey = await window.crypto.subtle.importKey(
    'raw',
    saltBuffer,
    { name: 'PBKDF2' },
    false,
    ['deriveKey']
  );
  
  // Derive the actual encryption key
  return window.crypto.subtle.deriveKey(
    {
      name: 'PBKDF2',
      salt: encoder.encode(hostname),
      iterations: 100000,
      hash: 'SHA-256',
    },
    baseKey,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt']
  );
}

/**
 * Encrypt a string value before storing
 */
async function encrypt(value: string): Promise<string> {
  const key = await getEncryptionKey();
  const encoder = new TextEncoder();
  const data = encoder.encode(value);
  
  // Create an initialization vector
  const iv = window.crypto.getRandomValues(new Uint8Array(12));
  
  // Encrypt the data
  const encryptedData = await window.crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv,
    },
    key,
    data
  );
  
  // Combine the IV and encrypted data for storage
  const encryptedArray = new Uint8Array(iv.length + encryptedData.byteLength);
  encryptedArray.set(iv, 0);
  encryptedArray.set(new Uint8Array(encryptedData), iv.length);
  
  // Convert to Base64 for storage
  return btoa(String.fromCharCode(...encryptedArray));
}

/**
 * Decrypt a stored value
 */
async function decrypt(encryptedValue: string): Promise<string> {
  try {
    const key = await getEncryptionKey();
    
    // Convert from Base64
    const encryptedArray = new Uint8Array(
      atob(encryptedValue).split('').map(char => char.charCodeAt(0))
    );
    
    // Extract the IV (first 12 bytes)
    const iv = encryptedArray.slice(0, 12);
    const encryptedData = encryptedArray.slice(12);
    
    // Decrypt the data
    const decryptedData = await window.crypto.subtle.decrypt(
      {
        name: 'AES-GCM',
        iv,
      },
      key,
      encryptedData
    );
    
    // Convert the decrypted data back to a string
    const decoder = new TextDecoder();
    return decoder.decode(decryptedData);
  } catch (error) {
    console.error('Error decrypting data:', error);
    // If decryption fails, remove the corrupted data
    return '';
  }
}

/**
 * Securely store a value in localStorage
 */
export async function secureSet(key: string, value: string): Promise<void> {
  try {
    const encryptedValue = await encrypt(value);
    localStorage.setItem(key, encryptedValue);
  } catch (error) {
    console.error('Error storing encrypted data:', error);
    // Fallback to unencrypted storage if encryption fails
    localStorage.setItem(key, value);
  }
}

/**
 * Retrieve and decrypt a value from localStorage
 */
export async function secureGet(key: string): Promise<string | null> {
  const encryptedValue = localStorage.getItem(key);
  if (!encryptedValue) return null;
  
  try {
    // Check if the value is likely Base64 encoded (a basic check)
    const isLikelyEncrypted = /^[A-Za-z0-9+/=]+$/.test(encryptedValue) && 
                             encryptedValue.length % 4 === 0;
    
    if (!isLikelyEncrypted) {
      console.log(`secureGet: Value for ${key} appears to be plaintext, returning as-is`);
      return encryptedValue;
    }
    
    return await decrypt(encryptedValue);
  } catch (error) {
    console.error('Error retrieving encrypted data:', error);
    // If we can't decrypt, assume it's not encrypted (for backward compatibility)
    return encryptedValue;
  }
}

/**
 * Remove a value from localStorage
 */
export function secureRemove(key: string): void {
  try {
    console.log(`Secure remove: Removing ${key} from localStorage`);
    localStorage.removeItem(key);
    
    // Also try to remove any backup or alternate versions that might exist
    const alternateKeys = [`${key}_backup`, `${key}_alt`, key.replace('auth', 'pt')];
    alternateKeys.forEach(altKey => {
      if (localStorage.getItem(altKey)) {
        console.log(`Secure remove: Also removing ${altKey}`);
        localStorage.removeItem(altKey);
      }
    });
  } catch (error) {
    console.error(`Error removing ${key}:`, error);
  }
}

/**
 * Clean all authentication-related data from storage
 */
export function cleanAuthStorage(): void {
  try {
    console.log('Cleaning all auth storage');
    // List of keys that might contain auth data
    const authKeys = [
      'authToken', 'userData', 'pt_champion_session', 
      'authTokenBackup', 'userSession', 'refreshToken',
      'user'
    ];
    
    // Remove all auth-related keys
    authKeys.forEach(key => {
      if (localStorage.getItem(key)) {
        console.log(`Cleaning auth storage: removing ${key}`);
        localStorage.removeItem(key);
      }
    });
    
    // Also clear sessionStorage
    sessionStorage.clear();
    
    console.log('Auth storage cleaning complete');
  } catch (error) {
    console.error('Error cleaning auth storage:', error);
  }
}

// Non-async versions that use the sync localStorage API directly
// Useful for fallback and non-sensitive data
export const plainStorage = {
  getItem: (key: string): string | null => localStorage.getItem(key),
  setItem: (key: string, value: string): void => localStorage.setItem(key, value),
  removeItem: (key: string): void => localStorage.removeItem(key),
}; 