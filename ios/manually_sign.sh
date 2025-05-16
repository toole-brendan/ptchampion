#!/bin/bash

# Path to the project file
PROJECT_FILE="ptchampion/ptchampion.xcodeproj/project.pbxproj"

# Backup the project file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

# Modify the project file to use manual signing
perl -i -pe 's/ProvisioningStyle = Automatic;/ProvisioningStyle = Manual;/g' "$PROJECT_FILE"

# Set development team explicitly
perl -i -pe 's/DEVELOPMENT_TEAM = "";/DEVELOPMENT_TEAM = "6DKP9BK9LF";/g' "$PROJECT_FILE"

# Set CODE_SIGN_IDENTITY if needed
perl -i -pe 's/CODE_SIGN_IDENTITY = ".*";/CODE_SIGN_IDENTITY = "Apple Development: Brendan Toole (2289U4M489)";/g' "$PROJECT_FILE"

echo "Modified project to use manual signing. Open Xcode and set the provisioning profile manually."
echo "Original project file backed up to: ${PROJECT_FILE}.backup" 