import SwiftUI

// Re-export core types with our design system namespace
// This ensures consistency and avoids naming conflicts
// with SwiftUI types like Color, Font, etc.

// These are imported from DesignTokensCore module 
// but we're making them available via simpler imports
public typealias DSColor = SwiftUI.Color
public typealias DSFont = SwiftUI.Font
public typealias DSRadius = CGFloat

// Helpers for SwiftUI interop 
public typealias DSSwiftUIColor = SwiftUI.Color
public typealias DSSwiftUIFont = SwiftUI.Font

// Public type aliases for design system core types
// This helps maintain backward compatibility and 
// ensures users don't have to change their imports
public typealias DSShadow = DSShadow
public typealias DSShadowSize = DSShadowSize

// Import the DSShadow and DSShadowSize types we've defined
// These are exported for use by client code
// The implementation is in DesignTokensCore.swift 

// This file provides clear type aliases to avoid ambiguity
// between SwiftUI built-in types and our design system types

// SwiftUI type aliases for clarity in our code
public typealias DSSwiftUIColor = SwiftUI.Color
public typealias DSSwiftUIFont = SwiftUI.Font 