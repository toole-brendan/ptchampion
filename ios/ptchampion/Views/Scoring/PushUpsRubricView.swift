import SwiftUI
import PTDesignSystem

struct PushUpsRubricView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedGender = "Male"
    @State private var selectedAgeGroup = "21-25"
    
    private let genders = ["Male", "Female"]
    private let ageGroups = ["17-20", "21-25", "26-30", "31-35", "36-40", "41-45", "46-50", "51+"]
    
    // USMC PFT Push-ups scoring note
    private let scoringNote = """
    USMC PFT Push-up Scoring
    • Alternative to pull-ups (max 70 points)
    • Cannot achieve max PFT score with push-ups
    • 2-minute time limit
    • Scores vary by age and gender
    """

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Text("USMC PUSH-UP SCORING")
                    .militaryMonospaced(size: 18)
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.95))
                
                // Scoring note
                Text(scoringNote)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // Selection controls
                VStack(spacing: 12) {
                    // Gender picker
                    Picker("Gender", selection: $selectedGender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Age group picker
                    Picker("Age Group", selection: $selectedAgeGroup) {
                        ForEach(ageGroups, id: \.self) { age in
                            Text(age).tag(age)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Scrollable scoring table
                ScrollView {
                    VStack(spacing: 0) {
                        // Table header
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
                        
                        // Data rows
                        ForEach(getScoringData(), id: \.reps) { item in
                            HStack(spacing: 0) {
                                Text("\(item.reps)")
                                    .militaryMonospaced(size: 16)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                    .frame(width: 120, height: 40)
                                    .background(item.reps % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                                    .border(Color.gray.opacity(0.3), width: 1)
                                
                                Text("\(item.points)")
                                    .militaryMonospaced(size: 16)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                    .frame(width: 120, height: 40)
                                    .background(item.reps % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                                    .border(Color.gray.opacity(0.3), width: 1)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Get scoring data based on selection
    private func getScoringData() -> [(reps: Int, points: Int)] {
        var scoringData: [(reps: Int, points: Int)] = []
        
        // Get age index based on selected age group
        let ageIndex = ageGroups.firstIndex(of: selectedAgeGroup) ?? 1
        
        // Get gender for scoring lookup
        let gender = selectedGender.lowercased()
        
        // Get scores for different rep counts
        for reps in stride(from: 87, through: 10, by: -1) {
            let score = USMCPFTScoring.scorePushups(
                reps: reps,
                age: getAgeFromGroup(selectedAgeGroup),
                gender: gender
            )
            if score > 0 {
                scoringData.append((reps: reps, points: score))
            }
        }
        
        return scoringData
    }
    
    // Helper to get a representative age from age group
    private func getAgeFromGroup(_ group: String) -> Int {
        switch group {
        case "17-20": return 19
        case "21-25": return 23
        case "26-30": return 28
        case "31-35": return 33
        case "36-40": return 38
        case "41-45": return 43
        case "46-50": return 48
        case "51+": return 55
        default: return 25
        }
    }
} 