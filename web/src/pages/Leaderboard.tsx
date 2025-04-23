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
import { AlertCircle, Loader2 } from 'lucide-react';

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

  // Dynamically set the card title
  const cardTitle = `Top Performers - ${exerciseDisplayNames[exerciseFilter as keyof typeof exerciseDisplayNames]} (${scopeFilter})`;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-foreground">Leaderboard</h1>
      
      {/* Geolocation Alert - Show if needed */}
      {scopeFilter === scopeOptions[1] && geoState.error && (
        <Alert variant="destructive" className="mb-4">
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Location Error</AlertTitle>
          <AlertDescription>
            {geoState.error}
            <Button 
              variant="outline" 
              size="sm" 
              className="mt-2" 
              onClick={requestGeolocation}
            >
              Try Again
            </Button>
          </AlertDescription>
        </Alert>
      )}
      
      {/* Location Status Alert - Only show when actively looking for location */}
      {geoState.isLoading && (
        <Alert className="mb-4">
          <AlertTitle>Getting your location</AlertTitle>
          <AlertDescription>
            Please allow location access to view the local leaderboard.
          </AlertDescription>
        </Alert>
      )}

      {/* API Error Alert */}
      {isError && !geoState.isLoading && error instanceof Error && error.message !== 'Location permission required' && (
        <Alert variant="destructive" className="mb-4">
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Error loading leaderboard</AlertTitle>
          <AlertDescription>
            {error.message}
            <Button 
              variant="outline" 
              size="sm" 
              className="mt-2" 
              onClick={() => refetch()}
            >
              Retry
            </Button>
          </AlertDescription>
        </Alert>
      )}

      {/* Leaderboard Table Card */}
      <Card className="rounded-lg border border-border bg-card shadow-sm transition-shadow hover:shadow-md">
        <CardHeader>
          <CardTitle className="text-lg font-semibold">{cardTitle}</CardTitle>
          <CardDescription className="text-muted-foreground">See how you stack up against the competition.</CardDescription>
        </CardHeader>
        <CardContent>
            {/* Filter Controls */}
            <div className="mb-6 flex flex-col gap-4 sm:flex-row">
              <div className="flex-1 space-y-1.5">
                <Label htmlFor="exercise-filter" className="text-sm font-medium">Exercise</Label>
                <Select value={exerciseFilter} onValueChange={setExerciseFilter}>
                  <SelectTrigger id="exercise-filter">
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
              <div className="flex-1 space-y-1.5">
                <Label htmlFor="scope-filter" className="text-sm font-medium">Scope</Label>
                <Select value={scopeFilter} onValueChange={setScopeFilter}>
                  <SelectTrigger id="scope-filter">
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
                <p className="mt-4 text-center text-muted-foreground">
                  Loading leaderboard data...
                </p>
              </div>
            ) : processedLeaderboard.length > 0 ? (
              <Table>
                <TableCaption className="py-4 text-muted-foreground">
                  Leaderboard rankings based on selected criteria.
                </TableCaption>
                <TableHeader>
                <TableRow className="border-b border-border hover:bg-transparent">
                    <TableHead className="w-[80px] font-medium text-muted-foreground">Rank</TableHead>
                    <TableHead className="font-medium text-muted-foreground">User</TableHead>
                    <TableHead className="text-right font-medium text-muted-foreground">Score</TableHead>
                </TableRow>
                </TableHeader>
                <TableBody>
                  {processedLeaderboard.map((user) => (
                    <TableRow key={`${user.username}-${user.rank}`} className="border-b border-border/50 transition-colors hover:bg-muted/50">
                        <TableCell className="text-lg font-semibold text-primary">{user.rank}</TableCell>
                        <TableCell>
                            <div className="flex items-center space-x-3">
                                <Avatar className="size-8">
                                    <AvatarImage src={user.avatar || undefined} alt={user.name} />
                                    <AvatarFallback className="bg-muted text-xs font-medium text-muted-foreground">
                                        {getInitials(user.name)}
                                    </AvatarFallback>
                                </Avatar>
                                <span className="font-medium text-foreground">{user.name}</span>
                            </div>
                        </TableCell>
                        <TableCell className="text-right font-medium tabular-nums text-foreground">{user.score}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <div className="flex flex-col items-center justify-center py-8">
                <Player
                  autoplay
                  loop
                  src={emptyLeaderboardAnimation}
                  style={{ height: '200px', width: '200px' }}
                  className="text-brass-gold"
                />
                <p className="mt-4 text-center text-muted-foreground">
                  No rankings found for {exerciseDisplayNames[exerciseFilter as keyof typeof exerciseDisplayNames]}.
                </p>
                <p className="text-center text-sm text-muted-foreground">
                  {scopeFilter === scopeOptions[1]
                    ? "Try changing to Global scope or completing an exercise in this area."
                    : "Try selecting a different exercise type or complete your first workout to get on the board."
                  }
                </p>
              </div>
            )}
        </CardContent>
      </Card>
    </div>
  );
};

export default Leaderboard; 