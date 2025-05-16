import SwiftUI
import PTDesignSystem

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
    
    public var color: Color {
        switch self {
        case .up:
            return AppTheme.GeneratedColors.success
        case .down:
            return AppTheme.GeneratedColors.error
        case .neutral:
            return AppTheme.GeneratedColors.textTertiary
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
    public let subtitle: String?

    public init(
        title: String,
        value: Any,
        unit: String? = nil,
        description: String? = nil,
        subtitle: String? = nil,
        icon: Image? = nil
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.description = description
        self.subtitle = subtitle
        self.icon = icon
    }
    
    // Convenience initializer for int values
    public init(
        title: String,
        value: Int,
        unit: String? = nil,
        description: String? = nil,
        subtitle: String? = nil,
        icon: Image? = nil
    ) {
        self.init(
            title: title,
            value: value as Any,
            unit: unit,
            description: description,
            subtitle: subtitle,
            icon: icon
        )
    }
    
    // Convenience initializer for double values
    public init(
        title: String,
        value: Double,
        unit: String? = nil,
        description: String? = nil,
        subtitle: String? = nil,
        icon: Image? = nil
    ) {
        self.init(
            title: title,
            value: value as Any,
            unit: unit,
            description: description,
            subtitle: subtitle,
            icon: icon
        )
    }
    
    // Convenience initializer for string values
    public init(
        title: String,
        value: String,
        description: String? = nil,
        subtitle: String? = nil,
        icon: Image? = nil
    ) {
        self.init(
            title: title,
            value: value as Any,
            unit: nil,
            description: description,
            subtitle: subtitle,
            icon: icon
        )
    }
} 