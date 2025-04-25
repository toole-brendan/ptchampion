import Foundation

struct TokenSet: Decodable {
    struct Palette: Decodable { var name: String; var value: String }
    let colors: [Palette]
    let spacing: [Palette]
    let radius: [Palette]
    let fontSize: [Palette]
}

func camel(_ str: String) -> String {
    var s = str.replacingOccurrences(of: "-", with: " ")
    s = s.capitalized.replacingOccurrences(of: " ", with: "")
    return s.prefix(1).lowercased() + s.dropFirst()
}

func hexToSwiftUIColor(_ hex: String) -> String {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int = UInt64()
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:
        (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
        (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    default:
        (a, r, g, b) = (255, 0, 0, 0)
    }
    return "Color(red: \(Double(r)/255.0), green: \(Double(g)/255.0), blue: \(Double(b)/255.0), opacity: \(Double(a)/255.0))"
}

func generateSwift(_ tokens: TokenSet, path: URL) throws {
    var out = """
    // ⚠️ Auto‑generated file. Do not edit.
    import SwiftUI

    public enum Theme {
    """

    out += "\n    // MARK: Colors\n"
    for c in tokens.colors {
        let colorName = camel(c.name)
        out += "    public static let \(colorName) = \(hexToSwiftUIColor(c.value))\n"
    }

    out += "\n    // MARK: Spacing\n    public enum Spacing {\n"
    for s in tokens.spacing { 
        out += "        public static let \(camel(s.name)) : CGFloat = \(s.value)\n" 
    }
    out += "    }\n"

    out += "\n    // MARK: Corner Radius\n    public enum Radius {\n"
    for r in tokens.radius { 
        out += "        public static let \(camel(r.name)) : CGFloat = \(r.value)\n" 
    }
    out += "    }\n"

    out += "\n    // MARK: Font Size\n    public enum FontSize {\n"
    for f in tokens.fontSize { 
        out += "        public static let \(camel(f.name)) : CGFloat = \(f.value)\n" 
    }
    out += "    }\n}"

    try out.write(to: path, atomically: true, encoding: .utf8)
}

// Entry point
let args = CommandLine.arguments
precondition(args.count == 3, "Usage: DesignTokenGenTool <input.json> <output.swift>")
let inputURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2])

let data = try Data(contentsOf: inputURL)
let decoder = JSONDecoder()
let tokenSet = try decoder.decode(TokenSet.self, from: data)
try generateSwift(tokenSet, path: outputURL)

print("Generated \(outputURL.path) ✓") 