import Foundation
import Combine

/// Feature flag constants - must match backend
enum FeatureFlag: String {
    case gradingFormulaV2 = "grading_formula_v2"
    case fineTunedPushupModel = "fine_tuned_pushup_model"
    case teamChallenges = "team_challenges"
    case darkModeDefault = "dark_mode_default"
}

/// Feature flag service response type
struct FeatureFlagsResponse: Decodable {
    let features: [String: AnyCodable]
}

/// Type-erased Codable value for handling different flag types
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = "null"
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

/// Error types for feature flag operations
enum FeatureFlagError: Error {
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case flagNotFound
}

/// Service for managing feature flags with caching support
class FeatureFlagService: ObservableObject {
    /// Singleton instance
    static let shared = FeatureFlagService()
    
    /// Published feature flags for SwiftUI observation
    @Published var flags: [String: Any] = [:]
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error state
    @Published var error: Error?
    
    private let apiBaseURL: String
    private let cacheTTL: TimeInterval
    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialize with custom configuration
    init(
        apiBaseURL: String = "https://api.ptchampion.ai",
        cacheTTL: TimeInterval = 300, // 5 minutes
        userDefaults: UserDefaults = .standard
    ) {
        self.apiBaseURL = apiBaseURL
        self.cacheTTL = cacheTTL
        self.userDefaults = userDefaults
        
        // Initialize with cached values
        if let cachedFlags = getCachedFlags() {
            self.flags = cachedFlags
        }
    }
    
    /// Load feature flags from API or cache
    func loadFeatureFlags() {
        // Check if we need to refresh
        if !shouldRefreshCache() && !flags.isEmpty {
            return
        }
        
        isLoading = true
        error = nil
        
        guard let url = URL(string: "\(apiBaseURL)/api/v1/features") else {
            error = FeatureFlagError.invalidResponse
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token if available
        if let token = getAuthToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: FeatureFlagsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let err):
                        self.error = FeatureFlagError.networkError(err)
                        print("Error loading feature flags: \(err)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    // Convert AnyCodable values to their underlying types
                    let featureValues = response.features.mapValues { $0.value }
                    self.flags = featureValues
                    
                    // Cache the flags
                    self.cacheFlags(featureValues)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Check if a boolean feature flag is enabled
    func isEnabled(_ flag: FeatureFlag, defaultValue: Bool = false) -> Bool {
        getBoolValue(flag, defaultValue: defaultValue)
    }
    
    /// Get a boolean value for a feature flag
    func getBoolValue(_ flag: FeatureFlag, defaultValue: Bool = false) -> Bool {
        guard let value = flags[flag.rawValue] else {
            return defaultValue
        }
        
        if let boolValue = value as? Bool {
            return boolValue
        } else if let stringValue = value as? String {
            return stringValue.lowercased() == "true"
        }
        
        return defaultValue
    }
    
    /// Get a string value for a feature flag
    func getStringValue(_ flag: FeatureFlag, defaultValue: String = "") -> String {
        guard let value = flags[flag.rawValue] else {
            return defaultValue
        }
        
        if let stringValue = value as? String {
            return stringValue
        }
        
        return String(describing: value)
    }
    
    /// Get a numeric value for a feature flag
    func getNumberValue(_ flag: FeatureFlag, defaultValue: Double = 0.0) -> Double {
        guard let value = flags[flag.rawValue] else {
            return defaultValue
        }
        
        if let doubleValue = value as? Double {
            return doubleValue
        } else if let intValue = value as? Int {
            return Double(intValue)
        } else if let stringValue = value as? String, let doubleValue = Double(stringValue) {
            return doubleValue
        }
        
        return defaultValue
    }
    
    /// Get a JSON value for a feature flag
    func getJSONValue<T: Decodable>(_ flag: FeatureFlag, defaultValue: T? = nil) -> T? {
        guard let value = flags[flag.rawValue] else {
            return defaultValue
        }
        
        do {
            if let jsonObject = value as? [String: Any] {
                let data = try JSONSerialization.data(withJSONObject: jsonObject)
                return try JSONDecoder().decode(T.self, from: data)
            } else if let jsonString = value as? String, !jsonString.isEmpty {
                guard let data = jsonString.data(using: .utf8) else {
                    return defaultValue
                }
                return try JSONDecoder().decode(T.self, from: data)
            }
        } catch {
            print("Error parsing JSON flag \(flag.rawValue): \(error)")
        }
        
        return defaultValue
    }
    
    /// Force refresh the feature flags from the API
    func refresh() {
        clearLastFetchTime()
        loadFeatureFlags()
    }
    
    /// Clear all cached flags
    func clearCache() {
        flags = [:]
        userDefaults.removeObject(forKey: "feature_flags")
        clearLastFetchTime()
    }
    
    // MARK: - Private Methods
    
    private func getAuthToken() -> String? {
        return userDefaults.string(forKey: "auth_token")
    }
    
    private func shouldRefreshCache() -> Bool {
        let lastFetchTime = userDefaults.double(forKey: "feature_flags_last_fetch")
        let now = Date().timeIntervalSince1970
        return (now - lastFetchTime) > cacheTTL
    }
    
    private func clearLastFetchTime() {
        userDefaults.removeObject(forKey: "feature_flags_last_fetch")
    }
    
    private func cacheFlags(_ flags: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: flags, options: [])
            userDefaults.set(data, forKey: "feature_flags")
            userDefaults.set(Date().timeIntervalSince1970, forKey: "feature_flags_last_fetch")
        } catch {
            print("Error caching feature flags: \(error)")
        }
    }
    
    private func getCachedFlags() -> [String: Any]? {
        guard let data = userDefaults.data(forKey: "feature_flags") else {
            return nil
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        } catch {
            print("Error loading cached feature flags: \(error)")
        }
        
        return nil
    }
}

// MARK: - Convenience API for SwiftUI

extension View {
    /// Conditionally render content based on a feature flag
    func featureFlag(_ flag: FeatureFlag, defaultValue: Bool = false) -> some View {
        let service = FeatureFlagService.shared
        return self.opacity(service.isEnabled(flag, defaultValue: defaultValue) ? 1 : 0)
            .frame(height: service.isEnabled(flag, defaultValue: defaultValue) ? nil : 0)
            .disabled(!service.isEnabled(flag, defaultValue: defaultValue))
    }
}

// Example usage:
/*
struct ContentView: View {
    @ObservedObject private var featureFlags = FeatureFlagService.shared
    
    var body: some View {
        VStack {
            Text("PT Champion")
                .font(.title)
            
            if featureFlags.isEnabled(.teamChallenges) {
                TeamChallengesView()
            }
            
            Button("Refresh Flags") {
                featureFlags.refresh()
            }
        }
        .onAppear {
            featureFlags.loadFeatureFlags()
        }
    }
}
*/ 