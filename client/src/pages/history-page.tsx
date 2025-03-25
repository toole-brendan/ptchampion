import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import Navigation from "@/components/navigation";
import { Loader2 } from "lucide-react";
import { format } from "date-fns";
import { Exercise, UserExercise } from "@shared/schema";

export default function HistoryPage() {
  const { user } = useAuth();
  
  // Get all user exercises
  const { data: userExercises, isLoading } = useQuery({
    queryKey: ["/api/user-exercises"],
    enabled: !!user
  });
  
  // Get all exercises for lookup
  const { data: exercises } = useQuery({
    queryKey: ["/api/exercises"],
    enabled: !!user
  });
  
  // Helper to find exercise name from ID
  const getExerciseName = (exerciseId: number): string => {
    if (!exercises) return "Unknown";
    const exercise = exercises.find(e => e.id === exerciseId);
    return exercise ? exercise.name : "Unknown";
  };
  
  // Helper to get exercise type
  const getExerciseType = (exerciseId: number): string => {
    if (!exercises) return "";
    const exercise = exercises.find(e => e.id === exerciseId);
    return exercise ? exercise.type : "";
  };
  
  // Format exercise result
  const formatResult = (userExercise: UserExercise): string => {
    const type = getExerciseType(userExercise.exerciseId);
    
    if (type === "run") {
      const minutes = Math.floor(userExercise.timeInSeconds! / 60);
      const seconds = userExercise.timeInSeconds! % 60;
      return `${minutes}:${seconds.toString().padStart(2, '0')}`;
    } else {
      return `${userExercise.repetitions} reps`;
    }
  };
  
  // Format date
  const formatDate = (dateString: string): string => {
    return format(new Date(dateString), "MMM d, yyyy h:mm a");
  };
  
  // Group exercises by date
  const groupByDate = (exercises: UserExercise[]) => {
    const grouped: Record<string, UserExercise[]> = {};
    
    exercises.forEach(exercise => {
      const date = format(new Date(exercise.createdAt!), "yyyy-MM-dd");
      if (!grouped[date]) {
        grouped[date] = [];
      }
      grouped[date].push(exercise);
    });
    
    return Object.entries(grouped)
      .sort(([dateA], [dateB]) => new Date(dateB).getTime() - new Date(dateA).getTime())
      .map(([date, exercises]) => ({
        date,
        displayDate: format(new Date(date), "MMMM d, yyyy"),
        exercises
      }));
  };
  
  const groupedExercises = userExercises ? groupByDate(userExercises) : [];

  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      {/* Header */}
      <header className="bg-white border-b border-slate-200">
        <div className="container px-4 py-3 mx-auto">
          <h1 className="text-xl font-bold text-primary">Exercise History</h1>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        <section className="py-6 px-4 lg:px-8">
          <div className="container mx-auto max-w-5xl">
            {isLoading ? (
              <div className="flex justify-center py-12">
                <Loader2 className="h-8 w-8 animate-spin text-accent" />
              </div>
            ) : userExercises?.length === 0 ? (
              <div className="bg-white rounded-xl shadow-sm p-8 text-center">
                <h3 className="text-lg font-semibold mb-2">No Exercise History</h3>
                <p className="text-slate-500">Complete some exercises to see your history</p>
              </div>
            ) : (
              <div className="space-y-6">
                {groupedExercises.map(group => (
                  <div key={group.date}>
                    <h3 className="text-lg font-semibold mb-3">{group.displayDate}</h3>
                    <div className="bg-white rounded-xl shadow-sm overflow-hidden">
                      {group.exercises.map(exercise => (
                        <div key={exercise.id} className="p-4 border-b border-slate-100 flex items-center justify-between">
                          <div className="flex items-center">
                            <div className={`w-10 h-10 rounded-full bg-accent/10 text-accent flex items-center justify-center mr-3`}>
                              {getExerciseType(exercise.exerciseId) === "pushup" && "P"}
                              {getExerciseType(exercise.exerciseId) === "pullup" && "PU"}
                              {getExerciseType(exercise.exerciseId) === "situp" && "S"}
                              {getExerciseType(exercise.exerciseId) === "run" && "R"}
                            </div>
                            <div>
                              <div className="font-medium">{getExerciseName(exercise.exerciseId)}</div>
                              <div className="text-xs text-slate-500">{formatDate(exercise.createdAt!)}</div>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="text-sm font-medium">{formatResult(exercise)}</div>
                            <div className="text-xs text-slate-500">
                              {exercise.formScore ? `Form: ${exercise.formScore}%` : ''}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </section>
      </main>

      {/* Bottom Navigation */}
      <Navigation active="history" />
    </div>
  );
}
