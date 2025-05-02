import SwiftUI

struct WorkoutSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let workoutTypes = ["Push-ups", "Pull-ups", "Sit-ups", "Squats"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(workoutTypes, id: \.self) { workout in
                    Button(action: {
                        // Handle workout selection
                        print("Selected workout: \(workout)")
                    }) {
                        HStack {
                            Text(workout)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Workout")
        }
    }
}

#Preview {
    WorkoutSelectionView()
        .environmentObject(AuthViewModel())
} 