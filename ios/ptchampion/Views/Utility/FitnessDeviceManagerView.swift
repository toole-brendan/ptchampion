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
    @State private var showHealthKitDeniedAlert = false
    @State private var isRequestingHealthKitAuth = false
    @State private var hasCheckedExistingAuth = false
    @AppStorage("useImperialUnits") private var useImperialUnits = false

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
        .sheet(isPresented: $showingDeviceDetails) {
            deviceDetailsView()
        }
        .alert("HealthKit Access Required", isPresented: $showHealthKitDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable HealthKit access in Settings > Privacy & Security > Health > PT Champion")
        }
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
                            isRequestingHealthKitAuth = true
                            Task {
                                print("DEBUG: About to request HealthKit auth")
                                
                                // Add a small delay to ensure the view is fully presented
                                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                
                                let authorized = await viewModel.requestHealthKitAuthorization()
                                print("DEBUG: HealthKit auth result: \(authorized)")
                                
                                isRequestingHealthKitAuth = false
                                
                                if authorized {
                                    print("DEBUG: Starting to monitor HealthKit data")
                                    // Start monitoring immediately after authorization
                                    viewModel.startMonitoringHealthKitData()
                                    await viewModel.fetchRecentWorkouts()
                                    
                                    // Show success feedback
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                } else {
                                    print("DEBUG: HealthKit auth failed or was denied")
                                    // Check if it's a permission issue or a real denial
                                    let status = HKHealthStore().authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRate)!)
                                    
                                    if status == .notDetermined {
                                        print("DEBUG: HealthKit authorization still not determined")
                                    } else if status == .sharingDenied {
                                        print("DEBUG: HealthKit authorization was denied by user")
                                        // Show alert to guide user to Settings
                                        showHealthKitDeniedAlert = true
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if isRequestingHealthKitAuth {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.GeneratedColors.deepOps))
                                        .scaleEffect(0.8)
                                    Text("Connecting...")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.GeneratedColors.deepOps)
                                } else {
                                    Text("Connect")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.GeneratedColors.textOnPrimary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.GeneratedColors.brassGold)
                            .cornerRadius(8)
                            .opacity(isRequestingHealthKitAuth ? 0.7 : 1.0)
                        }
                        .disabled(isRequestingHealthKitAuth)
                    } else {
                        // Show connected state with checkmark
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.GeneratedColors.success)
                                .font(.system(size: 20))
                            
                            Text("Connected")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.GeneratedColors.success)
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
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            // Check if we already have authorization
            if !hasCheckedExistingAuth {
                hasCheckedExistingAuth = true
                Task {
                    // Force a check of current authorization status
                    if UserDefaults.standard.bool(forKey: "HasRequestedHealthKitAuth") {
                        print("DEBUG: Checking existing HealthKit authorization")
                        let authorized = await viewModel.requestHealthKitAuthorization()
                        if authorized {
                            print("DEBUG: Already authorized, starting monitoring")
                            viewModel.startMonitoringHealthKitData()
                        }
                    }
                }
            }
        }
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
                        // Check Bluetooth state and show appropriate error if needed
                        if viewModel.bluetoothState == .poweredOff {
                            // Show alert or handle error
                            print("DEBUG: Bluetooth is powered off")
                        } else if viewModel.bluetoothState == .unauthorized {
                            // Open settings
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } else {
                            viewModel.startBluetoothScan()
                        }
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
                
                // Bluetooth State Warning
                if viewModel.bluetoothState != .poweredOn {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.GeneratedColors.warning)
                            .font(.system(size: 14))
                        
                        Text(bluetoothStateMessage)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        if viewModel.bluetoothState == .poweredOff || viewModel.bluetoothState == .unauthorized {
                            Button("Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.GeneratedColors.warning.opacity(0.1))
                    .cornerRadius(6)
                }
                
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
    
    private var bluetoothStateMessage: String {
        switch viewModel.bluetoothState {
        case .poweredOff:
            return "Bluetooth is off. Turn on in Settings."
        case .unauthorized:
            return "Bluetooth permission denied. Allow in Settings."
        case .unsupported:
            return "Bluetooth is not supported on this device."
        case .resetting:
            return "Bluetooth is resetting..."
        case .unknown:
            return "Bluetooth state unknown."
        default:
            return ""
        }
    }
    
    @ViewBuilder
    private func connectedDeviceView(_ device: CBPeripheral) -> some View {
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
        }
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func autoConnectDeviceView() -> some View {
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
        }
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(8)
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