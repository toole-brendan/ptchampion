import { useMemo } from "react";
import { UserExercise } from "@shared/schema";
import { getScoreRating } from "@/lib/exercise-grading";

interface PerformanceCardProps {
  latestExercises: Record<string, UserExercise> | undefined;
}

export default function PerformanceCard({ latestExercises }: PerformanceCardProps) {
  // Calculate overall performance score using the grade field
  const { overallScore, rating } = useMemo(() => {
    if (!latestExercises) {
      return { overallScore: 0, rating: "Incomplete" };
    }
    
    let totalScore = 0;
    let exerciseCount = 0;
    
    // Add scores from each exercise type
    Object.entries(latestExercises).forEach(([type, exercise]) => {
      if (exercise) {
        // Use the grade field from each exercise
        if (exercise.grade !== undefined && exercise.grade !== null) {
          totalScore += exercise.grade;
          exerciseCount++;
        }
        // Fallback to old calculation if grade is not available
        else if (type === "run" && exercise.timeInSeconds) {
          const runScore = Math.max(0, 100 - ((exercise.timeInSeconds - 720) / 4.8));
          totalScore += runScore;
          exerciseCount++;
        } else if (exercise.formScore) {
          totalScore += exercise.formScore;
          exerciseCount++;
        }
      }
    });
    
    // Calculate average
    const finalScore = exerciseCount > 0 ? Math.round(totalScore / exerciseCount) : 0;
    
    // Get rating from the exercise-grading utility
    const rating = exerciseCount > 0 ? getScoreRating(finalScore) : "Incomplete";
    
    return { overallScore: finalScore, rating };
  }, [latestExercises]);
  
  // Format run time
  const formatRunTime = (seconds: number | null | undefined): string => {
    if (seconds === undefined || seconds === null) return "-";
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };
  
  // Calculate progress ring stroke-dashoffset
  const calculateRingOffset = (score: number): number => {
    const circumference = 2 * Math.PI * 44; // 2πr where r = 44
    return circumference - (score / 100) * circumference;
  };

  return (
    <div className="bg-white rounded-xl shadow-sm p-4 mb-6">
      <h3 className="text-lg font-semibold mb-3">Your Performance</h3>
      <div className="flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center">
          <div className="relative w-24 h-24">
            <svg className="w-24 h-24 progress-ring">
              <circle
                cx="48"
                cy="48"
                r="44"
                stroke="#E2E8F0"
                strokeWidth="8"
                fill="transparent"
              />
              <circle
                cx="48"
                cy="48"
                r="44"
                stroke="#3B82F6"
                strokeWidth="8"
                strokeDasharray="276.46"
                strokeDashoffset={calculateRingOffset(overallScore)}
                fill="transparent"
              />
            </svg>
            <div className="absolute inset-0 flex items-center justify-center">
              <span className="text-2xl font-bold text-primary">{overallScore}%</span>
            </div>
          </div>
          <div className="ml-4">
            <h4 className="text-xl font-bold">{rating}</h4>
            <p className="text-slate-600 text-sm">Overall Fitness Score</p>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-4 w-full md:w-auto md:flex md:space-x-8">
          <div className="text-center">
            <div className="text-2xl font-bold text-primary">
              {latestExercises?.pushup?.repetitions || "-"}
            </div>
            <div className="text-xs text-slate-600">Push-ups</div>
            {latestExercises?.pushup?.grade !== undefined && (
              <div className="text-xs font-medium mt-1 px-2 py-1 rounded-full bg-slate-100 text-gray-700">
                {latestExercises.pushup.grade} pts
              </div>
            )}
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-primary">
              {latestExercises?.pullup?.repetitions || "-"}
            </div>
            <div className="text-xs text-slate-600">Pull-ups</div>
            {latestExercises?.pullup?.grade !== undefined && (
              <div className="text-xs font-medium mt-1 px-2 py-1 rounded-full bg-slate-100 text-gray-700">
                {latestExercises.pullup.grade} pts
              </div>
            )}
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-primary">
              {latestExercises?.situp?.repetitions || "-"}
            </div>
            <div className="text-xs text-slate-600">Sit-ups</div>
            {latestExercises?.situp?.grade !== undefined && (
              <div className="text-xs font-medium mt-1 px-2 py-1 rounded-full bg-slate-100 text-gray-700">
                {latestExercises.situp.grade} pts
              </div>
            )}
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-primary">
              {formatRunTime(latestExercises?.run?.timeInSeconds)}
            </div>
            <div className="text-xs text-slate-600">2-mile Run</div>
            {latestExercises?.run?.grade !== undefined && (
              <div className="text-xs font-medium mt-1 px-2 py-1 rounded-full bg-slate-100 text-gray-700">
                {latestExercises.run.grade} pts
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
