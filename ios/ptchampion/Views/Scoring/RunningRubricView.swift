import SwiftUI
import PTDesignSystem

struct RunningRubricView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Comprehensive scoring rubric: time in seconds -> points
    // 11:00 = 660 s, 19:30 = 1170 s
    private let scoring: [Int: Int] = [
        660: 100, // 11:00
        666:  99, // 11:06
        672:  98, // 11:12
        678:  96, // 11:18
        684:  95, // 11:24
        690:  94, // 11:30
        696:  93, // 11:36
        702:  92, // 11:42
        708:  91, // 11:48
        714:  89, // 11:54
        720:  88, // 12:00
        726:  87, // 12:06
        732:  86, // 12:12
        738:  85, // 12:18
        744:  84, // 12:24
        750:  82, // 12:30
        756:  81, // 12:36
        762:  80, // 12:42
        768:  79, // 12:48
        774:  78, // 12:54
        780:  76, // 13:00
        786:  75, // 13:06
        792:  74, // 13:12
        798:  73, // 13:18
        804:  72, // 13:24
        810:  71, // 13:30
        816:  69, // 13:36
        822:  68, // 13:42
        828:  67, // 13:48
        834:  66, // 13:54
        840:  64, // 14:00
        846:  63, // 14:06
        852:  62, // 14:12
        858:  61, // 14:18
        864:  60, // 14:24
        870:  59, // 14:30
        876:  57, // 14:36
        882:  56, // 14:42
        888:  55, // 14:48
        894:  54, // 14:54
        900:  53, // 15:00
        906:  51, // 15:06
        912:  50, // 15:12
        918:  49, // 15:18
        924:  48, // 15:24
        930:  47, // 15:30
        936:  45, // 15:36
        942:  44, // 15:42
        948:  43, // 15:48
        954:  42, // 15:54
        960:  41, // 16:00
        966:  39, // 16:06
        972:  38, // 16:12
        978:  37, // 16:18
        984:  36, // 16:24
        990:  35, // 16:30
        996:  33, // 16:36
       1002:  32, // 16:42
       1008:  31, // 16:48
       1014:  30, // 16:54
       1020:  29, // 17:00
       1026:  28, // 17:06
       1032:  27, // 17:12
       1038:  26, // 17:18
       1044:  24, // 17:24
       1050:  23, // 17:30
       1056:  22, // 17:36
       1062:  21, // 17:42
       1068:  20, // 17:48
       1074:  19, // 17:54
       1080:  18, // 18:00
       1086:  16, // 18:06
       1092:  15, // 18:12
       1098:  14, // 18:18
       1104:  13, // 18:24
       1110:  12, // 18:30
       1116:  11, // 18:36
       1122:  10, // 18:42
       1128:   9, // 18:48
       1134:   8, // 18:54
       1140:   6, // 19:00
       1146:   5, // 19:06
       1152:   4, // 19:12
       1158:   3, // 19:18
       1164:   2, // 19:24
       1170:   0  // 19:30
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
                            
                            // Data rows - use enumerated to get row index for alternating colors
                            ForEach(Array(zip(Array(scoring.keys.sorted()), 0..<scoring.count)), id: \.0) { secs, index in
                                if let points = scoring[secs] {
                                    let minutes = secs / 60
                                    let seconds = secs % 60
                                    
                                    HStack(spacing: 0) {
                                        Text(String(format: "%d:%02d", minutes, seconds))
                                            .militaryMonospaced(size: 16)
                                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                            .frame(width: 120, height: 40)
                                            .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                                            .border(Color.gray.opacity(0.3), width: 1)
                                        
                                        Text("\(points)")
                                            .militaryMonospaced(size: 16)
                                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                            .frame(width: 120, height: 40)
                                            .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
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
                    Text("TWO-MILE RUN SCORE TABLE")
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