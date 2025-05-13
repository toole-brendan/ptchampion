#!/bin/bash
# Script to build and run the SwiftSyntax-based rewriter
# This should be run from the repository root

set -e # Exit on error

cd ios/tools/CodeRewriter

echo "🔨 Building the CodeRewriter tool..."
swift build -c release

echo "🔍 Running the rewriter on Swift files..."
REWRITER_BINARY=.build/release/CodeRewriter

# Run on all Swift files in the project
find ../../ptchampion -name "*.swift" | xargs $REWRITER_BINARY

echo "✅ Code rewriting completed!"
echo
echo "Run the migration script to check the final status:"
echo "bash ios/complete_styling_migration.sh" 