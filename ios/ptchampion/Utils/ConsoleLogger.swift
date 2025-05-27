// ConsoleLogger.swift
// Add this to your project for cleaner console output

import Foundation
import os

public enum LogCategory: String {
    case auth = "🔐 AUTH"
    case network = "🌐 NETWORK"
    case ui = "🎨 UI"
    case font = "🔤 FONT"
    case camera = "📸 CAMERA"
    case workout = "💪 WORKOUT"
    case error = "❌ ERROR"
    case warning = "⚠️ WARNING"
    case debug = "🐛 DEBUG"
    case info = "ℹ️ INFO"
}

public class ConsoleLogger {
    static let shared = ConsoleLogger()
    private let logger = Logger(subsystem: "com.toole.ptchampion", category: "main")
    private var logBuffer: [String] = []
    private let maxBufferSize = 1000
    
    // Control verbosity
    var enableDebugLogs = false
    var enableViewInitLogs = false
    
    private init() {}
    
    func log(_ message: String, category: LogCategory = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        // Filter out repetitive logs
        if shouldFilterLog(message, category: category) {
            return
        }
        
        let formattedMessage = "\(timestamp) \(category.rawValue) [\(fileName):\(line)] \(message)"
        
        // Add to buffer for crash reports
        logBuffer.append(formattedMessage)
        if logBuffer.count > maxBufferSize {
            logBuffer.removeFirst()
        }
        
        // Print to console
        print(formattedMessage)
        
        // Also log to system logger
        switch category {
        case .error:
            logger.error("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .debug:
            if enableDebugLogs {
                logger.debug("\(message)")
            }
        default:
            logger.info("\(message)")
        }
    }
    
    private func shouldFilterLog(_ message: String, category: LogCategory) -> Bool {
        // Filter out repetitive view initialization logs
        if !enableViewInitLogs && message.contains("Initialized LeaderboardView") {
            return true
        }
        
        // Filter out repetitive font logs after initial report
        if category == .font && logBuffer.filter({ $0.contains("FONT REGISTRATION") }).count > 10 {
            return true
        }
        
        // Filter debug logs if not enabled
        if category == .debug && !enableDebugLogs {
            return true
        }
        
        return false
    }
    
    func logNetworkRequest(_ request: URLRequest) {
        guard let url = request.url,
              let method = request.httpMethod else { return }
        
        var message = "\(method) \(url.absoluteString)"
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            message += "\nHeaders: \(headers)"
        }
        
        log(message, category: .network)
    }
    
    func logNetworkResponse(_ response: HTTPURLResponse?, data: Data?, error: Error?) {
        if let error = error {
            log("Network Error: \(error.localizedDescription)", category: .error)
            return
        }
        
        guard let response = response else { return }
        
        var message = "Response [\(response.statusCode)] \(response.url?.absoluteString ?? "")"
        
        if response.statusCode >= 400 {
            if let data = data, let body = String(data: data, encoding: .utf8) {
                message += "\nBody: \(body)"
            }
            log(message, category: .error)
        } else {
            log(message, category: .network)
        }
    }
    
    func getCrashLog() -> String {
        return logBuffer.joined(separator: "\n")
    }
}

// Convenience global functions
public func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ConsoleLogger.shared.log(message, category: .debug, file: file, function: function, line: line)
}

public func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ConsoleLogger.shared.log(message, category: .info, file: file, function: function, line: line)
}

public func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ConsoleLogger.shared.log(message, category: .warning, file: file, function: function, line: line)
}

public func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ConsoleLogger.shared.log(message, category: .error, file: file, function: function, line: line)
} 