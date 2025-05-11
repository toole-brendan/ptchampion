import SwiftUI

/// View that displays the current network and sync status
struct OfflineSyncStatusView: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitorService
    @State private var showingDetails = false
    @State var pendingSyncCount: Int = 0
    @State private var isSyncing = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Network status indicator bar
            HStack {
                // Connection status icon
                Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                    .foregroundColor(networkMonitor.isConnected ? .green : .orange)
                
                // Status text and sync count
                if pendingSyncCount > 0 {
                    if networkMonitor.isConnected {
                        Text("Online • \(pendingSyncCount) pending sync\(pendingSyncCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("Offline • \(pendingSyncCount) pending sync\(pendingSyncCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } else {
                    Text(networkMonitor.isConnected ? "Online" : "Offline Mode")
                        .font(.caption)
                        .foregroundColor(networkMonitor.isConnected ? .green : .orange)
                }
                
                Spacer()
                
                // Show sync indicator if actively syncing
                if isSyncing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, 4)
                }
                
                // Chevron to expand/collapse details
                Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    showingDetails.toggle()
                }
            }
            
            // Expanded details section
            if showingDetails {
                VStack(alignment: .leading, spacing: 8) {
                    // Connection details
                    HStack {
                        Text("Connection:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(networkMonitor.connectionDescription)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    // Sync status
                    HStack {
                        Text("Pending Syncs:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(pendingSyncCount) item\(pendingSyncCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(pendingSyncCount > 0 ? .orange : .primary)
                    }
                    
                    // Manual sync button
                    Button {
                        triggerManualSync()
                    } label: {
                        if isSyncing {
                            HStack {
                                Text("Syncing...")
                                    .font(.caption)
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        } else {
                            Text("Sync Now")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    networkMonitor.isConnected && pendingSyncCount > 0 
                                    ? Color.blue 
                                    : Color.gray
                                )
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    .disabled(!networkMonitor.isConnected || pendingSyncCount == 0 || isSyncing)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.03))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: showingDetails)
        .onReceive(NotificationCenter.default.publisher(for: .syncStarted)) { _ in
            isSyncing = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .syncCompleted)) { _ in
            isSyncing = false
        }
    }
    
    /// Trigger a manual sync operation
    private func triggerManualSync() {
        guard networkMonitor.isConnected && pendingSyncCount > 0 && !isSyncing else { 
            return 
        }
        
        // Show syncing indicator
        isSyncing = true
        
        // Post notification to trigger sync
        NotificationCenter.default.post(name: .manualSyncRequested, object: nil)
        
        // Show syncing indicator for at least 1 second for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // This will be turned off by the syncCompleted notification when sync actually finishes
            // But if sync finishes too quickly, this ensures the indicator is visible long enough
            // for the user to see that something happened
        }
    }
}

/// Add notification names for sync events
extension Notification.Name {
    static let syncStarted = Notification.Name("syncStarted")
    static let syncCompleted = Notification.Name("syncCompleted")
    static let manualSyncRequested = Notification.Name("manualSyncRequested")
}

#Preview {
    VStack {
        OfflineSyncStatusView(pendingSyncCount: 3)
            .environmentObject(NetworkMonitorService())
        
        Spacer()
    }
    .padding()
}

/// View modifier to add the offline sync status view to any view
struct OfflineSyncStatusViewModifier: ViewModifier {
    @EnvironmentObject private var networkMonitor: NetworkMonitorService
    @State private var showBanner = false
    @State private var pendingSyncCount = 0
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if !networkMonitor.isConnected || showBanner || pendingSyncCount > 0 {
                OfflineSyncStatusView(pendingSyncCount: pendingSyncCount)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .onReceive(networkMonitor.$isConnected) { isConnected in
            withAnimation {
                // Always show when offline, briefly show when connection restored
                if !isConnected {
                    showBanner = true
                } else {
                    // When connection restored, show briefly then hide if no pending syncs
                    showBanner = true
                    
                    // Hide after 3 seconds if online and no pending syncs
                    if pendingSyncCount == 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showBanner = false
                            }
                        }
                    }
                }
            }
        }
    }
}

extension View {
    /// Adds an offline sync status banner that appears when the device is offline
    func withOfflineSyncStatus() -> some View {
        modifier(OfflineSyncStatusViewModifier())
    }
} 