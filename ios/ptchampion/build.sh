#!/bin/bash

# Force remove old provisioning profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/* 2>/dev/null
rm -rf ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/* 2>/dev/null

# Clean build folder
xcodebuild clean -project ptchampion.xcodeproj -scheme ptchampion

# Build with explicit entitlements file
xcodebuild build \
  -project ptchampion.xcodeproj \
  -scheme ptchampion \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Apple Development: Brendan Toole (2289U4M489)" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  OTHER_CODE_SIGN_FLAGS="--entitlements $(pwd)/ptchampion.entitlements" 