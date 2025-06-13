//
//  USMCScoring.swift
//  ptchampion
//
//  USMC PFT Scoring System
//  Based on Marine Corps Order 6100.13A (Change 4, 2022)
//

import Foundation

// MARK: - JSON Decodable Structs

struct GenderScoring: Decodable {
    let age_brackets: [String]
    let scores: [String: [Int?]]
}

struct USMCPFTTable: Decodable {
    let exercise: String
    let scoring_system: String
    let version: String
    let source: String
    let description: String
    let implementation_notes: [String]?
    let male: GenderScoring
    let female: GenderScoring
}

// Plank has a universal table instead of gender split
struct UniversalPlank: Decodable {
    let max_time_seconds: Int
    let min_time_seconds: Int
    let max_time_formatted: String
    let min_time_formatted: String
    let max_points: Int
    let min_points: Int
    let scoring_table: [String: Int]
}

struct PlankScoring: Decodable {
    let exercise: String
    let scoring_system: String
    let version: String
    let source: String
    let description: String
    let universal: UniversalPlank
}

// MARK: - USMC PFT Scoring Class

class USMCPFTScoring {
    
    // Singleton instance
    static let shared = USMCPFTScoring()
    
    // Loaded tables
    private let pushupTable: USMCPFTTable
    private let pullupTable: USMCPFTTable
    private let runTable: USMCPFTTable
    private let plankTable: PlankScoring
    
    private init() {
        // Load all JSON files from bundle
        self.pushupTable = Self.loadJSON("usmc_pushup_scoring")
        self.pullupTable = Self.loadJSON("usmc_pullup_scoring")
        self.runTable = Self.loadJSON("usmc_3mile_run_scoring")
        self.plankTable = Self.loadJSON("usmc_plank_scoring")
    }
    
    // Helper to load JSON from bundle
    private static func loadJSON<T: Decodable>(_ name: String) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            fatalError("Failed to locate \(name).json in bundle.")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(name).json from bundle.")
        }
        
        let decoder = JSONDecoder()
        guard let decodedData = try? decoder.decode(T.self, from: data) else {
            fatalError("Failed to decode \(name).json.")
        }
        
        return decodedData
    }
    
    // MARK: - Scoring Methods
    
    /// Calculate score for push-ups (max 70 points)
    static func scorePushups(reps: Int, age: Int, gender: String) -> Int {
        return shared.scoreStrengthExercise(
            reps: reps,
            age: age,
            gender: gender,
            table: shared.pushupTable
        )
    }
    
    /// Calculate score for pull-ups (max 100 points)
    static func scorePullups(reps: Int, age: Int, gender: String) -> Int {
        return shared.scoreStrengthExercise(
            reps: reps,
            age: age,
            gender: gender,
            table: shared.pullupTable
        )
    }
    
    /// Calculate score for 3-mile run
    static func scoreRun(seconds: Int, age: Int, gender: String) -> Int {
        // Convert seconds to MM:SS format
        let minutes = seconds / 60
        let secs = seconds % 60
        let timeKey = String(format: "%d:%02d", minutes, secs)
        
        return shared.scoreTimeBasedExercise(
            timeKey: timeKey,
            age: age,
            gender: gender,
            table: shared.runTable
        )
    }
    
    /// Calculate score for plank (universal table, no gender/age)
    static func scorePlank(seconds: Int) -> Int {
        let table = shared.plankTable.universal.scoring_table
        
        // Find the highest time key that is <= the given seconds
        let sortedKeys = table.keys.compactMap { Int($0) }.sorted(by: >)
        
        for key in sortedKeys {
            if seconds >= key {
                return table[String(key)] ?? 0
            }
        }
        
        // If no matching key found, return minimum score
        return shared.plankTable.universal.min_points
    }
    
    // MARK: - Private Helper Methods
    
    private func scoreStrengthExercise(reps: Int, age: Int, gender: String, table: USMCPFTTable) -> Int {
        // Find age bracket index
        let ageBracketIndex = findAgeBracketIndex(age: age, brackets: table.male.age_brackets)
        
        // Get the appropriate gender table
        let genderTable = (gender.lowercased() == "male") ? table.male : table.female
        
        // Look up score by reps (as string key)
        let repKey = String(reps)
        guard let scores = genderTable.scores[repKey],
              ageBracketIndex < scores.count else {
            return 0
        }
        
        return scores[ageBracketIndex] ?? 0
    }
    
    private func scoreTimeBasedExercise(timeKey: String, age: Int, gender: String, table: USMCPFTTable) -> Int {
        // Find age bracket index
        let ageBracketIndex = findAgeBracketIndex(age: age, brackets: table.male.age_brackets)
        
        // Get the appropriate gender table
        let genderTable = (gender.lowercased() == "male") ? table.male : table.female
        
        // Look up score by time key
        guard let scores = genderTable.scores[timeKey],
              ageBracketIndex < scores.count else {
            return 0
        }
        
        return scores[ageBracketIndex] ?? 0
    }
    
    private func findAgeBracketIndex(age: Int, brackets: [String]) -> Int {
        for (index, bracket) in brackets.enumerated() {
            if bracket.contains("+") {
                // Handle "51+" case
                if let minAge = Int(bracket.dropLast()) {
                    if age >= minAge {
                        return index
                    }
                }
            } else {
                // Handle "17-20" style ranges
                let parts = bracket.split(separator: "-").compactMap { Int($0) }
                if parts.count == 2 && age >= parts[0] && age <= parts[1] {
                    return index
                }
            }
        }
        
        // Default to first bracket if no match found
        return 0
    }
    
    // MARK: - Utility Methods
    
    /// Get the maximum possible score for an exercise
    static func getMaxScore(for exercise: ExerciseType) -> Int {
        switch exercise {
        case .pushup:
            return 70  // Push-ups max out at 70 points
        case .pullup:
            return 100
        case .plank:
            return 100
        case .run:
            return 100
        default:
            return 0
        }
    }
    
    /// Get the minimum passing score for an exercise
    static func getMinScore(for exercise: ExerciseType) -> Int {
        switch exercise {
        case .pushup, .pullup, .run:
            return 40
        case .plank:
            return 40  // Updated from 70 to 40 based on actual USMC standards
        default:
            return 0
        }
    }
    
    /// Check if a score is passing for a given exercise
    static func isPassing(score: Int, for exercise: ExerciseType) -> Bool {
        return score >= getMinScore(for: exercise)
    }
    
    /// Calculate total PFT score from individual event scores
    static func calculateTotalScore(pushups: Int? = nil, pullups: Int? = nil, plank: Int, run: Int) -> Int {
        // Note: Marines must choose either push-ups OR pull-ups, not both
        let upperBodyScore = pullups ?? pushups ?? 0
        return upperBodyScore + plank + run
    }
    
    /// Check if total score qualifies for a specific class
    static func getPerformanceClass(totalScore: Int) -> String {
        switch totalScore {
        case 285...300:
            return "1st Class"
        case 245..<285:
            return "2nd Class"
        case 200..<245:
            return "3rd Class"
        default:
            return "Fail"
        }
    }
} 