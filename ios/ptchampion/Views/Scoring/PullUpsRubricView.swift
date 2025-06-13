import SwiftUI
import PTDesignSystem

struct PullUpsRubricView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAge = "21-25"
    @State private var selectedGender = 0 // 0 = Male, 1 = Female
    
    // Age brackets for USMC PFT
    private let ageBrackets = ["17-20", "21-25", "26-30", "31-35", "36-40", "41-45", "46-50", "51+"]
    
    // Helper function to convert age bracket to age for scoring
    private func ageFromBracket(_ bracket: String) -> Int {
        switch bracket {
        case "17-20": return 20
        case "21-25": return 25
        case "26-30": return 30
        case "31-35": return 35
        case "36-40": return 40
        case "41-45": return 45
        case "46-50": return 50
        case "51+": return 55
        default: return 25
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Scrollable content area
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer to push content below the header
                        Spacer()
                            .frame(height: 220)
                        
                        // USMC Pull-up Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("USMC PFT Pull-up Scoring")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Text("• Primary upper body exercise (max 100 points)")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Text("• Minimum 3 pull-ups required to pass")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Text("• Dead hang, overhand or underhand grip allowed")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            
                            Text("• Scores vary by age and gender")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        .padding()
                        .padding(.horizontal)
                        
                        // Gender Selector
                        VStack(spacing: 8) {
                            Picker("Gender", selection: $selectedGender) {
                                Text("Male").tag(0)
                                Text("Female").tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal, 40)
                            
                            // Age Bracket Selector
                            HStack {
                                ForEach(ageBrackets, id: \.self) { bracket in
                                    Button(action: {
                                        selectedAge = bracket
                                    }) {
                                        Text(bracket)
                                            .font(.system(size: 14, weight: selectedAge == bracket ? .bold : .regular))
                                            .foregroundColor(selectedAge == bracket ? .white : AppTheme.GeneratedColors.deepOps)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(selectedAge == bracket ? AppTheme.GeneratedColors.brassGold : Color.clear)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(AppTheme.GeneratedColors.brassGold, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 16)
                        
                        // Table Header
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
                        
                        // Show scoring data based on gender and age
                        let age = ageFromBracket(selectedAge)
                        let gender = selectedGender == 0 ? "male" : "female"
                        
                        // Show scores from max down to 0
                        // USMC pull-ups typically max at 23 for males, 12 for females
                        let maxReps = gender == "male" ? 23 : 12
                        
                        ForEach((0...maxReps).reversed(), id: \.self) { reps in
                            let score = USMCPFTScoring.scorePullups(reps: reps, age: age, gender: gender)
                            
                            HStack(spacing: 0) {
                                Text("\(reps)")
                                    .militaryMonospaced(size: 16)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                    .frame(width: 120, height: 40)
                                    .background(reps % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                                    .border(Color.gray.opacity(0.3), width: 1)
                                
                                Text("\(score)")
                                    .militaryMonospaced(size: 16)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                    .frame(width: 120, height: 40)
                                    .background(reps % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                                    .border(Color.gray.opacity(0.3), width: 1)
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Fixed header that stays at the top
                VStack {
                    Text("USMC PULL-UP SCORING")
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