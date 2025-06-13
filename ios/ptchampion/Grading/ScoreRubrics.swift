// ios/ptchampion/Grading/ScoreRubrics.swift

import Foundation

/// This file previously contained APFT scoring tables.
/// All scoring has been migrated to USMCScoring.swift for Marine Corps PFT standards.
/// 
/// Use USMCPFTScoring methods instead:
/// - USMCPFTScoring.scorePushups(reps:age:gender:)
/// - USMCPFTScoring.scorePullups(reps:age:gender:)
/// - USMCPFTScoring.scorePlank(seconds:)
/// - USMCPFTScoring.scoreRun(seconds:age:gender:)

enum ScoreRubrics {
    // All scoring logic has been moved to USMCScoring.swift
    // This enum is kept for backward compatibility but should not be used for new code
    
    /// Legacy scoring function - DEPRECATED
    /// Use USMCPFTScoring methods instead
    @available(*, deprecated, message: "Use USMCPFTScoring methods instead")
    static func score(for type: ExerciseType, reps: Int? = nil, time: Int? = nil) -> Int {
        // This is a compatibility shim - it returns approximate scores
        // For accurate USMC PFT scoring, use USMCPFTScoring directly
        
        // Default to age 25 and male for legacy compatibility
        let defaultAge = 25
        let defaultGender = "male"
        
        switch type {
        case .pushup:
            return USMCPFTScoring.scorePushups(reps: reps ?? 0, age: defaultAge, gender: defaultGender)
        case .pullup:
            return USMCPFTScoring.scorePullups(reps: reps ?? 0, age: defaultAge, gender: defaultGender)
        case .plank:
            // If time is provided, use it for plank scoring
            return USMCPFTScoring.scorePlank(seconds: time ?? 0)
        case .run:
            return USMCPFTScoring.scoreRun(seconds: time ?? 0, age: defaultAge, gender: defaultGender)
        case .situp:
            // Sit-ups are deprecated, return 0
            return 0
        default:
            return 0
        }
    }
} 