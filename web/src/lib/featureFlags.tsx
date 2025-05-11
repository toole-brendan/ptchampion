import { ReactNode, createContext, useContext, useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';

// Flag names - must match backend
export const FLAGS = {
  GRADING_FORMULA_V2: 'grading_formula_v2',
  FINE_TUNED_PUSHUP_MODEL: 'fine_tuned_pushup_model',
  TEAM_CHALLENGES: 'team_challenges',
  DARK_MODE_DEFAULT: 'dark_mode_default',
  EXPERIMENTAL_FEATURES: 'experimental_features',
  MEDIAPIPE_HOLISTIC: 'mediapipe_holistic',
};

// API response type
interface FeaturesResponse {
  features: Record<string, unknown>;
}

// Context type
interface FeatureFlagContextType {
  flags: Record<string, unknown>;
  isLoading: boolean;
  error: Error | null;
  isEnabled: (flagName: string, defaultValue?: boolean) => boolean;
  getStringValue: (flagName: string, defaultValue?: string) => string;
  getNumberValue: (flagName: string, defaultValue?: number) => number;
  getJSONValue: <T>(flagName: string, defaultValue?: T) => T;
  refresh: () => void;
}

// Create context with default values
const FeatureFlagContext = createContext<FeatureFlagContextType>({
  flags: {},
  isLoading: false,
  error: null,
  isEnabled: () => false,
  getStringValue: (_: string, defaultValue = '') => defaultValue,
  getNumberValue: (_: string, defaultValue = 0) => defaultValue,
  getJSONValue: <T,>(_: string, defaultValue?: T) => defaultValue as T,
  refresh: () => {},
});

// Hook to fetch feature flags
const useFetchFeatureFlags = () => {
  return useQuery<FeaturesResponse, Error>({
    queryKey: ['features'],
    queryFn: async () => {
      try {
        const response = await fetch('/api/v1/features', {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          credentials: 'include', // Include cookies for authentication
        });

        if (!response.ok) {
          throw new Error(`Error fetching feature flags: ${response.status}`);
        }

        return response.json();
      } catch (error) {
        console.error('Error fetching feature flags:', error);
        throw error;
      }
    },
    staleTime: 5 * 60 * 1000, // 5 minutes before refetching
    retry: 2,
  });
};

// Provider component
export const FeatureFlagProvider = ({ children }: { children: ReactNode }) => {
  const { data, isLoading, error, refetch } = useFetchFeatureFlags();
  const [flags, setFlags] = useState<Record<string, unknown>>({});

  useEffect(() => {
    if (data?.features) {
      setFlags(data.features);
    }
  }, [data]);

  // Helper functions to get flag values
  const isEnabled = (flagName: string, defaultValue = false): boolean => {
    if (flags[flagName] === undefined) return defaultValue;
    return Boolean(flags[flagName]);
  };

  const getStringValue = (flagName: string, defaultValue = ''): string => {
    if (flags[flagName] === undefined) return defaultValue;
    return String(flags[flagName]);
  };

  const getNumberValue = (flagName: string, defaultValue = 0): number => {
    if (flags[flagName] === undefined) return defaultValue;
    const value = flags[flagName];
    return typeof value === 'number' ? value : Number(value) || defaultValue;
  };

  const getJSONValue = <T,>(flagName: string, defaultValue?: T): T => {
    if (flags[flagName] === undefined) return defaultValue as T;
    
    try {
      const value = flags[flagName];
      
      // If it's already an object, return it directly
      if (typeof value === 'object' && value !== null) {
        return value as T;
      }
      
      // If it's a string, try to parse it
      if (typeof value === 'string') {
        return JSON.parse(value) as T;
      }
      
      return defaultValue as T;
    } catch (error) {
      console.error(`Error parsing JSON flag ${flagName}:`, error);
      return defaultValue as T;
    }
  };

  const contextValue: FeatureFlagContextType = {
    flags,
    isLoading,
    error,
    isEnabled,
    getStringValue,
    getNumberValue,
    getJSONValue,
    refresh: refetch,
  };

  return (
    <FeatureFlagContext.Provider value={contextValue}>
      {children}
    </FeatureFlagContext.Provider>
  );
};

// Hook to use feature flags
export const useFeatureFlags = () => {
  return useContext(FeatureFlagContext);
};

// Example usage:
/*
function App() {
  return (
    <FeatureFlagProvider>
      <YourComponents />
    </FeatureFlagProvider>
  );
}

function YourComponent() {
  const { isEnabled } = useFeatureFlags();
  
  return (
    <div>
      {isEnabled(FLAGS.TEAM_CHALLENGES) && (
        <TeamChallengesFeature />
      )}
    </div>
  );
}
*/ 