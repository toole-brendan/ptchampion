import React, { useState, useMemo, useEffect, useCallback } from 'react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"; // For user avatars
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select"; // For filtering
import { Label } from "@/components/ui/label"; // For filter labels
import { cn, formatLeaderboardScore } from "@/lib/utils"; // Import utilities
import { Button } from "@/components/ui/button";
import { 
  Alert,
  AlertDescription,
  AlertTitle,
} from "@/components/ui/alert";
import { useApi } from "@/lib/apiClient"; // Import API client hook
import { Player } from '@lottiefiles/react-lottie-player'; // Import Lottie player
import emptyLeaderboardAnimation from '@/assets/empty-leaderboard.json';
import { useQuery } from '@tanstack/react-query';
import { AlertCircle, Loader2, Trophy, Medal, MapPin } from 'lucide-react';
import { SkeletonRow } from '@/components/ui/skeleton';
import { useToast } from '@/components/ui/use-toast';
import { SectionCard, CardDivider } from "@/components/ui/card"; // Import card components from design system

// Header divider component
const HeaderDivider: React.FC = () => (
  <CardDivider className="mx-auto" />
);

const exerciseOptions = ['overall', 'pushup', 'situp', 'pullup', 'running'];
const exerciseDisplayNames = {
  'overall': 'Overall',
  'pushup': 'Push-ups',
  'situp': 'Sit-ups',
  'pullup': 'Pull-ups',
  'running': 'Running'
};
const scopeOptions = ['Global', 'Local (5 Miles)']; // Local needs implementation

// Helper to get initials from name
const getInitials = (name: string) => {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('');
};

// Get medal component based on rank
const getRankMedal = (rank: number) => {
  if (rank === 1) return <Medal className="size-6 text-yellow-500" />;
  if (rank === 2) return <Medal className="size-6 text-gray-400" />;
  if (rank === 3) return <Medal className="size-6 text-amber-700" />;
  return null;
};

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
  const [exerciseFilter, setExerciseFilter] = useState<string>(exerciseOptions[0]); // Default to overall
  const [scopeFilter, setScopeFilter] = useState<string>(scopeOptions[0]); // Default to Global
  
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
    queryKey: ['leaderboard', exerciseFilter, scopeFilter, geoState.coordinates],
    queryFn: async () => {
      const isLocalScope = scopeFilter === scopeOptions[1];
      
      if (isLocalScope && !geoState.coordinates) {
        // If local scope selected but no coordinates, throw error to trigger request
        throw new Error('Location permission required');
      }

      if (isLocalScope) {
        // Call local leaderboard API
        return api.leaderboard.getLocalLeaderboard(
          exerciseFilter,
          geoState.coordinates!.latitude,
          geoState.coordinates!.longitude,
          8047 // ~5 miles in meters
        );
      } else {
        // Call global leaderboard API
        return api.leaderboard.getLeaderboard(exerciseFilter);
      }
    },
    enabled: !(scopeFilter === scopeOptions[1] && !geoState.coordinates && !geoState.isLoading),
    retry: 1,
    retryDelay: 1000,
  });

  // Effect to handle scope change
  useEffect(() => {
    const isLocalScope = scopeFilter === scopeOptions[1];
    
    if (isLocalScope && !geoState.coordinates && !geoState.error) {
      // If local scope selected but no coordinates, request them
      requestGeolocation();
    }
  }, [scopeFilter, geoState.coordinates, geoState.error, requestGeolocation]);

  // Process the leaderboard data for display
  const processedLeaderboard = useMemo(() => {
    if (!leaderboardData || !Array.isArray(leaderboardData)) return [];
    
    // Convert API data to display format with ranks
    return leaderboardData.map((entry, index) => ({
      rank: index + 1,
      name: entry.display_name || entry.username,
      username: entry.username,
      userId: entry.user_id,
      score: entry.max_grade !== undefined ? entry.max_grade : 0,
      formattedScore: formatLeaderboardScore(exerciseFilter, entry.max_grade || 0),
      avatar: entry.profile_picture_url || null // Use profile pic if available
    }));
  }, [leaderboardData, exerciseFilter]);

  return (
    <div className="bg-cream min-h-screen px-4 py-section md:py-12 lg:px-8">
      <div className="flex flex-col space-y-section max-w-7xl mx-auto">
        {/* Header Section Card */}
        <SectionCard
          title="Leaderboard"
          description="Compare your performance"
          icon={<Trophy className="size-5" />}
          className="animate-fade-in"
          showDivider
        >
          <div className="flex flex-col items-center">
            <HeaderDivider />
            <p className="mt-2 text-sm uppercase tracking-wide text-tactical-gray">
              Track your progress against other athletes
            </p>
          </div>
        </SectionCard>
        
        {/* Geolocation Alert - Show if needed */}
        {scopeFilter === scopeOptions[1] && geoState.error && (
          <Alert variant="destructive" className="rounded-card">
            <AlertCircle className="size-5" />
            <AlertTitle className="font-heading text-sm">Location Error</AlertTitle>
            <AlertDescription>
              {geoState.error}
              <Button 
                variant="outline" 
                size="sm" 
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
          <Alert className="rounded-card border-olive-mist bg-olive-mist/10">
            <MapPin className="size-5 text-brass-gold" />
            <AlertTitle className="font-heading text-sm">Getting your location</AlertTitle>
            <AlertDescription>
              Please allow location access to view the local leaderboard.
            </AlertDescription>
          </Alert>
        )}

        {/* API Error Alert */}
        {isError && !geoState.isLoading && error instanceof Error && error.message !== 'Location permission required' && (
          <Alert variant="destructive" className="rounded-card">
            <AlertCircle className="size-5" />
            <AlertTitle className="font-heading text-sm">Error loading leaderboard</AlertTitle>
            <AlertDescription>
              {error.message}
              <Button 
                variant="outline" 
                size="sm" 
                className="mt-2 border-brass-gold text-brass-gold" 
                onClick={() => refetch()}
              >
                RETRY
              </Button>
            </AlertDescription>
          </Alert>
        )}

        {/* Main Leaderboard Section Card */}
        <SectionCard
          title={`${exerciseDisplayNames[exerciseFilter as keyof typeof exerciseDisplayNames]} Rankings`}
          description={scopeFilter === scopeOptions[1] 
            ? 'See how you compare to athletes in your area'
            : 'See how you measure up against the global competition'
          }
          icon={<Trophy className="size-5" />}
          className="animate-fade-in animation-delay-100"
          showDivider
        >
          {/* Filter Controls - Improved for responsiveness */}
          <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="min-w-[140px] space-y-2">
              <Label htmlFor="exercise-filter" className="font-semibold text-xs uppercase tracking-wide text-tactical-gray">Exercise Type</Label>
              <Select value={exerciseFilter} onValueChange={setExerciseFilter}>
                <SelectTrigger 
                  id="exercise-filter" 
                  className="border-army-tan/30 bg-cream"
                  aria-label="Select exercise type"
                >
                  <SelectValue placeholder="Select Exercise" />
                </SelectTrigger>
                <SelectContent>
                  {exerciseOptions.map(option => (
                    <SelectItem key={option} value={option}>
                      {exerciseDisplayNames[option as keyof typeof exerciseDisplayNames]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="min-w-[140px] space-y-2">
              <Label htmlFor="scope-filter" className="font-semibold text-xs uppercase tracking-wide text-tactical-gray">Leaderboard Scope</Label>
              <Select value={scopeFilter} onValueChange={setScopeFilter}>
                <SelectTrigger 
                  id="scope-filter" 
                  className="border-army-tan/30 bg-cream"
                  aria-label="Select leaderboard scope"
                >
                  <SelectValue placeholder="Select Scope" />
                </SelectTrigger>
                <SelectContent>
                  {scopeOptions.map(option => (
                    <SelectItem key={option} value={option}>{option}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {isLoading ? (
            // Skeleton loading state
            <div className="relative overflow-hidden rounded-card border border-olive-mist/20">
              <Table className="w-full">
                <TableHeader>
                  <TableRow className="bg-tactical-gray/10 hover:bg-transparent">
                    <TableHead className="w-[80px] font-heading text-xs uppercase tracking-wider text-tactical-gray">Rank</TableHead>
                    <TableHead className="font-heading text-xs uppercase tracking-wider text-tactical-gray">User</TableHead>
                    <TableHead className="text-right font-heading text-xs uppercase tracking-wider text-tactical-gray">Score</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {Array.from({ length: 10 }).map((_, i) => (
                    <SkeletonRow key={i} />
                  ))}
                </TableBody>
              </Table>
              
              {/* Floating loading indicator */}
              <div className="absolute inset-0 flex items-center justify-center bg-background/30">
                <div className="bg-card-background rounded-md p-3 shadow-lg">
                  <Loader2 className="size-6 animate-spin text-brass-gold" />
                </div>
              </div>
            </div>
          ) : processedLeaderboard.length > 0 ? (
            <div className="relative overflow-hidden rounded-card border border-olive-mist/20">
              <Table className="w-full">
                <caption className="sr-only">
                  {exerciseDisplayNames[exerciseFilter as keyof typeof exerciseDisplayNames]} Leaderboard - {scopeFilter}
                </caption>
                <TableHeader>
                  <TableRow className="bg-tactical-gray/10 hover:bg-transparent">
                    <TableHead className="w-[80px] font-heading text-xs uppercase tracking-wider text-tactical-gray">Rank</TableHead>
                    <TableHead className="font-heading text-xs uppercase tracking-wider text-tactical-gray">User</TableHead>
                    <TableHead className="text-right font-heading text-xs uppercase tracking-wider text-tactical-gray">Score</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {processedLeaderboard.map((user) => (
                    <TableRow 
                      key={`${user.username}-${user.rank}`} 
                      className={cn(
                        "border-b border-olive-mist/10 transition-colors hover:bg-brass-gold/5",
                        user.rank <= 3 && "bg-cream/30"
                      )}
                    >
                      <TableCell className="flex items-center space-x-2">
                        <span className={cn(
                          "font-heading text-lg",
                          user.rank === 1 && "text-yellow-600",
                          user.rank === 2 && "text-gray-500",
                          user.rank === 3 && "text-amber-800"
                        )}>{user.rank}</span>
                        {getRankMedal(user.rank)}
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center space-x-3">
                          <Avatar className={cn(
                            "border-brass-gold/20 size-8 border-2",
                            // Add shadow highlight to top 3
                            user.rank <= 3 && "shadow-md shadow-brass-gold/20"
                          )}>
                            <AvatarImage src={user.avatar || undefined} alt={user.name} />
                            <AvatarFallback className="bg-army-tan/20 text-xs font-medium text-tactical-gray">
                              {getInitials(user.name)}
                            </AvatarFallback>
                          </Avatar>
                          <span className="font-semibold text-command-black">{user.name}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-right font-heading text-lg tabular-nums text-brass-gold">
                        {user.formattedScore}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center py-8">
              <Player
                autoplay
                loop
                src={emptyLeaderboardAnimation}
                style={{ height: '200px', width: '200px' }}
                className="text-brass-gold"
              />
              <p className="mt-4 text-center font-semibold text-tactical-gray">
                No rankings found for {exerciseDisplayNames[exerciseFilter as keyof typeof exerciseDisplayNames]}.
              </p>
              <p className="text-center text-sm text-tactical-gray">
                {scopeFilter === scopeOptions[1]
                  ? "Try changing to Global scope or completing an exercise in this area."
                  : "Try selecting a different exercise type or complete your first workout to get on the board."
                }
              </p>
            </div>
          )}
          
          <div className="mt-4 text-center text-xs text-tactical-gray">
            <p>Rankings reset weekly. Complete exercises to improve your position.</p>
          </div>
        </SectionCard>
      </div>
    </div>
  );
};

export default Leaderboard; 