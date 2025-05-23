import SwiftUI
import PTDesignSystem

struct PushUpsRubricView: View {
    @Environment(\.dismiss) private var dismiss

    // Comprehensive scoring rubric: reps -> points
    private let scoring: [Int: Int] = [
        68: 100,
        67: 99,
        66: 97,
        65: 96,
        64: 94,
        63: 93,
        62: 91,
        61: 90,
        60: 88,
        59: 87,
        58: 85,
        57: 84,
        56: 82,
        55: 81,
        54: 79,
        53: 78,
        52: 76,
        51: 75,
        50: 74,
        49: 72,
        48: 71,
        47: 69,
        46: 68,
        45: 66,
        44: 65,
        43: 63,
        42: 62,
        41: 60,
        40: 59,
        39: 57,
        38: 56,
        37: 54,
        36: 53,
        35: 51,
        34: 50,
        33: 48,
        32: 47,
        31: 46,
        30: 44,
        29: 43,
        28: 41,
        27: 40,
        26: 38,
        25: 37,
        24: 35,
        23: 34,
        22: 32,
        21: 31,
        20: 29,
        19: 28,
        18: 26,
        17: 25,
        16: 24,
        15: 22,
        14: 21,
        13: 19,
        12: 18,
        11: 16,
        10: 15,
         9: 13,
         8: 12,
         7: 10,
         6:  9,
         5:  7,
         4:  6,
         3:  4,
         2:  3,
         1:  1,
         0:  0
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Scrollable content area
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer to push content below the header
                        Spacer()
                            .frame(height: 60)
                        
                        // Table
                        VStack(spacing: 0) {
                            // Header row
                            HStack(spacing: 0) {
                                Text("REPS")
                                    .militaryMonospaced(size: 16)
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                    .frame(width: 120, height: 44)
                                    .background(Color.gray.opacity(0.1))
                                    .border(Color.gray.opacity(0.3), width: 1)
                                
                                Text("POINTS")
                                    .militaryMonospaced(size: 16)
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                    .frame(width: 120, height: 44)
                                    .background(Color.gray.opacity(0.1))
                                    .border(Color.gray.opacity(0.3), width: 1)
                            }
                            
                            // Data rows - reversed to show highest score first
                            ForEach(Array(scoring.keys.sorted().reversed()), id: \.self) { rep in
                                if let points = scoring[rep] {
                                    HStack(spacing: 0) {
                                        Text("\(rep)")
                                            .militaryMonospaced(size: 16)
                                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                            .frame(width: 120, height: 40)
                                            .background(rep % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                                            .border(Color.gray.opacity(0.3), width: 1)
                                        
                                        Text("\(points)")
                                            .militaryMonospaced(size: 16)
                                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                            .frame(width: 120, height: 40)
                                            .background(rep % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                                            .border(Color.gray.opacity(0.3), width: 1)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Fixed header that stays at the top
                VStack {
                    Text("PUSH-UP SCORE TABLE")
                        .militaryMonospaced(size: 16)
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.95))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Done button to dismiss the modal
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 