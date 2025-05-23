import SwiftUI
import HealthKit
import CoreBluetooth
import PTDesignSystem

// Create explicit button styles to avoid ambiguity
fileprivate let primaryButtonStyle = PTButton.ExtendedStyle.primary
fileprivate let secondaryButtonStyle = PTButton.ExtendedStyle.secondary
fileprivate let destructiveButtonStyle = PTButton.ExtendedStyle.destructive

struct FitnessDeviceManagerView: View {
    @EnvironmentObject var viewModel: FitnessDeviceManagerViewModel
    @State private var showingDeviceDetails = false
    @State private var activeBanner: BannerType?     // nil = none
    @AppStorage("useImperialUnits") private var useImperialUnits = false
    @AppStorage("dismissedBluetoothWarning") private var dismissedBluetoothWarning = false

    enum BannerType { case bluetooth, healthKit }
    
    var body: some View {
        ZStack {
            // Ambient Background Gradient (matching Dashboard)
            RadialGradient(
                gradient: Gradient(colors: [
                    AppTheme.GeneratedColors.background.opacity(0.9),
                    AppTheme.GeneratedColors.background
                ]),
                center: .center,
                startRadius: 50,
                endRadius: UIScreen.main.bounds.height * 0.6
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Banner at the top
                bannerView
                
                ScrollView {
                    VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                        // Header
                        deviceSourcesSection()
                        
                        // Current Metrics Section
                        if viewModel.isReceivingHeartRateData || 
                           viewModel.isReceivingPaceData || 
                           viewModel.isReceivingCadenceData {
                            currentMetricsSection()
                        }
                        
                        // Device Sections
                        if viewModel.isHealthKitAvailable {
                            appleWatchSection()
                        }
                        
                        bluetoothDevicesSection()
                        
                        Spacer(minLength: AppTheme.GeneratedSpacing.contentPadding)
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                }
            }
        }
        .navigationTitle("Fitness Devices")
        .onAppear {
            // This fires after the NavigationView is on-screen.
            print("DEBUG: [FitnessDeviceManagerView] onAppear")
            print("DEBUG: [FitnessDeviceManagerView] Current activeBanner: \(String(describing: activeBanner))")
            print("DEBUG: [FitnessDeviceManagerView] dismissedBluetoothWarning: \(viewModel.dismissedBluetoothWarning)")
            
            // Track state
            viewModel.showBluetoothError = false
            print("DEBUG: [FitnessDeviceManagerView] Reset showBluetoothError to false")
            
            if viewModel.bluetoothState != .poweredOn && !dismissedBluetoothWarning {
                print("DEBUG: [FitnessDeviceManagerView] Bluetooth state is \(viewModel.bluetoothState.stateDescription), showing banner")
                DispatchQueue.main.async {
                    showBluetoothBanner()
                }
            } else {
                print("DEBUG: [FitnessDeviceManagerView] No banner needed: Bluetooth=\(viewModel.bluetoothState.stateDescription), dismissedWarning=\(dismissedBluetoothWarning)")
            }
        }
        .onDisappear {
            print("DEBUG: [FitnessDeviceManagerView] onDisappear - activeBanner: \(String(describing: activeBanner))")
            print("DEBUG: [FitnessDeviceManagerView] onDisappear - dismissedBluetoothWarning: \(viewModel.dismissedBluetoothWarning)")
            print("DEBUG: [FitnessDeviceManagerView] onDisappear - bluetoothState: \(viewModel.bluetoothState.stateDescription)")
            
            // Reset banner state on disappear to ensure it can be shown again
            if activeBanner != nil {
                print("DEBUG: [FitnessDeviceManagerView] Resetting activeBanner from \(String(describing: activeBanner)) to nil on disappear")
                activeBanner = nil
            } else {
                print("DEBUG: [FitnessDeviceManagerView] activeBanner already nil on disappear")
            }
        }
        .sheet(isPresented: $showingDeviceDetails) {
            deviceDetailsView()
        }
        .onReceive(viewModel.$showBluetoothError) { hasError in
            print("DEBUG: [FitnessDeviceManagerView] onReceive showBluetoothError: \(hasError)")
            print("DEBUG: [FitnessDeviceManagerView] onReceive dismissedBluetoothWarning: \(dismissedBluetoothWarning)")
            
            guard hasError, 
                  !dismissedBluetoothWarning,
                  activeBanner == nil   // Prevent rebuild loop
            else {
                if hasError {
                    print("DEBUG: [FitnessDeviceManagerView] Ignoring showBluetoothError because dismissedBluetoothWarning=\(dismissedBluetoothWarning) or banner exists=\(activeBanner != nil)")
                }
                return
            }
            
            print("DEBUG: [FitnessDeviceManagerView] Showing banner and auto-resetting trigger")
            DispatchQueue.main.async {
                showBluetoothBanner()
                viewModel.showBluetoothError = false
            }
        }
        // Removed automatic HealthKit authorization to prevent auto-dismissal
        // Now authorization only happens when user explicitly taps "Connect" button
    }
    
    // MARK: - Banner Helpers
    private func showBluetoothBanner() {
        print("DEBUG: [FitnessDeviceManagerView] Showing Bluetooth Banner - activeBanner was \(String(describing: activeBanner))")
        print("DEBUG: [FitnessDeviceManagerView] dismissedBluetoothWarning = \(dismissedBluetoothWarning)")
        print("DEBUG: [FitnessDeviceManagerView] Bluetooth state = \(viewModel.bluetoothState.stateDescription)")
        
        // Guard against showing banner that's already dismissed or showing
        guard activeBanner == nil, !dismissedBluetoothWarning else {
            print("DEBUG: [FitnessDeviceManagerView] NOT showing banner because: activeBanner=\(String(describing: activeBanner)), dismissedWarning=\(dismissedBluetoothWarning)")
            return
        }
            
        print("DEBUG: [FitnessDeviceManagerView] Setting activeBanner to .bluetooth")
        activeBanner = .bluetooth
        viewModel.showBluetoothError = false  // reset trigger
        print("DEBUG: [FitnessDeviceManagerView] Set activeBanner to .bluetooth")
    }
    
    private func showHealthKitBanner() {
        print("DEBUG: Showing HealthKit Banner - activeBanner was \(String(describing: activeBanner))")
        if activeBanner == nil { 
            activeBanner = .healthKit
            print("DEBUG: Set activeBanner to .healthKit")
        }
    }
    
    // Add banner debugging
    private var bannerView: some View {
        Group {
            if let banner = activeBanner {
                WarningBanner(
                    title: banner == .bluetooth ? "Bluetooth Error"
                                                : "HealthKit Authorization",
                    message: banner == .bluetooth
                             ? viewModel.bluetoothErrorMessage
                             : "Please allow PT Champion to access your health data to use Apple Watch features.",
                    primary: .init(label: "OK") { 
                        print("DEBUG: [FitnessDeviceManagerView] Banner primary button (OK) tapped - banner type: \(banner)")
                        // Set the dismissal flag first, then dismiss the banner
                        if banner == .bluetooth {
                            print("DEBUG: [FitnessDeviceManagerView] Setting dismissedBluetoothWarning = true")
                            dismissedBluetoothWarning = true
                        }
                        
                        // Slight delay before dismissing to ensure the tap is fully processed
                        print("DEBUG: [FitnessDeviceManagerView] Scheduling banner dismissal after 0.1s delay")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            print("DEBUG: [FitnessDeviceManagerView] Inside delayed dismissal block")
                            print("DEBUG: [FitnessDeviceManagerView] Setting activeBanner = nil")
                            activeBanner = nil 
                            print("DEBUG: [FitnessDeviceManagerView] Banner dismissal complete")
                        }
                    },
                    secondary: banner == .bluetooth
                        ? .init(label: "Settings") {
                              print("DEBUG: [FitnessDeviceManagerView] Banner settings button tapped")
                              if let url = URL(string: UIApplication.openSettingsURLString) {
                                  print("DEBUG: [FitnessDeviceManagerView] Opening settings URL")
                                  UIApplication.shared.open(url)
                              }
                              
                              // Set dismissed flag FIRST to prevent race condition
                              print("DEBUG: [FitnessDeviceManagerView] Setting dismissedBluetoothWarning = true")
                              dismissedBluetoothWarning = true
                              
                              print("DEBUG: [FitnessDeviceManagerView] Scheduling banner dismissal after settings opened (0.5s delay)")
                              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                  print("DEBUG: [FitnessDeviceManagerView] Inside settings delayed dismissal block")
                                  print("DEBUG: [FitnessDeviceManagerView] Setting activeBanner = nil")
                                  activeBanner = nil
                                  print("DEBUG: [FitnessDeviceManagerView] Banner dismissal after settings complete")
                              }
                          }
                        : nil
                )
                .onAppear {
                    print("DEBUG: [FitnessDeviceManagerView] Banner appeared - type: \(banner)")
                    print("DEBUG: [FitnessDeviceManagerView] Current dismissedBluetoothWarning: \(viewModel.dismissedBluetoothWarning)")
                }
                .onDisappear {
                    print("DEBUG: [FitnessDeviceManagerView] Banner disappeared - type: \(banner)")
                    print("DEBUG: [FitnessDeviceManagerView] dismissedBluetoothWarning at disappear: \(viewModel.dismissedBluetoothWarning)")
                    print("DEBUG: [FitnessDeviceManagerView] activeBanner at disappear: \(String(describing: activeBanner))")
                }
                .id(banner) // Force view recreation when banner type changes
            }
        }
        .animation(.easeInOut, value: activeBanner)
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func deviceSourcesSection() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with dark background and gold text (like dashboard)
            VStack(alignment: .leading, spacing: 4) {
                Text("DATA SOURCES")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("ACTIVE FITNESS TRACKING SOURCES")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Content section with cream background
            HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Heart Rate Source
                VStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    
                    Text("HEART RATE")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    
                    Text(viewModel.isReceivingHeartRateData ? viewModel.primaryDataSource() : "None")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.isReceivingHeartRateData ? AppTheme.GeneratedColors.deepOps : AppTheme.GeneratedColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                // Location Source
                VStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    
                    Text("GPS")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    
                    Text(viewModel.isReceivingLocationData ? viewModel.deviceDisplayName() : "Phone")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                }
                .frame(maxWidth: .infinity)
                
                // Pace Source
                VStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "figure.walk")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    
                    Text("PACE")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    
                    Text(viewModel.isReceivingPaceData ? viewModel.deviceDisplayName() : "None")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.isReceivingPaceData ? AppTheme.GeneratedColors.deepOps : AppTheme.GeneratedColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(red: 0.93, green: 0.91, blue: 0.86)) // cream-dark from web
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func currentMetricsSection() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with dark background and gold text (like dashboard)
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT METRICS")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("LIVE FITNESS DATA")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Metrics with cream background
            HStack(spacing: AppTheme.GeneratedSpacing.medium) {
                if viewModel.heartRate > 0 {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.error.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.GeneratedColors.error)
                        }
                        
                        Text(viewModel.formattedHeartRate())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text("HEART RATE")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                if viewModel.currentPace.metersPerSecond > 0 {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.brassGold.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "figure.run")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                        
                        Text(viewModel.formattedPace(useImperial: useImperialUnits))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text(useImperialUnits ? "MIN/MILE" : "MIN/KM")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                if viewModel.currentCadence.stepsPerMinute > 0 {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "metronome")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        }
                        
                        Text(viewModel.formattedCadence())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text("CADENCE")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(red: 0.93, green: 0.91, blue: 0.86)) // cream-dark from web
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func appleWatchSection() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with dark background and gold text (like dashboard)
            VStack(alignment: .leading, spacing: 4) {
                Text("APPLE WATCH")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("HEALTHKIT DATA CONNECTION")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Content with cream background
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.GeneratedColors.oliveMist.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "applewatch")
                            .font(.title2)
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(viewModel.isHealthKitAuthorized ? "Connected" : "Not Connected")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text(viewModel.isHealthKitAuthorized ? 
                             "Data from Apple Health" : 
                             "Authorization required")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !viewModel.isHealthKitAuthorized {
                        Button {
                            Task {
                                let authorized = await viewModel.requestHealthKitAuthorization()
                                if authorized {
                                    await viewModel.fetchRecentWorkouts()
                                } else {
                                    showHealthKitBanner()
                                }
                            }
                        } label: {
                            Text("Connect")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.GeneratedColors.textOnPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppTheme.GeneratedColors.brassGold)
                                .cornerRadius(8)
                        }
                    }
                }
                
                if viewModel.isHealthKitAuthorized {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    Toggle(isOn: $viewModel.preferAppleWatchForHeartRate) {
                        Text("Prefer Apple Watch for Heart Rate")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.GeneratedColors.brassGold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(red: 0.93, green: 0.91, blue: 0.86)) // cream-dark from web
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func bluetoothDevicesSection() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with dark background and gold text (like dashboard)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("BLUETOOTH DEVICES")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    
                    Spacer()
                    
                    Text("Status: \(viewModel.bluetoothState.stateDescription)")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(viewModel.bluetoothState == .poweredOn ? 
                                   AppTheme.GeneratedColors.success.opacity(0.2) : 
                                   AppTheme.GeneratedColors.error.opacity(0.2))
                        .foregroundColor(viewModel.bluetoothState == .poweredOn ? 
                                        AppTheme.GeneratedColors.success : 
                                        AppTheme.GeneratedColors.error)
                        .cornerRadius(4)
                }
                .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold.opacity(0.3))
                    .padding(.bottom, 4)
                
                Text("CONNECT TO YOUR FITNESS DEVICES")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.GeneratedColors.deepOps)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
            
            // Content with cream background
            VStack(spacing: AppTheme.GeneratedSpacing.medium) {
                // Connected Device
                if let device = viewModel.connectedBluetoothDevice {
                    connectedDeviceView(device)
                } else if viewModel.hasPreferredDevice() {
                    // Show auto-connect option if we have a preferred device but not connected
                    autoConnectDeviceView()
                }
                
                // Scan Button
                Button {
                    if viewModel.isBluetoothScanning {
                        viewModel.stopBluetoothScan()
                    } else {
                        viewModel.startBluetoothScan()
                    }
                } label: {
                    HStack {
                        Spacer()
                        
                        if viewModel.isBluetoothScanning {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                                    .scaleEffect(0.8)
                                
                                Text("Stop Scanning")
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.leading, 8)
                            }
                        } else {
                            Text("Scan for Devices")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(
                        viewModel.isBluetoothScanning ? 
                        AppTheme.GeneratedColors.error : 
                        AppTheme.GeneratedColors.brassGold
                    )
                    .cornerRadius(8)
                    .opacity(viewModel.bluetoothState != .poweredOn ? 0.5 : 1.0)
                }
                .disabled(viewModel.bluetoothState != .poweredOn)
                
                // Scanning Indicator
                if viewModel.isBluetoothScanning {
                    HStack {
                        Text("Scanning for fitness devices...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 4)
                }
                
                // List of discovered devices
                if !viewModel.bluetoothDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("AVAILABLE DEVICES")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                            .padding(.vertical, 8)
                        
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.bluetoothDevices) { device in
                                    deviceRow(device)
                                    
                                    if device.id != viewModel.bluetoothDevices.last?.id {
                                        Divider()
                                            .background(Color.gray.opacity(0.2))
                                    }
                                }
                            }
                        }
                        .frame(height: min(300, CGFloat(viewModel.bluetoothDevices.count * 60 + 20)))
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(red: 0.93, green: 0.91, blue: 0.86)) // cream-dark from web
            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func connectedDeviceView(_ device: CBPeripheral) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CONNECTED DEVICE")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            
            VStack {
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.GeneratedColors.success.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.GeneratedColors.success)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\(device.name ?? "Unknown Device")")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        HStack {
                            Text(viewModel.deviceDisplayName())
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            if let batteryLevel = viewModel.deviceBatteryLevel {
                                HStack(spacing: 4) {
                                    Image(systemName: "battery.50")
                                        .foregroundColor(AppTheme.GeneratedColors.success)
                                    
                                    Text("\(batteryLevel)%")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.GeneratedColors.success)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button {
                            showingDeviceDetails = true
                        } label: {
                            Text("Details")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(AppTheme.GeneratedColors.deepOps.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Button {
                            viewModel.disconnectFromDevice()
                        } label: {
                            Text("Disconnect")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.GeneratedColors.error)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color.white)
            .cornerRadius(8)
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private func autoConnectDeviceView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SAVED DEVICE")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.GeneratedColors.deepOps)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            
            VStack {
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.GeneratedColors.brassGold.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Previous Device")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                        Text("You have a preferred device saved")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button {
                            viewModel.reconnectToPreferredDevice()
                        } label: {
                            Text("Reconnect")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.GeneratedColors.brassGold)
                                .cornerRadius(6)
                        }
                        
                        Button {
                            viewModel.forgetPreferredDevice()
                        } label: {
                            Text("Forget")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.GeneratedColors.error)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color.white)
            .cornerRadius(8)
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private func deviceRow(_ device: DiscoveredPeripheral) -> some View {
        // Don't show already connected devices
        if viewModel.connectedBluetoothDevice?.identifier != device.id {
            HStack {
                VStack(alignment: .leading) {
                    Text(device.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                        
                    HStack(spacing: 8) {
                        if device.deviceType != .unknown {
                            Text(device.deviceType.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("RSSI: \(device.rssi)")
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray)
                    }
                }
                
                Spacer()
                
                if case .connecting = viewModel.deviceConnectionState {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button {
                        viewModel.connectToDevice(device)
                    } label: {
                        Text("Connect")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.textOnPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.GeneratedColors.brassGold)
                            .cornerRadius(6)
                            .opacity(!isConnectable(state: viewModel.deviceConnectionState) ? 0.5 : 1.0)
                    }
                    .disabled(!isConnectable(state: viewModel.deviceConnectionState))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private func deviceDetailsView() -> some View {
        NavigationView {
            VStack {
                if let peripheral = viewModel.connectedBluetoothDevice {
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                        FitnessDetailRow(label: "Name", value: peripheral.name ?? "Unknown")
                        FitnessDetailRow(label: "Manufacturer", value: viewModel.deviceManufacturer ?? "Unknown")
                        FitnessDetailRow(label: "Type", value: viewModel.connectedDeviceType.rawValue)
                        FitnessDetailRow(label: "Battery", value: viewModel.formattedBatteryLevel())
                        
                        Divider()
                        
                        PTLabel("Supported Features:", style: .bodyBold)
                            .padding(.top, AppTheme.GeneratedSpacing.small)
                        
                        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                            FitnessFeatureRow(title: "Heart Rate", isSupported: viewModel.isReceivingHeartRateData)
                            FitnessFeatureRow(title: "Location Tracking", isSupported: viewModel.isReceivingLocationData)
                            FitnessFeatureRow(title: "Running Pace", isSupported: viewModel.isReceivingPaceData)
                            FitnessFeatureRow(title: "Running Cadence", isSupported: viewModel.isReceivingCadenceData)
                        }
                        .padding(.leading, AppTheme.GeneratedSpacing.medium)
                        
                        Spacer()
                    }
                    .padding(AppTheme.GeneratedSpacing.contentPadding)
                } else {
                    PTLabel("No device connected", style: .body)
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        .padding(AppTheme.GeneratedSpacing.contentPadding)
                    
                    Spacer()
                }
            }
            .navigationTitle("Device Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showingDeviceDetails = false
                    }
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                }
            }
        }
    }
    
    // Helper function to check if the state allows initiating a connection
    private func isConnectable(state: PeripheralConnectionState) -> Bool {
        switch state {
        case .disconnected, .failed:
            return true
        default:
            return false
        }
    }
}

// Re-using helper components from DeviceScanningView
private struct FitnessMetricView: View {
    let value: String
    let title: String
    let systemImage: String
    
    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
            
            PTLabel(value, style: .heading)
                .fontWeight(.bold)
            
            PTLabel(title, style: .caption)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
        }
        .frame(minWidth: 70)
    }
}

private struct FitnessDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            PTLabel(label, style: .body)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .frame(width: 120, alignment: .leading)
            
            PTLabel(value, style: .bodyBold)
            
            Spacer()
        }
    }
}

private struct FitnessFeatureRow: View {
    let title: String
    let isSupported: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isSupported ? AppTheme.GeneratedColors.success : AppTheme.GeneratedColors.error)
            
            PTLabel(title, style: .body)
                .foregroundColor(isSupported ? AppTheme.GeneratedColors.textPrimary : AppTheme.GeneratedColors.textSecondary)
            
            Spacer()
        }
    }
}

// Extension to provide descriptive strings for CBManagerState
extension CBManagerState {
    var stateDescription: String {
        switch self {
        case .poweredOn: return "Powered On"
        case .poweredOff: return "Powered Off"
        case .resetting: return "Resetting"
        case .unauthorized: return "Unauthorized"
        case .unsupported: return "Unsupported"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown State"
        }
    }
}

#Preview {
    NavigationView {
        FitnessDeviceManagerView()
            .environmentObject(FitnessDeviceManagerViewModel())
    }
}