// ios/ptchampion/Grading/ScoreRubrics.swift

import Foundation

/// Scoring rubrics for each exercise type based on the APFT (17-21 Male) standards
enum ScoreRubrics {
    // MARK: - Push-ups Scoring
    static let pushup: [Int: Int] = [
        68:100, 67:99, 66:97, 65:96, 64:94, 63:93, 62:91, 61:90,
        60:88, 59:87, 58:85, 57:84, 56:82, 55:81, 54:79, 53:78,
        52:76, 51:75, 50:74, 49:72, 48:71, 47:69, 46:68, 45:66,
        44:65, 43:63, 42:62, 41:60, 40:59, 39:57, 38:56, 37:54,
        36:53, 35:51, 34:50, 33:48, 32:47, 31:46, 30:44, 29:43,
        28:41, 27:40, 26:38, 25:37, 24:35, 23:34, 22:32, 21:31,
        20:29, 19:28, 18:26, 17:25, 16:24, 15:22, 14:21, 13:19,
        12:18, 11:16, 10:15,  9:13,  8:12,  7:10,  6: 9,  5: 7,
         4: 6,  3: 4,  2: 3,  1: 1,  0: 0
    ]
    
    // MARK: - Sit-ups Scoring
    static let situp: [Int: Int] = [
         0:  0,  1:  1,  2:  2,  3:  3,  4:  4,  5:  5,  6:  6,  7:  7,  8:  8,  9:  9,
        10: 10, 11: 11, 12: 12, 13: 13, 14: 14, 15: 15, 16: 16, 17: 17, 18: 18, 19: 19,
        20: 20, 21: 21, 22: 22, 23: 23, 24: 24, 25: 25, 26: 26, 27: 27, 28: 28, 29: 29,
        30: 30, 31: 31, 32: 32, 33: 33, 34: 34, 35: 35, 36: 36, 37: 37, 38: 38, 39: 39,
        40: 40, 41: 41, 42: 42, 43: 43, 44: 44, 45: 45, 46: 46, 47: 47, 48: 48, 49: 49,
        50: 50, 51: 52, 52: 58, 53: 60, 54: 62, 55: 64, 56: 66, 57: 68, 58: 70, 59: 72,
        60: 74, 61: 76, 62: 78, 63: 80, 64: 82, 65: 84, 66: 86, 67: 88, 68: 90, 69: 91,
        70: 92, 71: 93, 72: 94, 73: 95, 74: 96, 75: 97, 76: 98, 77: 99, 78:100
    ]
    
    // MARK: - Pull-ups Scoring
    static let pullup: [Int: Int] = [
        25:100, 24:96, 23:92, 22:88, 21:84, 20:80, 19:76, 18:72,
        17:68, 16:64, 15:60, 14:56, 13:52, 12:48, 11:44, 10:40,
         9:36,  8:32,  7:28,  6:24,  5:20,  4:16,  3:12,  2: 8,
         1: 4,  0: 0
    ]
    
    // MARK: - 2-Mile Run Scoring (time in seconds)
    static let run: [Int: Int] = [
       660:100,  666: 99,  672: 98,  678: 96,  684: 95,  690: 94,  696: 93,
       702: 92,  708: 91,  714: 89,  720: 88,  726: 87,  732: 86,  738: 85,
       744: 84,  750: 82,  756: 81,  762: 80,  768: 79,  774: 78,  780: 76,
       786: 75,  792: 74,  798: 73,  804: 72,  810: 71,  816: 69,  822: 68,
       828: 67,  834: 66,  840: 64,  846: 63,  852: 62,  858: 61,  864: 60,
       870: 59,  876: 57,  882: 56,  888: 55,  894: 54,  900: 53,  906: 51,
       912: 50,  918: 49,  924: 48,  930: 47,  936: 45,  942: 44,  948: 43,
       954: 42,  960: 41,  966: 39,  972: 38,  978: 37,  984: 36,  990: 35,
       996: 33, 1002: 32, 1008: 31, 1014: 30, 1020: 29, 1026: 28, 1032: 27,
      1038: 26, 1044: 24, 1050: 23, 1056: 22, 1062: 21, 1068: 20, 1074: 19,
      1080: 18, 1086: 16, 1092: 15, 1098: 14, 1104: 13, 1110: 12, 1116: 11,
      1122: 10, 1128:  9, 1134:  8, 1140:  6, 1146:  5, 1152:  4, 1158:  3,
      1164:  2, 1170:  0
    ]
    
    /// Unified scoring function that returns the appropriate score based on exercise type and performance
    /// - Parameters:
    ///   - type: The exercise type (pushup, situp, pullup, run)
    ///   - reps: Number of repetitions (for strength exercises)
    ///   - time: Time in seconds (for run)
    /// - Returns: Score from 0-100
    static func score(for type: ExerciseType, reps: Int? = nil, time: Int? = nil) -> Int {
        switch type {
        case .pushup: return lookup(pushup, reps ?? 0, higherBest: true)
        case .situp:  return lookup(situp,  reps ?? 0, higherBest: true)
        case .pullup: return lookup(pullup, reps ?? 0, higherBest: true)
        case .run:    return lookup(run,    time ?? 0, higherBest: false)
        default:      return 0
        }
    }
    
    /// Helper function to look up a score in a table, handling edge cases
    /// - Parameters:
    ///   - dict: The scoring table to use
    ///   - key: The performance value (reps or time)
    ///   - higherBest: Whether higher values are better (true for reps, false for time)
    /// - Returns: The score from 0-100
    private static func lookup(_ dict: [Int:Int], _ key: Int, higherBest: Bool) -> Int {
        if let v = dict[key] { return v }
        if higherBest {
            return key > (dict.keys.max() ?? 0) ? 100 : 0
        } else {
            return key < (dict.keys.min() ?? 0) ? 100 : 0
        }
    }
} 