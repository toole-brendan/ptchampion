import Foundation

class ExerciseGrader {
    
    /**
     * Calculates pushup grade based on reps
     * - 100 points = 60 reps
     * - 50 points = 30 reps
     * @param reps Number of pushups completed
     * @returns Score from 0-100
     */
    static func calculatePushupGrade(reps: Int) -> Int {
        if reps >= 60 {
            return 100
        } else if reps <= 0 {
            return 0
        } else {
            // Linear scale between 0 and 60 reps
            return Int(Double(reps) / 60.0 * 100.0)
        }
    }
    
    /**
     * Calculates situp grade based on reps
     * - 100 points = 78 reps
     * - 50 points = 47 reps
     * @param reps Number of situps completed
     * @returns Score from 0-100
     */
    static func calculateSitupGrade(reps: Int) -> Int {
        if reps >= 78 {
            return 100
        } else if reps <= 15 {
            return 0
        } else {
            // Linear scale between 15 and 78 reps
            return Int(Double(reps - 15) / 63.0 * 100.0)
        }
    }
    
    /**
     * Calculates pullup grade based on reps
     * - 100 points = 20 reps
     * - 50 points = 8 reps
     * @param reps Number of pullups completed
     * @returns Score from 0-100
     */
    static func calculatePullupGrade(reps: Int) -> Int {
        if reps >= 20 {
            return 100
        } else if reps <= 0 {
            return 0
        } else {
            // Linear scale between 0 and 20 reps
            return Int(Double(reps) / 20.0 * 100.0)
        }
    }
    
    /**
     * Calculates 2-mile run grade based on time in seconds
     * - 100 points = 13:00 (780 seconds) or less
     * - 50 points = 16:36 (996 seconds)
     * @param timeInSeconds Time in seconds to complete 2-mile run
     * @returns Score from 0-100
     */
    static func calculateRunGrade(timeInSeconds: Int) -> Int {
        let maxScore = 780 // 13:00 in seconds
        let minScore = 1260 // 21:00 in seconds
        
        if timeInSeconds <= maxScore {
            return 100
        } else if timeInSeconds >= minScore {
            return 0
        } else {
            // Linear scale between 13:00 and 21:00
            // Score decreases as time increases
            let range = minScore - maxScore
            let overMaxTime = timeInSeconds - maxScore
            return max(0, Int(100.0 - (Double(overMaxTime) / Double(range) * 100.0)))
        }
    }
    
    /**
     * Gets a textual rating based on a numeric score
     * @param score Numeric score 0-100
     * @returns Text rating
     */
    static func getScoreRating(score: Int) -> String {
        switch score {
        case 90...100:
            return "Excellent"
        case 75..<90:
            return "Good"
        case 60..<75:
            return "Satisfactory"
        case 40..<60:
            return "Marginal"
        default:
            return "Poor"
        }
    }
    
    /**
     * Calculates overall fitness score from individual exercise scores
     * @param scores Object containing individual exercise scores
     * @returns Overall score 0-100
     */
    static func calculateOverallScore(pushups: Int?, situps: Int?, pullups: Int?, runTime: Int?) -> Int {
        var totalScore = 0
        var count = 0
        
        // Calculate score for each exercise if available
        if let pushupReps = pushups {
            totalScore += calculatePushupGrade(reps: pushupReps)
            count += 1
        }
        
        if let situpReps = situps {
            totalScore += calculateSitupGrade(reps: situpReps)
            count += 1
        }
        
        if let pullupReps = pullups {
            totalScore += calculatePullupGrade(reps: pullupReps)
            count += 1
        }
        
        if let runTimeSeconds = runTime {
            totalScore += calculateRunGrade(timeInSeconds: runTimeSeconds)
            count += 1
        }
        
        // Return average score or 0 if no exercises completed
        return count > 0 ? totalScore / count : 0
    }
    
    /**
     * Calculates overall fitness score from a dictionary of UserExercise objects
     * @param latestExercises Dictionary of latest user exercises by type
     * @returns Overall score 0-100
     */
    static func calculateOverallScore(latestExercises: [String: UserExercise]) -> Int {
        guard !latestExercises.isEmpty else { return 0 }
        
        var totalScore = 0
        var count = 0
        
        for (_, exercise) in latestExercises {
            if let grade = exercise.grade {
                totalScore += grade
                count += 1
            }
        }
        
        return count > 0 ? totalScore / count : 0
    }
}