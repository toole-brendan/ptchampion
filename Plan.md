Below is a practical game-plan to bring the iOS SwiftUI client to full parity with your Tailwind-driven web front-end, re-using the palette, typography, component DNA and data flow patterns you already established.

1 · Lock design tokens in one place

Task	How	Why
Export Tailwind tokens → JSON	`npx tailwindcss --list-config	jq … > design-tokens.json`
Generate Swift code on build	Add a tiny Swift PM plugin that reads the JSON and regenerates Theme.generated.swift (extension of your current Theme.swift) before each build.	No hand-syncing; changes on the web propagate instantly.
Fonts	You already reference Montserrat / Bebas / Roboto Mono in Theme.swift 
GitHub
 – just drop the .ttf files into Resources and list them in Info.plist ⇢ Fonts provided by application.	
2 · Component kit ≈ shadcn/ui
You have a good start with PrimaryButtonStyle, CardBackground, NavLabelTextStyle, etc. 
GitHub

Next steps:

Atoms – Finish Buttons (primary/secondary/destructive), TextField (with floating label + validation icon), Badge, Spinner.

Molecules – StatCard, WorkoutTile, LeaderboardRow, ErrorToast.

Organisms – DashboardHeader, WorkoutHistoryList, SettingsSheet.

Create a PreviewProvider grid so every component renders in all states, the same way Storybook does for web.

Tip: keep every style in a .modifier so you can fold it into any container view (.cardStyle(), .headingStyle()).

3 · Navigation & state parity
Your MainTabView matches the web’s top-level routes 
GitHub
.

Mirror React-Router lazy boundaries with SwiftUI’s .task inside each tab + @StateObject viewModel.

Use async/await + Observation in ViewModels to replicate TanStack Query’s “cache & re-validate”:

swift
Copy
Edit
@Observable class WorkoutHistoryVM {
    private let repo = WorkoutRepository()
    @MainActor @Published var history: [Workout] = []

    func load() async throws {
        if let cached = cache["history"] { history = cached }
        let fresh = try await repo.fetchHistory()
        history = fresh; cache["history"] = fresh
    }
}
Persist to SwiftData (already wired 
GitHub
) just like Web uses LocalStorage for initial hydration.

4 · API layer

Web analogue	iOS implementation
src/lib/api.ts fetch wrapper	NetworkService singleton with URLSession + URLCache (memory + disk).
react-query retries	URLSessionConfiguration.requestCachePolicy + custom retry decorator.
Encryption of tokens in LS	Keychain + App Groups so you can share with watchOS later.
Add a shared Swift package for DTOs (WorkoutDTO, LeaderboardEntryDTO) so macOS catalina builds and watchOS share the same layer.

5 · Styling perfection
Tab bar already themed via UITabBarAppearance 
GitHub
. Do the same for UINavigationBarAppearance so push stacks match.

Recreate Tailwind spacing scale with helper:

swift
Copy
Edit
enum Spacing { static let xs: CGFloat = 4; static let sm = 8; … }
Then .padding(Spacing.md) everywhere – reads like p-4 in Tailwind.

Charts – Use Apple’s Charts framework; you can port the olive mist / gridline gray scheme from the web area chart.

6 · The “pixel-check” loop
Create Figma → iOS tokens inspection mode (Plugin: Design Tokens).

Run SwiftUI snapshot tests (XCTAssert... .record = true) side-by-side with Chromatic for web.

Automate Fastlane screenshot on every branch to catch divergence.

7 · Next sprint starter issues
Token generator SPM plugin

Unified NetworkService (+Keychain refresh-token flow)

StatsCard & LeaderboardRow SwiftUI views

Charts prototype for Workout progress

RTL layout audit & accessibility pass





/ Package.swift – add this target and plugin at the root of your repo
// ------------------------------------------------------------------
// Add the following to the `targets` and `products` arrays:
// .plugin(name: "DesignTokenGenPlugin", targets: ["DesignTokenGenPlugin"]),
//
// .executableTarget(
//     name: "DesignTokenGenTool",
//     path: "Tools/DesignTokenGenTool"),
// .plugin(
//     name: "DesignTokenGenPlugin",
//     capability: .buildTool(),
//     dependencies: [
//         .target(name: "DesignTokenGenTool")
//     ]),
//
// Then attach the plugin to any target that needs the generated Swift file:
// .target(
//     name: "App",
//     plugins: [
//         .plugin(name: "DesignTokenGenPlugin")
//     ]),

// Folder layout
// ├─ Package.swift
// ├─ design-tokens.json          <-- produced by your Tailwind build
// ├─ Tools/
// │   └─ DesignTokenGenTool/
// │       ├─ main.swift          <-- decoding + generation logic
// └─ Plugins/
//     └─ DesignTokenGenPlugin.swift   <-- the SPM BuildTool plugin

// 1. Plugins/DesignTokenGenPlugin.swift
// -------------------------------------
import PackagePlugin
import Foundation

@main
struct DesignTokenGenPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // Locate the tool executable built from "DesignTokenGenTool"
        let tool = try context.tool(named: "DesignTokenGenTool")
        let toolPath = tool.path

        // Path to the JSON exported from Tailwind
        let jsonPath = context.package.directory.appending("design-tokens.json")

        // Output directory inside Plugin’s work dir
        let outputDir = context.pluginWorkDirectory.appending("Generated")
        try? FileManager.default.createDirectory(atPath: outputDir.string, withIntermediateDirectories: true)

        let outputFile = outputDir.appending("Theme.generated.swift")

        // Construct the command
        return [
            .buildCommand(
                displayName: "Generate SwiftUI theme from design‑tokens.json",
                executable: toolPath,
                arguments: [jsonPath, outputFile],
                environment: [:],
                outputFiles: [outputFile]
            )
        ]
    }
}

// 2. Tools/DesignTokenGenTool/main.swift
// --------------------------------------
// swift-tools-version:5.10
// Compile with: swift build -c release --product DesignTokenGenTool
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
    return "Color(red: \(r)/255, green: \(g)/255, blue: \(b)/255, opacity: \(a)/255)"
}

func generateSwift(_ tokens: TokenSet, path: URL) throws {
    var out = """
    // ⚠️ Auto‑generated file. Do not edit.
    import SwiftUI

    public enum Theme {
    """

    out += "\n    // MARK: Colors\n"
    for c in tokens.colors {
        out += "    public static let \(camel(c.name)) = \(hexToSwiftUIColor(c.value))\n"
    }

    out += "\n    // MARK: Spacing\n    public enum Spacing {\n"
    for s in tokens.spacing { out += "        public static let \(camel(s.name)) : CGFloat = \(s.value)\n" }
    out += "    }\n"

    out += "\n    // MARK: Corner Radius\n    public enum Radius {\n"
    for r in tokens.radius { out += "        public static let \(camel(r.name)) : CGFloat = \(r.value)\n" }
    out += "    }\n"

    out += "\n    // MARK: Font Size\n    public enum FontSize {\n"
    for f in tokens.fontSize { out += "        public static let \(camel(f.name)) : CGFloat = \(f.value)\n" }
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
