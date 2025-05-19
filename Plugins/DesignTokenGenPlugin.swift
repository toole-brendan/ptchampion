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

        // Output directory inside Plugin's work dir
        let outputDir = context.pluginWorkDirectory.appending("Generated")
        try? FileManager.default.createDirectory(atPath: outputDir.string, withIntermediateDirectories: true)

        let outputFile = outputDir.appending("Theme.generated.swift")

        // Construct the command
        return [
            .buildCommand(
                displayName: "Generate SwiftUI theme from design‑tokens.json",
                executable: toolPath,
                arguments: [jsonPath.string, outputFile.string],
                environment: [:],
                outputFiles: [outputFile]
            )
        ]
    }
} 