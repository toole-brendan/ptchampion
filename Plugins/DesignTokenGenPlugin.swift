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
        
        // Path to the web parity JSON file
        let webParityJsonPath = context.package.directory.appending("design-tokens/web-parity.json")

        // Output directory inside Plugin's work dir
        let outputDir = context.pluginWorkDirectory.appending("Generated")
        try? FileManager.default.createDirectory(atPath: outputDir.string, withIntermediateDirectories: true)

        // Output files
        let outputFile = outputDir.appending("Theme.generated.swift")
        let webParityOutputFile = outputDir.appending("AppTheme+Generated.swift")

        // Construct the command for original theme
        let originalCommand = Command.buildCommand(
            displayName: "Generate SwiftUI theme from design‑tokens.json",
            executable: toolPath,
            arguments: [jsonPath.string, outputFile.string],
            environment: [:],
            outputFiles: [outputFile]
        )
        
        // Check if web parity file exists
        if FileManager.default.fileExists(atPath: webParityJsonPath.string) {
            // Construct the command for web parity
            let webParityCommand = Command.buildCommand(
                displayName: "Generate iOS theme from web-parity.json",
                executable: toolPath,
                arguments: [webParityJsonPath.string, webParityOutputFile.string, "--web-parity"],
                environment: [:],
                outputFiles: [webParityOutputFile]
            )
            
            return [originalCommand, webParityCommand]
        } else {
            return [originalCommand]
        }
    }
} 