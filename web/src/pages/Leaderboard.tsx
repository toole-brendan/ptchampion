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
import emptyLeaderboardAnimation from '@/assets/empty-leaderboard.json'; // Import animation JSON

// Mock data for leaderboard
const mockLeaderboard = [
  { rank: 1, name: 'Alex Johnson', score: 1550, exercise: 'Overall', avatar: 'https://github.com/shadcn.png' },
  { rank: 2, name: 'Maria Garcia', score: 1480, exercise: 'Overall', avatar: null },
  { rank: 3, name: 'Brendan Toole', score: 1450, exercise: 'Overall', avatar: 'https://github.com/brendantoole.png' },
  { rank: 4, name: 'Kenji Tanaka', score: 1390, exercise: 'Overall', avatar: null },
  { rank: 5, name: 'Fatima Ahmed', score: 1350, exercise: 'Overall', avatar: null },
  { rank: 1, name: 'Alex Johnson', score: 45, exercise: 'Push-ups', avatar: 'https://github.com/shadcn.png' },
  { rank: 2, name: 'Brendan Toole', score: 42, exercise: 'Push-ups', avatar: 'https://github.com/brendantoole.png' },
  { rank: 3, name: 'Maria Garcia', score: 40, exercise: 'Push-ups', avatar: null },
  { rank: 1, name: 'Kenji Tanaka', score: 65, exercise: 'Sit-ups', avatar: null },
  { rank: 2, name: 'Fatima Ahmed', score: 62, exercise: 'Sit-ups', avatar: null },
  { rank: 3, name: 'Alex Johnson', score: 60, exercise: 'Sit-ups', avatar: 'https://github.com/shadcn.png' },
  { rank: 1, name: 'Maria Garcia', score: 15, exercise: 'Pull-ups', avatar: null },
  { rank: 2, name: 'Alex Johnson', score: 12, exercise: 'Pull-ups', avatar: 'https://github.com/shadcn.png' },
  { rank: 1, name: 'Brendan Toole', score: 5.2, exercise: 'Running', avatar: 'https://github.com/brendantoole.png' }, // Score = km for running?
  { rank: 2, name: 'Fatima Ahmed', score: 4.8, exercise: 'Running', avatar: null },
];

const exerciseOptions = ['Overall', 'Push-ups', 'Sit-ups', 'Pull-ups', 'Running'];
const scopeOptions = ['Global', 'Local (5 Miles)']; // Local needs implementation

// Helper to get initials from name
const getInitials = (name: string) => {
    return name
      .split(' ')
      .map((n) => n[0])
      .join('');
  };

interface GeolocationState {
  isLoading: boolean;
  isSupported: boolean;
  isPermissionGranted: boolean;
  coordinates: { latitude: number; longitude: number } | null;
  error: string | null;
}

const Leaderboard: React.FC = () => {
  const api = useApi();
  const [exerciseFilter, setExerciseFilter] = useState<string>(exerciseOptions[0]); // Default to Overall
  const [scopeFilter, setScopeFilter] = useState<string>(scopeOptions[0]); // Default to Global
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [leaderboardData, setLeaderboardData] = useState(mockLeaderboard);
  
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
        
        // When we get location, if scope is local, fetch local leaderboard
        if (scopeFilter === scopeOptions[1]) {
          fetchLeaderboardData(exerciseFilter, true, position.coords.latitude, position.coords.longitude);
        }
      },
      (error) => {
        let errorMessage = "Unknown error occurred while accessing your location";
        
        switch (error.code) {
          case error.PERMISSION_DENIED:
            errorMessage = "Location permission was denied. Please enable location services to use the local leaderboard.";
            break;
          case error.POSITION_UNAVAILABLE:
            errorMessage = "Location information is unavailable.";
            break;
          case error.TIMEOUT:
            errorMessage = "The request to get your location timed out.";
            break;
        }
        
        setGeoState({
          isLoading: false,
          isSupported: true,
          isPermissionGranted: false,
          coordinates: null,
          error: errorMessage
        });
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 }
    );
  };

  // Fetch leaderboard data
  const fetchLeaderboardData = async (exercise: string, isLocal: boolean, lat?: number, lng?: number) => {
    setIsLoading(true);
    try {
      // In a real app, we would use the API client to fetch data
      // For now, simulate API call with timeout and mock data filtering
      
      // Example of how the API call might look:
      // const params = new URLSearchParams();
      // if (exercise !== 'Overall') params.append('exercise', exercise.toLowerCase());
      // if (isLocal && lat && lng) {
      //   params.append('lat', lat.toString());
      //   params.append('lng', lng.toString());
      //   params.append('radius', '5'); // 5 miles
      // }
      // const response = await api.get(`/leaderboard?${params.toString()}`);
      // setLeaderboardData(response.data);
      
      // Mock implementation - filter mockLeaderboard
      await new Promise(resolve => setTimeout(resolve, 500)); // Simulate network delay
      
      // Just filter the mock data for demo purposes
      const filtered = mockLeaderboard
          .filter(user => user.exercise === exercise)
          .sort((a, b) => a.rank - b.rank);
      
      setLeaderboardData(filtered);
    } catch (error) {
      console.error("Error fetching leaderboard data:", error);
      // Could set an error state here
    } finally {
      setIsLoading(false);
    }
  };

  // Effect to handle scope change
  useEffect(() => {
    const isLocalScope = scopeFilter === scopeOptions[1];
    
    if (isLocalScope && !geoState.coordinates) {
      // If local scope selected but no coordinates, request them
      requestGeolocation();
    } else {
      // Otherwise fetch appropriate data
      fetchLeaderboardData(
        exerciseFilter,
        isLocalScope,
        geoState.coordinates?.latitude,
        geoState.coordinates?.longitude
      );
    }
  }, [scopeFilter, exerciseFilter, geoState.coordinates]);

  // Filter leaderboard data based on selections
  const filteredLeaderboard = useMemo(() => {
    if (isLoading) return [];
    
    // Filter is now handled by the API/fetchLeaderboardData
    return leaderboardData;
  }, [leaderboardData, isLoading]);

  // Dynamically set the card title
  const cardTitle = `Top Performers - ${exerciseFilter} (${scopeFilter})`;

  return (
    <div className="space-y-6"> {/* Reduced vertical spacing */}
      <h1 className="text-2xl font-semibold text-foreground">Leaderboard</h1> {/* Standardized heading */}
      
      {/* Geolocation Alert - Show if needed */}
      {scopeFilter === scopeOptions[1] && geoState.error && (
        <Alert variant="destructive" className="mb-4">
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

      {/* Leaderboard Table Card */}
      <Card className="bg-card rounded-lg shadow-sm border border-border transition-shadow hover:shadow-md"> {/* Added hover effect */}
        <CardHeader>
          <CardTitle className="text-lg font-semibold">{cardTitle}</CardTitle> {/* Standardized card title */}
          <CardDescription className="text-muted-foreground">See how you stack up against the competition.</CardDescription> {/* Ensured muted color */}
        </CardHeader>
        <CardContent>
            {/* Filter Controls - Now here */}
            <div className="flex flex-col sm:flex-row gap-4 mb-6"> {/* Increased bottom margin slightly */}
              <div className="flex-1 space-y-1.5"> {/* Added space-y for label consistency */}
                <Label htmlFor="exercise-filter" className="text-sm font-medium">Exercise</Label> {/* Ensured label style */}
                <Select value={exerciseFilter} onValueChange={setExerciseFilter}>
                  <SelectTrigger id="exercise-filter">
                    <SelectValue placeholder="Select Exercise" />
                  </SelectTrigger>
                  <SelectContent>
                    {exerciseOptions.map(option => (
                      <SelectItem key={option} value={option}>{option}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="flex-1 space-y-1.5"> {/* Added space-y for label consistency */}
                <Label htmlFor="scope-filter" className="text-sm font-medium">Scope</Label> {/* Ensured label style */}
                <Select value={scopeFilter} onValueChange={setScopeFilter}>
                  <SelectTrigger id="scope-filter">
                    <SelectValue placeholder="Select Scope" />
                  </SelectTrigger>
                  <SelectContent>
                    {scopeOptions.map(option => (
                      <SelectItem
                        key={option}
                        value={option}
                      >
                        {option}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            {isLoading ? (
              <div className="flex justify-center items-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-brass-gold"></div>
              </div>
            ) : filteredLeaderboard.length > 0 ? (
              <Table>
                <TableCaption className="text-muted-foreground py-4">
                  Leaderboard rankings based on selected criteria.
                </TableCaption>
                <TableHeader>
                <TableRow className="border-b border-border hover:bg-transparent"> {/* Removed hover effect from header row */}
                    <TableHead className="w-[80px] text-muted-foreground font-medium">Rank</TableHead> {/* Styled header */}
                    <TableHead className="text-muted-foreground font-medium">User</TableHead> {/* Styled header */}
                    <TableHead className="text-right text-muted-foreground font-medium">Score</TableHead> {/* Styled header */}
                </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredLeaderboard.map((user) => (
                    // Added hover effect to body rows
                    <TableRow key={`${user.exercise}-${user.rank}-${user.name}`} className="border-b border-border/50 hover:bg-muted/50 transition-colors">
                        <TableCell className="font-semibold text-lg text-primary">{user.rank}</TableCell> {/* Kept rank prominent */}
                        <TableCell>
                            <div className="flex items-center space-x-3">
                                <Avatar className="h-8 w-8"> {/* Slightly smaller avatar */}
                                    <AvatarImage src={user.avatar || undefined} alt={user.name} />
                                    <AvatarFallback className="bg-muted text-muted-foreground text-xs font-medium"> {/* Consistent fallback style */}
                                        {getInitials(user.name)}
                                    </AvatarFallback>
                                </Avatar>
                                <span className="font-medium text-foreground">{user.name}</span>
                            </div>
                        </TableCell>
                        <TableCell className="text-right font-medium text-foreground tabular-nums">{user.score}</TableCell> {/* Ensured consistent font, added tabular-nums */}
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
                <p className="text-center text-muted-foreground mt-4">
                  No rankings found for {exerciseFilter}.
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