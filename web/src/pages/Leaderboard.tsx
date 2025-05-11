import React, { useState, useMemo, useEffect } from 'react';
import {
    Table,
    TableBody,
    TableCaption,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
  } from "@/components/ui/table";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"; // For user avatars
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select"; // For filtering
import { Label } from "@/components/ui/label"; // For filter labels
import { cn } from "@/lib/utils"; // Import cn utility
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

// Military-style corner component
const MilitaryCorners: React.FC = () => (
  <>
    {/* Military corner cutouts - top left and right */}
    <div className="absolute top-0 left-0 w-[15px] h-[15px] bg-background"></div>
    <div className="absolute top-0 right-0 w-[15px] h-[15px] bg-background"></div>
    
    {/* Military corner cutouts - bottom left and right */}
    <div className="absolute bottom-0 left-0 w-[15px] h-[15px] bg-background"></div>
    <div className="absolute bottom-0 right-0 w-[15px] h-[15px] bg-background"></div>
    
    {/* Diagonal lines for corners */}
    <div className="absolute top-0 left-0 w-[15px] h-[1px] bg-tactical-gray/50 rotate-45 origin-top-left"></div>
    <div className="absolute top-0 right-0 w-[15px] h-[1px] bg-tactical-gray/50 -rotate-45 origin-top-right"></div>
    <div className="absolute bottom-0 left-0 w-[15px] h-[1px] bg-tactical-gray/50 -rotate-45 origin-bottom-left"></div>
    <div className="absolute bottom-0 right-0 w-[15px] h-[1px] bg-tactical-gray/50 rotate-45 origin-bottom-right"></div>
  </>
);

// Header divider component
const HeaderDivider: React.FC = () => (
  <div className="h-[1px] w-16 bg-brass-gold mx-auto my-2"></div>
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

  // Request geolocation permission
  const requestGeolocation = () => {
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
  };

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
  }, [scopeFilter]);

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
      avatar: null // API doesn't provide avatars yet
    }));
  }, [leaderboardData]);

  return (
    <div className="space-y-section">
      <div className="relative overflow-hidden rounded-card bg-card-background p-content shadow-medium">
        <MilitaryCorners />
        <div className="mb-4 text-center">
          <h2 className="font-heading text-heading3 uppercase tracking-wider text-command-black">
            Leaderboard
          </h2>
          <HeaderDivider />
          <p className="mt-2 text-sm uppercase tracking-wide text-tactical-gray">Compare your performance</p>
        </div>
      </div>
      
      {/* Geolocation Alert - Show if needed */}
      {scopeFilter === scopeOptions[1] && geoState.error && (
        <Alert variant="destructive" className="rounded-card">
          <AlertCircle className="h-5 w-5" />
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
        <Alert className="rounded-card bg-olive-mist/10 border-olive-mist">
          <MapPin className="h-5 w-5 text-brass-gold" />
          <AlertTitle className="font-heading text-sm">Getting your location</AlertTitle>
          <AlertDescription>
            Please allow location access to view the local leaderboard.
          </AlertDescription>
        </Alert>
      )}

      {/* API Error Alert */}
      {isError && !geoState.isLoading && error instanceof Error && error.message !== 'Location permission required' && (
        <Alert variant="destructive" className="rounded-card">
          <AlertCircle className="h-5 w-5" />
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

      {/* Leaderboard Filters */}
      <div className="relative overflow-hidden rounded-card bg-card-background shadow-medium">
        <MilitaryCorners />
        <div className="rounded-t-card bg-deep-ops p-content">
          <div className="flex items-center">
            <Trophy className="mr-2 size-5 text-brass-gold" />
            <h2 className="font-heading text-heading4 text-cream uppercase tracking-wider">
              {exerciseDisplayNames[exerciseFilter as keyof typeof exerciseDisplayNames]} Rankings
            </h2>
          </div>
          <p className="text-sm text-army-tan">
            {scopeFilter === scopeOptions[1] 
              ? 'See how you compare to athletes in your area'
              : 'See how you measure up against the global competition'}
          </p>
        </div>
        
        <div className="p-content">
          {/* Filter Controls */}
          <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="exercise-filter" className="text-sm font-semibold uppercase tracking-wide text-tactical-gray">Exercise Type</Label>
              <Select value={exerciseFilter} onValueChange={setExerciseFilter}>
                <SelectTrigger id="exercise-filter" className="bg-cream border-army-tan/30">
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
            
            <div className="space-y-2">
              <Label htmlFor="scope-filter" className="text-sm font-semibold uppercase tracking-wide text-tactical-gray">Leaderboard Scope</Label>
              <Select value={scopeFilter} onValueChange={setScopeFilter}>
                <SelectTrigger id="scope-filter" className="bg-cream border-army-tan/30">
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
            <div className="flex flex-col items-center justify-center py-12">
              <Loader2 className="h-12 w-12 animate-spin text-brass-gold" />
              <p className="mt-4 text-center text-tactical-gray font-semibold">
                Loading leaderboard data...
              </p>
            </div>
          ) : processedLeaderboard.length > 0 ? (
            <div className="overflow-hidden rounded-card border border-olive-mist/20">
              <Table className="w-full">
                <TableHeader>
                  <TableRow className="bg-tactical-gray/10 hover:bg-transparent">
                    <TableHead className="w-[80px] font-heading uppercase text-tactical-gray text-xs tracking-wider">Rank</TableHead>
                    <TableHead className="font-heading uppercase text-tactical-gray text-xs tracking-wider">User</TableHead>
                    <TableHead className="text-right font-heading uppercase text-tactical-gray text-xs tracking-wider">Score</TableHead>
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
                          <Avatar className="size-8 border-2 border-brass-gold/20">
                            <AvatarImage src={user.avatar || undefined} alt={user.name} />
                            <AvatarFallback className="bg-army-tan/20 text-xs font-medium text-tactical-gray">
                              {getInitials(user.name)}
                            </AvatarFallback>
                          </Avatar>
                          <span className="font-semibold text-command-black">{user.name}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-right font-heading tabular-nums text-brass-gold text-lg">{user.score}</TableCell>
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
        </div>
      </div>
    </div>
  );
};

export default Leaderboard; 