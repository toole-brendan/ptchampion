import { useEffect } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import Navigation from "@/components/navigation";
import PerformanceCard from "@/components/performance-card";
import ExerciseCard from "@/components/exercise-card";
import Leaderboard from "@/components/leaderboard";
import { Loader2, Settings } from "lucide-react";

export default function HomePage() {
  const { user, updateLocationMutation } = useAuth();
  const queryClient = useQueryClient();
  
  // Get all exercises
  const { 
    data: exercises, 
    isLoading: loadingExercises 
  } = useQuery({
    queryKey: ["/api/exercises"],
    enabled: !!user
  });
  
  // Get the latest exercise results
  const { 
    data: latestExercises, 
    isLoading: loadingLatest 
  } = useQuery({
    queryKey: ["/api/user-exercises/latest/all"],
    enabled: !!user
  });

  // Update location for local leaderboard if needed
  useEffect(() => {
    // Only request location if user is logged in and location isn't already stored
    if (user && navigator.geolocation && (!user.latitude || !user.longitude)) {
      // Define the position function
      const getPosition = () => {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            console.log("Home - Position obtained:", position.coords);
            updateLocationMutation.mutate({
              latitude: position.coords.latitude,
              longitude: position.coords.longitude
            }, {
              onSuccess: (updatedUser) => {
                console.log("Home - Location updated:", updatedUser);
                // Invalidate leaderboard queries to refresh the data
                queryClient.invalidateQueries({ queryKey: ["/api/leaderboard/local"] });
              },
              onError: (error) => {
                console.error("Home - Update location error:", error);
                // No toast here to avoid disruption on homepage load
              }
            });
          },
          (error) => {
            console.error("Home - Geolocation error:", error);
            // No need to show a toast here as it would be disruptive on homepage load
          },
          {
            // More precise settings for better reliability
            enableHighAccuracy: true,
            timeout: 15000, // Increased timeout for slower devices/connections
            maximumAge: 0
          }
        );
      };

      // Try to request location with better error handling
      try {
        navigator.permissions?.query({ name: 'geolocation' }).then((permissionStatus) => {
          if (permissionStatus.state === 'granted' || permissionStatus.state === 'prompt') {
            getPosition();
          }
          // If denied, don't show any message on home page to avoid disruption
        }).catch(() => {
          // If the permissions API fails, try regular getCurrentPosition
          getPosition();
        });
      } catch (e) {
        // If permissions API isn't available, just try to get position
        getPosition();
      }
    }
  }, [user, updateLocationMutation, queryClient]);

  // Helper to get the latest score for an exercise type
  const getLatestScore = (type: string) => {
    if (!latestExercises) return null;
    // Type assertion to help TypeScript understand the structure
    return (latestExercises as Record<string, any>)?.[type] || null;
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      {/* Header */}
      <header className="bg-white border-b border-slate-200">
        <div className="container px-4 py-3 mx-auto flex items-center justify-between">
          <div className="flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" className="h-8 w-8 text-accent" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M18 8h1a4 4 0 0 1 0 8h-1"></path>
              <path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"></path>
              <line x1="6" y1="1" x2="6" y2="4"></line>
              <line x1="10" y1="1" x2="10" y2="4"></line>
              <line x1="14" y1="1" x2="14" y2="4"></line>
            </svg>
            <h1 className="ml-2 text-xl font-bold text-primary">PT Champion</h1>
          </div>
          <div>
            <button className="p-2 rounded-full bg-slate-100">
              <Settings className="h-5 w-5 text-primary" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        <section className="py-6 px-4 lg:px-8">
          <div className="container mx-auto max-w-5xl">
            <h2 className="text-2xl font-bold mb-6">Dashboard</h2>
            
            {/* Overall Performance Card */}
            {loadingLatest ? (
              <div className="bg-white rounded-xl shadow-sm p-4 mb-6 flex justify-center items-center h-32">
                <Loader2 className="h-8 w-8 animate-spin text-accent" />
              </div>
            ) : (
              <PerformanceCard latestExercises={latestExercises as Record<string, any>} />
            )}
            
            {/* Exercise Selection */}
            <h3 className="text-lg font-semibold mb-3">Select Exercise</h3>
            {loadingExercises ? (
              <div className="bg-white rounded-xl shadow-sm p-4 mb-6 flex justify-center items-center h-48">
                <Loader2 className="h-8 w-8 animate-spin text-accent" />
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {(Array.isArray(exercises) ? exercises : []).map((exercise: any) => (
                  <ExerciseCard 
                    key={exercise.id} 
                    exercise={exercise} 
                    latestScore={getLatestScore(exercise.type)}
                  />
                ))}
              </div>
            )}
            
            {/* Leaderboard Section */}
            <Leaderboard />
          </div>
        </section>
      </main>

      {/* Bottom Navigation */}
      <Navigation active="home" />
    </div>
  );
}
