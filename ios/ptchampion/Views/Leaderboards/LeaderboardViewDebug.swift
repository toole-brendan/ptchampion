import SwiftUI
import os.log
import Foundation

private let logger = Logger(subsystem: "com.ptchampion", category: "LeaderboardViewDebug")

struct LeaderboardViewDebug: View {
    @State private var isViewActive = false
    @State private var useMockData = true
    @State private var debugMessages: [DebugMessage] = []
    @State private var isShowingLogs = false
    
    // For tracking memory
    @State private var memoryUsage: String = "Unknown"
    @State private var memoryTimer: Timer? = nil
    
    struct DebugMessage: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let isError: Bool
        
        init(_ message: String, isError: Bool = false) {
            self.timestamp = Date()
            self.message = message
            self.isError = isError
        }
    }
    
    func addLog(_ message: String, isError: Bool = false) {
        DispatchQueue.main.async {
            let log = DebugMessage(message, isError: isError)
            debugMessages.append(log)
            print("🔍 \(message)")
            
            // Also log to system
            if isError {
                logger.error("\(message)")
            } else {
                logger.debug("\(message)")
            }
        }
    }
    
    func getMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return String(format: "%.1f MB", Double(info.resident_size) / (1024 * 1024))
        } else {
            return "Error"
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Leaderboard DEBUG MODE")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { isShowingLogs.toggle() }) {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.red)
                
                HStack {
                    Text("Memory: \(memoryUsage)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        useMockData.toggle()
                        addLog("Toggled mock data: \(useMockData)")
                    }) {
                        Text(useMockData ? "Using Mock Data" : "Using Real Data")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(useMockData ? Color.green : Color.blue)
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.8))
                
                // The actual leaderboard view is embedded here - it's lazily loaded
                if isViewActive {
                    LazyView {
                        LeaderboardViewWrapper(
                            addLog: addLog,
                            useMockData: useMockData
                        )
                    }
                } else {
                    Button(action: {
                        addLog("Activating leaderboard view")
                        isViewActive = true
                    }) {
                        Text("Load Leaderboard")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    // Debug log preview
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(debugMessages.suffix(5)) { log in
                                Text("\(log.message)")
                                    .font(.caption)
                                    .foregroundColor(log.isError ? .red : .primary)
                                    .padding(.vertical, 2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                }
            }
            
            // Show logs as modal overlay
            if isShowingLogs {
                DebugLogsView(logs: debugMessages, isShowingLogs: $isShowingLogs)
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(12)
                    .padding(20)
            }
        }
        .onAppear {
            addLog("LeaderboardViewDebug appeared")
            
            // Start memory monitoring
            memoryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                memoryUsage = getMemoryUsage()
            }
        }
        .onDisappear {
            addLog("LeaderboardViewDebug disappeared")
            isViewActive = false
            memoryTimer?.invalidate()
            memoryTimer = nil
        }
    }
}

struct DebugLogsView: View {
    let logs: [LeaderboardViewDebug.DebugMessage]
    @Binding var isShowingLogs: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text("Debug Logs")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isShowingLogs = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(logs.reversed()) { log in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(log.message)
                                .font(.caption)
                                .foregroundColor(log.isError ? .red : .white)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(log.isError ? Color.red.opacity(0.2) : Color.clear)
                        .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
    }
}

struct LeaderboardViewWrapper: View {
    let addLog: (String, Bool) -> Void
    let useMockData: Bool
    
    @StateObject private var viewModel: LeaderboardViewModel
    
    // Initialize with functions rather than variables for proper initialization
    init(addLog: @escaping (String, Bool) -> Void, useMockData: Bool) {
        self.addLog = addLog
        self.useMockData = useMockData
        
        // Create the view model
        let vm = LeaderboardViewModel(useMockData: useMockData, autoLoadData: false)
        self._viewModel = StateObject(wrappedValue: vm)
        
        addLog("LeaderboardViewWrapper init with mockData: \(useMockData)")
    }
    
    var body: some View {
        VStack {
            // Header with metrics
            HStack {
                VStack(alignment: .leading) {
                    Text("Status: \(viewModel.isLoading ? "Loading" : "Ready")")
                    Text("Entries: \(viewModel.leaderboardEntries.count)")
                    if let error = viewModel.errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    }
                }
                .font(.caption)
                
                Spacer()
                
                Button(action: {
                    addLog("Manual refresh triggered")
                    viewModel.refreshData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            
            // The actual leaderboard content
            LeaderboardContent(viewModel: viewModel, addLog: addLog)
        }
        .onAppear {
            addLog("LeaderboardViewWrapper appeared")
            
            // Use the async approach with a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                addLog("Starting data load after delay")
                viewModel.refreshData()
            }
        }
        .onDisappear {
            addLog("LeaderboardViewWrapper disappeared")
            viewModel.cancelTasksFromMainActor()
            viewModel.cleanupAfterCancellation()
        }
    }
}

struct LeaderboardContent: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    let addLog: (String, Bool) -> Void
    
    var body: some View {
        VStack {
            // Category Picker
            Picker("Category", selection: $viewModel.selectedCategory) {
                ForEach(LeaderboardCategory.allCases, id: \.id) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .disabled(viewModel.isLoading)
            .onChange(of: viewModel.selectedCategory) { _, newValue in
                addLog("Category changed to \(newValue.rawValue)")
            }
            
            // Type Picker
            Picker("Type", selection: $viewModel.selectedBoard) {
                ForEach(LeaderboardType.allCases, id: \.id) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 8)
            .disabled(viewModel.isLoading)
            .onChange(of: viewModel.selectedBoard) { _, newValue in
                addLog("Board type changed to \(newValue.rawValue)")
            }
            
            // Content based on state
            ZStack {
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading...")
                    }
                    .onAppear { addLog("Showing loading state") }
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            addLog("Retry button pressed")
                            viewModel.refreshData()
                        }
                        .padding()
                    }
                    .padding()
                    .onAppear { addLog("Showing error state: \(error)", isError: true) }
                } else if viewModel.leaderboardEntries.isEmpty {
                    VStack {
                        Text("No entries found.")
                            .foregroundColor(.secondary)
                        Button("Refresh") {
                            addLog("Empty state refresh pressed")
                            viewModel.refreshData()
                        }
                        .padding()
                    }
                    .onAppear { addLog("Showing empty state") }
                } else {
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.leaderboardEntries) { entry in
                                HStack {
                                    Text("#\(entry.rank)")
                                        .frame(width: 40, alignment: .leading)
                                    Text(entry.name)
                                    Spacer()
                                    Text("\(entry.score) pts")
                                        .bold()
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .onAppear { 
                        addLog("Showing entries list with \(viewModel.leaderboardEntries.count) items")
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// Helper for lazy loading views
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

#Preview {
    LeaderboardViewDebug()
} 