import { useMemo } from "react";
import { UserExercise } from "@shared/schema";
import { getScoreRating } from "@/lib/exercise-grading";

interface PerformanceCardProps {
  latestExercises: Record<string, UserExercise> | undefined;
}

export default function PerformanceCard({ latestExercises }: PerformanceCardProps) {
  // Calculate overall performance score
  const { overallScore, rating } = useMemo(() => {
    if (!latestExercises) {
      return { overallScore: 0, rating: "Incomplete" };
    }
    
    let totalScore = 0;
    let exerciseCount = 0;
    
    // Add scores from each exercise type
    Object.entries(latestExercises).forEach(([type, exercise]) => {
      if (exercise) {
        // For run, convert time to a score (lower time = higher score)
        if (type === "run" && exercise.timeInSeconds) {
          // Calculate a score between 0-100 based on run time
          // Assuming 12 mins (720s) is excellent (100) and 20 mins (1200s) is poor (0)
          const runScore = Math.max(0, 100 - ((exercise.timeInSeconds - 720) / 4.8));
          totalScore += runScore;
        } else {
          // For other exercises, use form score
          totalScore += exercise.formScore || 0;
        }
        exerciseCount++;
      }
    });
    
    // Calculate average
    const finalScore = exerciseCount > 0 ? Math.round(totalScore / exerciseCount) : 0;
    
    // Determine rating
    let rating = "Incomplete";
    if (finalScore >= 90) rating = "Excellent";
    else if (finalScore >= 80) rating = "Good";
    else if (finalScore >= 70) rating = "Satisfactory";
    else if (finalScore >= 60) rating = "Needs Improvement";
    else if (exerciseCount > 0) rating = "Poor";
    
    return { overallScore: finalScore, rating };
  }, [latestExercises]);
  
  // Format run time
  const formatRunTime = (seconds: number | undefined): string => {
    if (!seconds) return "-";
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
            <p className="text-slate-500 text-sm">Overall Fitness Score</p>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-4 w-full md:w-auto md:flex md:space-x-8">
          <div className="text-center">
            <div className="text-2xl font-bold text-accent">
              {latestExercises?.pushup?.repetitions || "-"}
            </div>
            <div className="text-xs text-slate-500">Push-ups</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-accent">
              {latestExercises?.pullup?.repetitions || "-"}
            </div>
            <div className="text-xs text-slate-500">Pull-ups</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-accent">
              {latestExercises?.situp?.repetitions || "-"}
            </div>
            <div className="text-xs text-slate-500">Sit-ups</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-accent">
              {formatRunTime(latestExercises?.run?.timeInSeconds)}
            </div>
            <div className="text-xs text-slate-500">2-mile Run</div>
          </div>
        </div>
      </div>
    </div>
  );
}
