import React, { useState, useMemo, useEffect, useCallback } from 'react';
import { cn, formatLeaderboardScore } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { 
  Alert,
  AlertDescription,
  AlertTitle,
} from "@/components/ui/alert";
import { useApi } from "@/lib/apiClient";
import { useQuery } from '@tanstack/react-query';
import { AlertCircle, MapPin, Loader2 } from 'lucide-react';
import { useToast } from '@/components/ui/use-toast';

// Import new leaderboard components
import LeaderboardSegmentedControl from '@/components/leaderboard/LeaderboardSegmentedControl';
import LeaderboardFilterBar from '@/components/leaderboard/LeaderboardFilterBar';
import EnhancedLeaderboardRow from '@/components/leaderboard/EnhancedLeaderboardRow';
import LeaderboardRowSkeleton from '@/components/leaderboard/LeaderboardRowSkeleton';
import LeaderboardErrorState from '@/components/leaderboard/LeaderboardErrorState';
import LeaderboardEmptyState from '@/components/leaderboard/LeaderboardEmptyState';
import useStaggeredAnimation from '@/hooks/useStaggeredAnimation';

// Header divider component removed as we'll use a simple div for the separator

const exerciseDisplayNames = {
  'overall': 'Overall',
  'pushup': 'Push-ups',
  'situp': 'Sit-ups',
  'pullup': 'Pull-ups',
  'running': 'Two-Mile Run'
} as const;

// Geolocation state type
interface GeolocationState {
  isLoading: boolean;
  isSupported: boolean;
  isPermissionGranted: boolean;
  coordinates: { latitude: number; longitude: number } | null;
  error: string | null;
}

const Leaderboard: React.FC = () => {
  const api = useApi();
  const { toast } = useToast();
  
  // New state variables matching iOS structure
  const [selectedBoard, setSelectedBoard] = useState<'Global' | 'Local'>('Global');
  const [selectedExercise, setSelectedExercise] = useState<string>('overall');
  const [selectedCategory, setSelectedCategory] = useState<string>('weekly');
  const [selectedRadius, setSelectedRadius] = useState<string>('5');
  
  // Geolocation state
  const [geoState, setGeoState] = useState<GeolocationState>({
    isLoading: false,
    isSupported: 'geolocation' in navigator,
    isPermissionGranted: false,
    coordinates: null,
    error: null
  });

  // Request geolocation permission - wrapped in useCallback to avoid frequent regeneration
  const requestGeolocation = useCallback(() => {
    if (!geoState.isSupported) {
      setGeoState(prev => ({ ...prev, error: "Geolocation is not supported by your browser" }));
      return;
    }

    setGeoState(prev => ({ ...prev, isLoading: true, error: null }));
    
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setGeoState({
          isLoading: false,
          isSupported: true,
          isPermissionGranted: true,
          coordinates: {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude
          },
          error: null
        });
        
        // Show success toast when location is acquired
        toast({
          title: "Location access granted",
          description: "You can now view the local leaderboard in your area.",
          duration: 3000,
        });
      },
      (error) => {
        setGeoState({
          isLoading: false,
          isSupported: true,
          isPermissionGranted: false,
          coordinates: null,
          error: error.message
        });
      },
      {
        enableHighAccuracy: true,
        timeout: 5000,
        maximumAge: 0
      }
    );
  }, [geoState.isSupported, toast]);

  // Use React Query to fetch leaderboard data
  const { 
    data: leaderboardData,
    isLoading,
    isError,
    error,
    refetch
  } = useQuery({
    queryKey: ['leaderboard', selectedExercise, selectedBoard, selectedCategory, selectedRadius, geoState.coordinates],
    queryFn: async () => {
      const isLocalScope = selectedBoard === 'Local';
      
      if (isLocalScope && !geoState.coordinates) {
        // If local scope selected but no coordinates, throw error to trigger request
        throw new Error('Location permission required');
      }

      if (isLocalScope) {
        // Call local leaderboard API
        const radiusInMeters = parseInt(selectedRadius) * 1609.34; // Convert miles to meters
        return api.leaderboard.getLocalLeaderboard(
          selectedExercise,
          geoState.coordinates!.latitude,
          geoState.coordinates!.longitude,
          radiusInMeters
        );
      } else {
        // Call global leaderboard API
        return api.leaderboard.getLeaderboard(selectedExercise);
      }
    },
    enabled: !(selectedBoard === 'Local' && !geoState.coordinates && !geoState.isLoading),
    retry: 1,
    retryDelay: 1000,
  });

  // Effect to handle scope change
  useEffect(() => {
    const isLocalScope = selectedBoard === 'Local';
    
    if (isLocalScope && !geoState.coordinates && !geoState.error) {
      // If local scope selected but no coordinates, request them
      requestGeolocation();
    }
  }, [selectedBoard, geoState.coordinates, geoState.error, requestGeolocation]);

  // Process the leaderboard data for display
  const processedLeaderboard = useMemo(() => {
    if (!leaderboardData || !Array.isArray(leaderboardData)) return [];
    
    // Convert API data to display format with ranks
    return leaderboardData.map((entry: any, index: number) => ({
      rank: index + 1,
      name: entry.display_name || entry.username,
      username: entry.username,
      userId: String(entry.user_id), // Convert to string to match interface
      score: entry.max_grade !== undefined ? entry.max_grade : 0,
      formattedScore: formatLeaderboardScore(selectedExercise, entry.max_grade || 0),
      avatar: entry.profile_picture_url || null,
      unit: entry.unit || undefined,
      location: entry.location || undefined,
      isPersonalBest: entry.is_personal_best || false,
      performanceChange: entry.performance_change ? {
        type: entry.performance_change.type as 'improved' | 'declined' | 'maintained',
        positions: entry.performance_change.positions
      } : undefined,
      displaySubtitle: entry.display_subtitle || undefined
    }));
  }, [leaderboardData, selectedExercise]);

  // Staggered animation for rows
  const visibleRows = useStaggeredAnimation({
    itemCount: processedLeaderboard.length,
    baseDelay: 200,
    staggerDelay: 50
  });

  return (
    <div className="min-h-screen">
      {/* Radial gradient background matching iOS */}
      <div 
        className="fixed inset-0 pointer-events-none"
        style={{
          background: `radial-gradient(circle at center, rgba(244, 241, 230, 0.9) 0%, rgb(244, 241, 230) 60%)`
        }}
      />
      
      <div className="relative z-10 px-4 py-8 md:py-12 lg:px-8">
        <div className="flex flex-col space-y-6 max-w-7xl mx-auto">
          {/* Military-styled header matching iOS */}
          <header className="text-left animate-fade-in">
            <h1 className="font-heading text-3xl md:text-4xl uppercase tracking-wider text-deep-ops font-bold">
              {selectedBoard.toUpperCase()} LEADERBOARD
            </h1>

            {/* Brass gold separator line */}
            <div className="my-4 h-0.5 w-32 bg-brass-gold" />

            <p className="text-sm md:text-base font-semibold tracking-wide text-deep-ops uppercase">
              {exerciseDisplayNames[selectedExercise as keyof typeof exerciseDisplayNames]} • {selectedCategory}
            </p>
          </header>
          
          {/* Segmented Control for Global/Local */}
          <div className="animate-fade-in animation-delay-100">
            <LeaderboardSegmentedControl
              selectedBoard={selectedBoard}
              onBoardChange={setSelectedBoard}
            />
          </div>

          {/* Filter Controls */}
          <div className="animate-fade-in animation-delay-200">
            <LeaderboardFilterBar
              selectedExercise={selectedExercise}
              selectedCategory={selectedCategory}
              selectedRadius={selectedRadius}
              showRadiusSelector={selectedBoard === 'Local'}
              onExerciseChange={setSelectedExercise}
              onCategoryChange={setSelectedCategory}
              onRadiusChange={setSelectedRadius}
            />
          </div>
          
          {/* Geolocation Alert - Show if needed */}
          {selectedBoard === 'Local' && geoState.error && (
            <Alert variant="destructive" className="rounded-lg">
              <AlertCircle className="w-5 h-5" />
              <AlertTitle className="font-heading text-sm">Location Error</AlertTitle>
              <AlertDescription>
                {geoState.error}
                <Button 
                  variant="outline" 
                  size="small" 
                  className="mt-2 border-brass-gold text-brass-gold" 
                  onClick={requestGeolocation}
                >
                  TRY AGAIN
                </Button>
              </AlertDescription>
            </Alert>
          )}
          
          {/* Location Status Alert - Only show when actively looking for location */}
          {geoState.isLoading && (
            <Alert className="rounded-lg border-olive-mist bg-olive-mist/10">
              <MapPin className="w-5 h-5 text-brass-gold" />
              <AlertTitle className="font-heading text-sm">Getting your location</AlertTitle>
              <AlertDescription>
                Please allow location access to view the local leaderboard.
              </AlertDescription>
            </Alert>
          )}

          {/* API Error Alert */}
          {isError && !geoState.isLoading && error instanceof Error && error.message !== 'Location permission required' && (
            <Alert variant="destructive" className="rounded-lg">
              <AlertCircle className="w-5 h-5" />
              <AlertTitle className="font-heading text-sm">Error loading leaderboard</AlertTitle>
              <AlertDescription>
                {error.message}
                <Button 
                  variant="outline" 
                  size="small" 
                  className="mt-2 border-brass-gold text-brass-gold" 
                  onClick={() => refetch()}
                >
                  RETRY
                </Button>
              </AlertDescription>
            </Alert>
          )}

          {/* Main Leaderboard Content Card */}
          <div className="bg-white rounded-lg shadow-md overflow-hidden animate-fade-in animation-delay-300">
            {/* Header with dark background */}
            <div className="bg-deep-ops text-cream p-4">
              <h3 className="text-xl font-bold text-brass-gold">TOP PERFORMERS</h3>
              <div className="h-px bg-brass-gold/30 my-2" />
              <p className="text-sm font-medium text-brass-gold">
                {selectedBoard === 'Local' 
                  ? `ATHLETES WITHIN ${selectedRadius} MILES`
                  : 'NATIONWIDE RANKINGS'
                }
              </p>
            </div>

            {/* Content area */}
            <div className="min-h-[300px]">
              {isLoading ? (
                // Enhanced loading state with skeletons
                <div className="space-y-0">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <LeaderboardRowSkeleton key={i} />
                  ))}
                  
                  {/* Floating loading indicator */}
                  <div className="absolute inset-0 flex items-center justify-center bg-white/30">
                    <div className="bg-white rounded-md p-3 shadow-lg">
                      <Loader2 className="w-6 h-6 animate-spin text-brass-gold" />
                    </div>
                  </div>
                </div>
              ) : isError && error instanceof Error && error.message !== 'Location permission required' ? (
                <LeaderboardErrorState
                  message={error.message}
                  onRetry={() => refetch()}
                />
              ) : processedLeaderboard.length > 0 ? (
                // Enhanced leaderboard rows
                <div className="divide-y divide-gray-100">
                  {processedLeaderboard.map((entry, index) => (
                    <div
                      key={`${entry.username}-${entry.rank}`}
                      className={cn(
                        "transition-all duration-300 ease-out",
                        visibleRows[index] 
                          ? "opacity-100 translate-y-0" 
                          : "opacity-0 translate-y-4"
                      )}
                    >
                      <EnhancedLeaderboardRow
                        entry={entry}
                        isCurrentUser={false} // TODO: Add current user detection
                        onClick={() => {
                          // TODO: Add navigation to user profile
                          console.log('Navigate to user:', entry.userId);
                        }}
                      />
                    </div>
                  ))}
                </div>
              ) : (
                <LeaderboardEmptyState
                  exerciseType={selectedExercise}
                  boardType={selectedBoard}
                />
              )}
            </div>
          </div>
          
          {/* Footer note */}
          <div className="mt-6 text-center text-xs text-tactical-gray">
            <p>Rankings reset weekly. Complete exercises to improve your position.</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Leaderboard; 