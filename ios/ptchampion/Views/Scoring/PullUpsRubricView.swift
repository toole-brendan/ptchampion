import SwiftUI
import PTDesignSystem

struct PullUpsRubricView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Comprehensive scoring rubric: reps -> points (25 reps = 100 pts → 0 reps = 0 pts)
    private let scoring: [Int: Int] = [
        25: 100,
        24:  96,
        23:  92,
        22:  88,
        21:  84,
        20:  80,
        19:  76,
        18:  72,
        17:  68,
        16:  64,
        15:  60,
        14:  56,
        13:  52,
        12:  48,
        11:  44,
        10:  40,
         9:  36,
         8:  32,
         7:  28,
         6:  24,
         5:  20,
         4:  16,
         3:  12,
         2:   8,
         1:   4,
         0:   0
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
                    Text("PULL-UP SCORE TABLE")
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