/**
 * Global type declarations for browser-specific functions
 */

interface ToastOptions {
  title: string;
  description?: string;
  duration?: number;
  variant?: 'default' | 'destructive' | 'success';
}

declare global {
  interface Window {
    /**
     * Global function to show toast notifications
     */
    showToast: (options: ToastOptions) => void;
    
    /**
     * Global function to capture and report exceptions to monitoring service
     */
    captureException: (error: unknown) => void;
  }
}

export {}; 