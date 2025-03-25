import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Loader2 } from "lucide-react";

export default function Leaderboard() {
  const { user } = useAuth();
  const [view, setView] = useState<"global" | "local">("global");
  
  // Get global leaderboard
  const { data: globalLeaderboard, isLoading: loadingGlobal } = useQuery({
    queryKey: ["/api/leaderboard/global"],
    enabled: !!user && view === "global"
  });
  
  // Get local leaderboard
  const { data: localLeaderboard, isLoading: loadingLocal } = useQuery({
    queryKey: [
      "/api/leaderboard/local", 
      user?.latitude?.toString() || "", 
      user?.longitude?.toString() || ""
    ],
    queryFn: async ({ queryKey }) => {
      const [_, latitude, longitude] = queryKey;
      if (!latitude || !longitude) return [];
      
      const res = await fetch(`/api/leaderboard/local?latitude=${latitude}&longitude=${longitude}&radius=5`);
      if (!res.ok) throw new Error("Failed to fetch local leaderboard");
      return res.json();
    },
    enabled: !!user && !!user.latitude && !!user.longitude && view === "local"
  });
  
  // Get the current leaderboard data based on view
  const leaderboardData = view === "global" ? globalLeaderboard : localLeaderboard;
  const isLoading = view === "global" ? loadingGlobal : loadingLocal;
  
  // Format run time for display
  const formatRunTime = (seconds: number | null | undefined): string => {
    if (seconds === null || seconds === undefined) return "-";
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };
  
  return (
    <div className="mt-10">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-lg font-semibold">Leaderboard</h3>
        <div className="flex flex-col items-end">
          <div className="flex mb-1">
            <Button
              variant={view === "global" ? "default" : "outline"}
              size="sm"
              className="rounded-l-md px-3"
              onClick={() => setView("global")}
            >
              Global
            </Button>
            <Button
              variant={view === "local" ? "default" : "outline"}
              size="sm"
              className="rounded-r-md px-3"
              onClick={() => setView("local")}
              disabled={!user?.latitude || !user?.longitude}
            >
              Local (5mi)
            </Button>
          </div>
          {view === "local" && user?.latitude && user?.longitude && (
            <span className="text-xs text-slate-500">
              Showing users within 5 miles of your location
            </span>
          )}
        </div>
      </div>
      
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="flex justify-center items-center py-12">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
        ) : leaderboardData && leaderboardData.length > 0 ? (
          <>
            {leaderboardData.slice(0, 100).map((entry: any, index: number) => {
              const isCurrentUser = user && entry.id === user.id;
              return (
                <div 
                  key={index} 
                  className={`p-4 border-b border-slate-100 flex items-center justify-between ${isCurrentUser ? 'bg-slate-50' : ''}`}
                >
                  <div className="flex items-center">
                    <div className={`${index < 3 
                      ? index === 0 
                        ? 'bg-accent text-white' 
                        : index === 1 
                          ? 'bg-secondary text-white' 
                          : 'bg-slate-200 text-secondary'
                      : 'bg-slate-100 text-accent'} w-8 h-8 rounded-full flex items-center justify-center font-bold`}>
                      {index + 1}
                    </div>
                    <div className="ml-3">
                      <div className="font-medium">
                        {isCurrentUser ? 'You' : entry.username}
                      </div>
                      <div className="text-xs text-slate-600">{entry.overallScore}% Overall Score</div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-medium text-gray-900">
                      {entry.pushups || '-'} / {entry.pullups || '-'} / {entry.situps || '-'} / {formatRunTime(entry.runTimeSeconds)}
                    </div>
                    <div className="text-xs text-slate-600">Push / Pull / Sit / Run</div>
                  </div>
                </div>
              );
            })}
          </>
        ) : (
          <div className="p-6 text-center">
            <p className="text-slate-500">
              {view === "local" && (!user?.latitude || !user?.longitude) 
                ? "Enable location services to see the local leaderboard" 
                : "No data available"}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
