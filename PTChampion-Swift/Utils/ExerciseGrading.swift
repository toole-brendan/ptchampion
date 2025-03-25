import Foundation

enum ScoreRating: String {
    case excellent = "Excellent"
    case good = "Good"
    case satisfactory = "Satisfactory"
    case marginal = "Marginal"
    case poor = "Poor"
}

struct ExerciseGrading {
    
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
        }
        
        // Linear scale: 100 points at 60 reps, 50 points at 30 reps
        return Int(min(100, max(0, 50 + (reps - 30) * (50.0 / 30.0))))
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
        }
        
        // Linear scale: 100 points at 78 reps, 50 points at 47 reps
        return Int(min(100, max(0, 50 + (reps - 47) * (50.0 / 31.0))))
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
        }
        
        // Linear scale: 100 points at 20 reps, 50 points at 8 reps
        return Int(min(100, max(0, 50 + (reps - 8) * (50.0 / 12.0))))
    }
    
    /**
     * Calculates 2-mile run grade based on time in seconds
     * - 100 points = 13:00 (780 seconds) or less
     * - 50 points = 16:36 (996 seconds)
     * @param timeInSeconds Time in seconds to complete 2-mile run
     * @returns Score from 0-100
     */
    static func calculateRunGrade(timeInSeconds: Int) -> Int {
        if timeInSeconds <= 780 {
            return 100
        } else if timeInSeconds >= 1320 { // 22 minutes
            return 0
        }
        
        // Linear scale: 100 points at 780 seconds, 50 points at 996 seconds
        return Int(min(100, max(0, 50 + (996 - timeInSeconds) * (50.0 / 216.0))))
    }
    
    /**
     * Gets a textual rating based on a numeric score
     * @param score Numeric score 0-100
     * @returns Text rating
     */
    static func getScoreRating(score: Int) -> ScoreRating {
        switch score {
        case 90...100:
            return .excellent
        case 75..<90:
            return .good
        case 60..<75:
            return .satisfactory
        case 40..<60:
            return .marginal
        default:
            return .poor
        }
    }
    
    /**
     * Calculates overall fitness score from individual exercise scores
     * @param scores Object containing individual exercise scores
     * @returns Overall score 0-100
     */
    static func calculateOverallScore(
        pushupScore: Int?,
        situpScore: Int?,
        pullupScore: Int?,
        runScore: Int?
    ) -> Int {
        var totalScore = 0
        var count = 0
        
        if let score = pushupScore {
            totalScore += score
            count += 1
        }
        
        if let score = situpScore {
            totalScore += score
            count += 1
        }
        
        if let score = pullupScore {
            totalScore += score
            count += 1
        }
        
        if let score = runScore {
            totalScore += score
            count += 1
        }
        
        return count > 0 ? totalScore / count : 0
    }
}