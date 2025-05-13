import SwiftUI
import PTDesignSystem

fileprivate typealias DSColor = PTDesignSystem.Color

/// Trend direction indicators for metric data visualization
public enum TrendDirection {
    case up, down, neutral
    
    public var icon: Image {
        switch self {
        case .up:
            return Image(systemName: "arrow.up")
        case .down:
            return Image(systemName: "arrow.down")
        case .neutral:
            return Image(systemName: "arrow.forward")
        }
    }
    
    public var color: SwiftUI.Color {
        switch self {
        case .up:
            return DSColor.success
        case .down:
            return DSColor.error
        case .neutral:
            return DSColor.textTertiary
        }
    }
}

public struct MetricData: Identifiable {
    public let id = UUID()
    public let title: String
    public let value: Any
    public let unit: String?
    public let description: String?
    public let icon: Image?

    public init(
        title: String,
        value: Any,
        unit: String? = nil,
        description: String? = nil,
        icon: Image? = nil
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.description = description
        self.icon = icon
    }
    
    // Convenience initializer for int values
    public init(
        title: String,
        value: Int,
        unit: String? = nil,
        description: String? = nil,
        icon: Image? = nil
    ) {
        self.init(
            title: title,
            value: value as Any,
            unit: unit,
            description: description,
            icon: icon
        )
    }
    
    // Convenience initializer for double values
    public init(
        title: String,
        value: Double,
        unit: String? = nil,
        description: String? = nil,
        icon: Image? = nil
    ) {
        self.init(
            title: title,
            value: value as Any,
            unit: unit,
            description: description,
            icon: icon
        )
    }
    
    // Convenience initializer for string values
    public init(
        title: String,
        value: String,
        description: String? = nil,
        icon: Image? = nil
    ) {
        self.init(
            title: title,
            value: value as Any,
            unit: nil,
            description: description,
            icon: icon
        )
    }
} 