#!/bin/bash
# Build script for compiling the grading package to WebAssembly using TinyGo
# Usage: ./scripts/build_wasm.sh

set -e

# Ensure we're in the project root
cd "$(dirname "$0")/.."

# Ensure needed directories exist
mkdir -p web/public/wasm
mkdir -p android/app/src/main/assets
mkdir -p ios/ptchampion/Resources

echo "Building WASM module with TinyGo..."

# Check if TinyGo is installed
if ! command -v tinygo &> /dev/null; then
    echo "Error: TinyGo is not installed or not in PATH."
    echo "Please install TinyGo: https://tinygo.org/getting-started/install/"
    exit 1
fi

# Build the WASM module
tinygo build -o web/public/wasm/grading.wasm -target wasm ./cmd/wasm

# Also build with WASI target for Android/iOS
tinygo build -o web/public/wasm/grading_wasi.wasm -target wasi ./cmd/wasm

echo "WASM build complete."

# Copy the WASM files to platform-specific directories
echo "Copying WASM module to platform directories..."

cp web/public/wasm/grading.wasm android/app/src/main/assets/
cp web/public/wasm/grading_wasi.wasm ios/ptchampion/Resources/grading.wasm

echo "Done!"

# Provide instructions for next steps
echo ""
echo "Next steps:"
echo "1. For web integration, import the gradingWasm.ts module in your components:"
echo "   import gradingWasm from '../lib/gradingWasm';"
echo ""
echo "2. For Android, ensure the Wasmtime dependency is added to build.gradle.kts:"
echo "   implementation(\"org.wasmtime:wasmtime-java:0.2.0\")"
echo ""
echo "3. For iOS, install the Wasmer-Swift package in Xcode:"
echo "   https://github.com/wasmerio/wasmer-swift"
echo "" 