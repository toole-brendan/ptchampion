import { useRef, useCallback } from 'react';

interface PendingRequest {
  promise: Promise<any>;
  timestamp: number;
}

/**
 * Hook to deduplicate API requests by caching in-flight requests
 * and returning the same promise for duplicate requests within a time window
 */
export function useRequestDeduplication(cacheTime: number = 5000) {
  const pendingRequests = useRef<Map<string, PendingRequest>>(new Map());

  const dedupedRequest = useCallback(async <T>(
    key: string,
    requestFn: () => Promise<T>
  ): Promise<T> => {
    const now = Date.now();
    const pending = pendingRequests.current.get(key);

    // If there's a pending request within the cache time, return it
    if (pending && (now - pending.timestamp) < cacheTime) {
      return pending.promise as Promise<T>;
    }

    // Clean up old entries
    for (const [k, v] of pendingRequests.current.entries()) {
      if (now - v.timestamp > cacheTime) {
        pendingRequests.current.delete(k);
      }
    }

    // Create new request
    const promise = requestFn()
      .finally(() => {
        // Remove from pending after completion
        setTimeout(() => {
          pendingRequests.current.delete(key);
        }, 100); // Small delay to handle rapid successive calls
      });

    pendingRequests.current.set(key, { promise, timestamp: now });
    return promise;
  }, [cacheTime]);

  return dedupedRequest;
}

/**
 * Create a request key from method, URL, and params
 */
export function createRequestKey(
  method: string,
  url: string,
  params?: any
): string {
  const paramStr = params ? JSON.stringify(params) : '';
  return `${method}:${url}:${paramStr}`;
}