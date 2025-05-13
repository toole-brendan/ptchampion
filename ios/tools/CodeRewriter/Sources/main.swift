import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

// MARK: - Main Rewriter Class

/// Rewriter that handles multiple transformation types by chaining specialized rewriters
class StylingRewriter {
    /// Process a file at the given path
    /// - Parameter filePath: The path to the Swift file to process
    /// - Returns: true if any changes were made
    static func processFile(_ filePath: String) -> Bool {
        guard FileManager.default.fileExists(atPath: filePath) else {
            print("File not found: \(filePath)")
            return false
        }
        
        guard let sourceData = FileManager.default.contents(atPath: filePath) else {
            print("Failed to read file: \(filePath)")
            return false
        }
        
        guard let sourceString = String(data: sourceData, encoding: .utf8) else {
            print("Failed to decode file: \(filePath)")
            return false
        }

        // Parse the Swift file
        let sourceFile = Parser.parse(source: sourceString)
        
        // Apply the rewriters in sequence
        var modifiedSourceFile = sourceFile
        
        // 1. Apply PTCard rewriter
        let ptCardRewriter = PTCardRewriter()
        modifiedSourceFile = ptCardRewriter.visit(modifiedSourceFile)
        
        // 2. Apply typography rewriter
        let typographyRewriter = TypographyRewriter()
        modifiedSourceFile = typographyRewriter.visit(modifiedSourceFile)
        
        // 3. Apply container modifier rewriter
        let containerRewriter = ContainerRewriter()
        modifiedSourceFile = containerRewriter.visit(modifiedSourceFile)
        
        // Check if any changes were made
        let modifiedString = modifiedSourceFile.description
        let hasChanges = sourceString != modifiedString
        
        // Save the modified file if changes were made
        if hasChanges {
            do {
                try modifiedString.write(toFile: filePath, atomically: true, encoding: .utf8)
                print("✅ Modified: \(filePath)")
            } catch {
                print("Error writing file: \(error)")
                return false
            }
        }
        
        return hasChanges
    }
}

// MARK: - Specialized Rewriters

/// Rewriter that converts PTCard to .card() modifier
class PTCardRewriter: SyntaxRewriter {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // Check if this is a PTCard call
        guard let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
              identifierExpr.identifier.text == "PTCard" else {
            return super.visit(node)
        }
        
        // If it has a trailing closure, replace PTCard with VStack + card()
        if let trailingClosure = node.trailingClosure {
            // Create a new VStack with the same closure
            let vstack = FunctionCallExprSyntax(
                calledExpression: ExprSyntax(IdentifierExprSyntax(identifier: .identifier("VStack")),
                leftParen: .leftParenToken(),
                argumentList: LabeledExprListSyntax([]),
                rightParen: .rightParenToken(),
                trailingClosure: trailingClosure
            )
            
            // Add .card() modifier
            let cardModifier = MemberAccessExprSyntax(
                base: ExprSyntax(vstack),
                name: .identifier("card")
            )
            
            let cardCall = FunctionCallExprSyntax(
                calledExpression: ExprSyntax(cardModifier),
                leftParen: .leftParenToken(),
                argumentList: LabeledExprListSyntax([]),
                rightParen: .rightParenToken()
            )
            
            return ExprSyntax(cardCall)
        }
        
        return super.visit(node)
    }
}

/// Rewriter that fixes typography modifiers
class TypographyRewriter: SyntaxRewriter {
    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        let typographyMethods = ["heading1", "heading2", "heading3", "heading4", 
                               "heading5", "body", "bodySemibold", "caption", 
                               "small", "smallSemibold"]
        
        // Check if this is a typography method access
        if let baseExpr = node.base?.as(MemberAccessExprSyntax.self),
           let baseBase = baseExpr.base?.as(MemberAccessExprSyntax.self),
           baseBase.name.text == "GeneratedTypography",
           typographyMethods.contains(node.name.text) {
            
            // Create replacement with new typography modifier
            let newModifier = ".\(node.name.text)()"
            return ExprSyntax(stringLiteral: newModifier)
        }
        
        return super.visit(node)
    }
}

/// Rewriter that adds .container() to main view
class ContainerRewriter: SyntaxRewriter {
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        // Only process view types
        guard node.name.text.hasSuffix("View") else {
            return super.visit(node)
        }
        
        // Process the structure
        var modified = node
        
        // Find the body property
        if let members = node.memberBlock.members.first(where: { member in
            if let varDecl = member.decl.as(VariableDeclSyntax.self),
               let binding = varDecl.bindings.first,
               binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body" {
                return true
            }
            return false
        }) {
            // Check if it already has .container() modifier
            // This is a simplified check and would need to be more robust in practice
            let memberText = members.description
            if !memberText.contains(".container()") {
                // Add the container modifier
                // This is placeholder logic - would need more complex AST manipulation
                // to properly modify the existing view hierarchy
            }
        }
        
        return DeclSyntax(modified)
    }
}

// MARK: - Command Line Tool

// Simple command line processing
if CommandLine.arguments.count < 2 {
    print("Usage: CodeRewriter <file_paths...>")
    exit(1)
}

// Process each provided file
var filesModified = 0
for i in 1..<CommandLine.arguments.count {
    let filePath = CommandLine.arguments[i]
    if StylingRewriter.processFile(filePath) {
        filesModified += 1
    }
}

print("🚀 Rewriting complete! Modified \(filesModified) file(s)") 