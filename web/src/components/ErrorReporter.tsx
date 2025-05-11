import { useEffect } from 'react';

/**
 * Component that initializes global error reporting
 * This integrates with a monitoring service like Sentry
 */
export function ErrorReporter() {
  useEffect(() => {
    if (typeof window !== 'undefined') {
      // Simple implementation - in production this would connect to Sentry or similar
      window.captureException = (error: unknown) => {
        console.error('[Error Reporter]', error);
        
        // In production, this would send to a monitoring service
        // Sentry.captureException(error);
        
        // For now, just log to console in development
        if (process.env.NODE_ENV === 'development') {
          console.warn('[Dev Only] Error captured but not sent to monitoring service');
        }
      };
    }

    return () => {
      // Clean up
      if (typeof window !== 'undefined') {
        // @ts-expect-error - We're explicitly removing the property
        window.captureException = undefined;
      }
    };
  }, []);

  // This component doesn't render anything
  return null;
} 