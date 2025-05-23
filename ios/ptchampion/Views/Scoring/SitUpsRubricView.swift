import SwiftUI
import PTDesignSystem

struct SitUpsRubricView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Comprehensive scoring rubric: reps -> points
    private let scoring: [Int: Int] = [
        0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9, 10: 10,
        11: 11, 12: 12, 13: 13, 14: 14, 15: 15, 16: 16, 17: 17, 18: 18, 19: 19, 20: 20,
        21: 21, 22: 22, 23: 23, 24: 24, 25: 25, 26: 26, 27: 27, 28: 28, 29: 29, 30: 30,
        31: 31, 32: 32, 33: 33, 34: 34, 35: 35, 36: 36, 37: 37, 38: 38, 39: 39, 40: 40,
        41: 41, 42: 42, 43: 43, 44: 44, 45: 45, 46: 46, 47: 47, 48: 48, 49: 49, 50: 50,
        51: 52, 52: 58, 53: 60, 54: 62, 55: 64, 56: 66, 57: 68, 58: 70, 59: 72, 60: 74,
        61: 76, 62: 78, 63: 80, 64: 82, 65: 84, 66: 86, 67: 88, 68: 90, 69: 91, 70: 92,
        71: 93, 72: 94, 73: 95, 74: 96, 75: 97, 76: 98, 77: 99, 78: 100
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
                    Text("SIT-UP SCORE TABLE")
                        .militaryMonospaced(size: 16)
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.95))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
} 