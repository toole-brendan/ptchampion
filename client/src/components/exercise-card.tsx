import { Link } from "wouter";
import { ChevronRight } from "lucide-react";
import { Exercise, UserExercise } from "@shared/schema";
import { getScoreRating } from "@/lib/exercise-grading";

interface ExerciseCardProps {
  exercise: Exercise;
  latestScore: UserExercise | null;
}

export default function ExerciseCard({ exercise, latestScore }: ExerciseCardProps) {
  // Helper function to get the exercise image
  const getExerciseImage = (type: string): string => {
    switch (type) {
      case "pushup":
        return "https://images.unsplash.com/photo-1616803689943-5601631c7fec?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80";
      case "pullup":
        return "https://images.unsplash.com/photo-1598971639058-fab3c3109a00?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80";
      case "situp":
        return "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80";
      case "run":
        return "https://images.unsplash.com/photo-1571008887538-b36bb32f4571?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80";
      default:
        return "https://images.unsplash.com/photo-1517344884509-a0c97ec11bcc?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80";
    }
  };
  
  // Format the score display
  const formatScore = (type: string, latestScore: UserExercise | null): string => {
    if (!latestScore) return "No data";
    
    if (type === "run" && latestScore.timeInSeconds) {
      const minutes = Math.floor(latestScore.timeInSeconds / 60);
      const seconds = latestScore.timeInSeconds % 60;
      return `${minutes}:${seconds.toString().padStart(2, '0')}`;
    }
    
    return `${latestScore.repetitions} reps`;
  };
  
  // Determine badge color based on grade if available
  const getBadgeClass = (type: string, latestScore: UserExercise | null): string => {
    if (!latestScore) return "badge badge-error";
    
    // Use grade if available
    if (latestScore.grade !== undefined && latestScore.grade !== null) {
      if (latestScore.grade >= 80) return "badge badge-success";
      if (latestScore.grade >= 60) return "badge badge-warning";
      return "badge badge-error";
    }
    
    // Fallback to old logic if grade isn't available
    if (type === "run") {
      const timeInSeconds = latestScore.timeInSeconds || 0;
      if (timeInSeconds < 780) return "badge badge-success"; // Under 13 minutes
      if (timeInSeconds < 900) return "badge badge-warning"; // Under 15 minutes
      return "badge badge-error";
    }
    
    // For other exercises, base it on form score
    const formScore = latestScore.formScore || 0;
    if (formScore >= 80) return "badge badge-success";
    if (formScore >= 60) return "badge badge-warning";
    return "badge badge-error";
  };
  
  // Get the appropriate route for the exercise
  const getExerciseRoute = (type: string): string => {
    switch (type) {
      case "pushup":
        return "/exercises/pushup";
      case "pullup":
        return "/exercises/pullup";
      case "situp":
        return "/exercises/situp";
      case "run":
        return "/run";
      default:
        return `/exercise/${type}`;
    }
  };

  return (
    <Link href={getExerciseRoute(exercise.type)} className="bg-white rounded-xl shadow-sm overflow-hidden cursor-pointer transition hover:shadow-md block">
      <div className="aspect-video bg-slate-100 relative">
        <img 
          src={getExerciseImage(exercise.type)} 
          alt={`${exercise.name} exercise`} 
          className="w-full h-full object-cover"
        />
        <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/60 to-transparent p-3">
          <div className="text-white font-semibold">{exercise.name}</div>
        </div>
      </div>
      <div className="p-3">
        <div className="flex justify-between items-center">
          <div className="text-sm text-slate-500">Last Score</div>
          <div className={getBadgeClass(exercise.type, latestScore)}>
            {latestScore ? formatScore(exercise.type, latestScore) : "No data"}
          </div>
        </div>
        <div className="mt-2 flex items-center justify-between">
          <div className="text-xs">
            {latestScore 
              ? (
                <div className="space-y-1">
                  {latestScore.grade !== undefined && latestScore.grade !== null && (
                    <div className="text-blue-600 font-medium">
                      Grade: {latestScore.grade} pts ({getScoreRating(latestScore.grade)})
                    </div>
                  )}
                  <div className="text-slate-400">
                    Form Score: {latestScore.formScore || 0}%
                  </div>
                </div>
              ) 
              : exercise.type === "run" 
                ? <div className="text-slate-400">Needs smartwatch</div>
                : <div className="text-slate-400">Not attempted yet</div>
            }
          </div>
          <ChevronRight className="h-5 w-5 text-gray-700" />
        </div>
      </div>
    </Link>
  );
}
