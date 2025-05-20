#!/bin/bash

# Define variables
WORKSPACE="/Users/brendantoole/projects/ptchampion/ptchampion.xcworkspace"

# Copy the package URL to clipboard for ease of use
echo "https://github.com/google/GoogleSignIn-iOS" | pbcopy
echo "Opening Xcode. Please add the Google SignIn package manually:"
echo "1. In Xcode, go to File > Add Packages..."
echo "2. Paste the URL already copied to clipboard: https://github.com/google/GoogleSignIn-iOS"
echo "3. Choose version 8.0.0"
echo "4. Add to the ptchampion target"

# Open Xcode with the workspace
open -a Xcode "$WORKSPACE"

echo "After adding the package in Xcode:"
echo "1. Make sure to select Up to Next Major Version (8.0.0)"
echo "2. Add to ptchampion target"
echo "3. Build the project (⌘+B) to verify integration" 