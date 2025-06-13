import SwiftUI
import PTDesignSystem

struct RunningRubricView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedGender = "Male"
    @State private var selectedAgeGroup = "21-25"
    
    private let genders = ["Male", "Female"]
    private let ageGroups = ["17-20", "21-25", "26-30", "31-35", "36-40", "41-45", "46-50", "51+"]
    
    // USMC PFT 3-Mile Run scoring note
    private let scoringNote = """
    USMC PFT 3-Mile Run Scoring
    • Maximum score: 100 points
    • Distance: 3 miles (4.8 km)
    • Minimum passing time varies by age/gender
    • Scores vary by age and gender
    """
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Text("USMC 3-MILE RUN SCORING")
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
                            Text("TIME")
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
                        ForEach(getScoringData().indices, id: \.self) { index in
                            let item = getScoringData()[index]
                            let minutes = item.seconds / 60
                            let secs = item.seconds % 60
                            
                            HStack(spacing: 0) {
                                Text(String(format: "%d:%02d", minutes, secs))
                                    .militaryMonospaced(size: 16)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                    .frame(width: 120, height: 40)
                                    .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                                    .border(Color.gray.opacity(0.3), width: 1)
                                
                                Text("\(item.score)")
                                    .militaryMonospaced(size: 16)
                                    .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                    .frame(width: 120, height: 40)
                                    .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
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
    private func getScoringData() -> [(seconds: Int, score: Int)] {
        let gender = selectedGender.lowercased()
        let age = getAgeFromGroup(selectedAgeGroup)
        
        // Generate time increments from fastest to slowest (every 6 seconds)
        // USMC 3-mile run typically ranges from 18:00 (1080s) to 33:00 (1980s)
        var times: [(seconds: Int, score: Int)] = []
        let minTime = 1080 // 18:00
        let maxTime = 1980 // 33:00
        
        var currentTime = minTime
        while currentTime <= maxTime {
            let score = USMCPFTScoring.scoreRun(seconds: currentTime, age: age, gender: gender)
            if score > 0 {
                times.append((seconds: currentTime, score: score))
            }
            currentTime += 6 // Show every 6 seconds
        }
        return times
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