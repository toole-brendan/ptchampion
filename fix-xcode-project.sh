#!/bin/bash
# Fix for PT Champion Xcode Project Error
# Script to repair the damaged Xcode project file

# Path variables - adjust if your paths are different
PROJECT_DIR="/Users/brendantoole/projects/ptchampion"
PROJECT_FILE="$PROJECT_DIR/ios/ptchampion/ptchampion.xcodeproj/project.pbxproj"
BACKUP_FILE="$PROJECT_DIR/ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.fixed.backup"
TEMP_FILE="/tmp/project.pbxproj.temp"

# Make sure we're in the right directory
cd "$PROJECT_DIR" || { echo "Error: Cannot find project directory"; exit 1; }

# Backup the current file (even though it's damaged)
echo "Backing up current project file to $BACKUP_FILE"
cp "$PROJECT_FILE" "$BACKUP_FILE"

# Identify the issue: 
# The error suggests a PBXShellScriptBuildPhase is incorrectly being treated as a PBXGroup
# There's likely a mix-up between the "Copy Fonts" build phase and the "Fonts" group
echo "Fixing the damaged project file..."

# Extract and fix the problematic section using direct file operations
# Instead of using complex sed commands that differ between GNU and BSD

# First, let's create a correct PBXShellScriptBuildPhase section
cat > /tmp/fix_shell_script_phase.txt << 'EOF'
/* Begin PBXShellScriptBuildPhase section */
		BF90A0072DBAF50000000007 /* Copy Fonts */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputFileListPaths = (
			);
			inputPaths = (
				"$(SRCROOT)/Resources/Fonts",
			);
			name = "Copy Fonts";
			outputFileListPaths = (
			);
			outputPaths = (
				"$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/BebasNeue-Bold.ttf",
				"$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/Montserrat-Regular.ttf",
				"$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/Montserrat-Bold.ttf",
				"$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/Montserrat-SemiBold.ttf",
				"$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/RobotoMono-Bold.ttf",
				"$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/RobotoMono-Medium.ttf",
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "# Copy font files to the app bundle\nFONTS_DIR=\"${SRCROOT}/Resources/Fonts\"\nDEST_DIR=\"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}\"\n\necho \"Copying fonts from ${FONTS_DIR} to ${DEST_DIR}\"\nmkdir -p \"${DEST_DIR}\"\n\n# Check if source dir exists\nif [ -d \"${FONTS_DIR}\" ]; then\n  /bin/cp -f \"${FONTS_DIR}\"/*.ttf \"${DEST_DIR}/\"\n  /bin/cp -f \"${FONTS_DIR}\"/*.otf \"${DEST_DIR}/\" 2>/dev/null || :\nelse \n  echo \"warning: Font source directory not found: ${FONTS_DIR}\"\nfi\n";
		};
/* End PBXShellScriptBuildPhase section */
EOF

# Create the correct Fonts group definition
cat > /tmp/fix_font_group.txt << 'EOF'
		BF90A0002DBAF50000000000 /* Fonts */ = {
			isa = PBXGroup;
			children = (
				BF90A0012DBAF50000000001 /* BebasNeue-Bold.ttf */,
				BF90A0022DBAF50000000002 /* Montserrat-Regular.ttf */,
				BF90A0032DBAF50000000003 /* Montserrat-Bold.ttf */,
				BF90A0042DBAF50000000004 /* Montserrat-SemiBold.ttf */,
				BF90A0052DBAF50000000005 /* RobotoMono-Bold.ttf */,
				BF90A0062DBAF50000000006 /* RobotoMono-Medium.ttf */,
			);
			path = Fonts;
			sourceTree = "<group>";
		};
EOF

# A more direct approach - manually fix each problematic section
# Part 1: Add the build phase to the target properly
# This is a multi-step approach using temporary files and standard file operations

# First, replace the PBXShellScriptBuildPhase section if it exists
if grep -q "Begin PBXShellScriptBuildPhase section" "$PROJECT_FILE"; then
    # Use awk to perform the replacement
    awk '
    /\/\* Begin PBXShellScriptBuildPhase section \*\//{
        found=1
        print "/* Begin PBXShellScriptBuildPhase section */"
        system("cat /tmp/fix_shell_script_phase.txt | grep -v \"Begin PBXShellScriptBuildPhase\" | grep -v \"End PBXShellScriptBuildPhase\"")
        next
    }
    /\/\* End PBXShellScriptBuildPhase section \*\//{
        found=0
        print "/* End PBXShellScriptBuildPhase section */"
        next
    }
    found!=1{print}
    ' "$PROJECT_FILE" > "$TEMP_FILE"
    
    cp "$TEMP_FILE" "$PROJECT_FILE"
else
    # Add the section before End XCConfigurationList section
    awk '
    /\/\* End XCConfigurationList section \*\//{
        system("cat /tmp/fix_shell_script_phase.txt")
        print
        next
    }
    {print}
    ' "$PROJECT_FILE" > "$TEMP_FILE"
    
    cp "$TEMP_FILE" "$PROJECT_FILE"
fi

# Part 2: Ensure the Copy Fonts build phase is in the target's buildPhases
# We'll use a more direct grep and awk approach
if ! grep -q "BF90A0072DBAF50000000007 /\\* Copy Fonts \\*/" "$PROJECT_FILE"; then
    # Need to add it to the build phases
    awk '
    /buildPhases = \(/ {
        inBuildPhases = 1
        print
        next
    }
    inBuildPhases==1 && /\);/ {
        # Before the closing parenthesis, add our build phase
        print "\t\t\t\tBF90A0072DBAF50000000007 /* Copy Fonts */,"
        print
        inBuildPhases = 0
        next
    }
    {print}
    ' "$PROJECT_FILE" > "$TEMP_FILE"
    
    cp "$TEMP_FILE" "$PROJECT_FILE"
fi

# Part 3: Fix the Fonts group definition
awk '
/BF90A0002DBAF50000000000 \/\* Fonts \*\/ = \{/ {
    inFontGroup = 1
    system("cat /tmp/fix_font_group.txt")
    next
}
inFontGroup==1 && /\};/ {
    inFontGroup = 0
    next
}
inFontGroup!=1 {print}
' "$PROJECT_FILE" > "$TEMP_FILE"

cp "$TEMP_FILE" "$PROJECT_FILE"

# Part 4: Fix any incorrect references to BF90A0072DBAF50000000007
# Ensure it's correctly defined as a PBXFileReference where needed
awk '
/BF90A0072DBAF50000000007 \/\* CopyFonts\.sh \*\/ = \{/ {
    print "BF90A0072DBAF50000000007 /* CopyFonts.sh */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.script.sh; path = CopyFonts.sh; sourceTree = \"<group>\";"
    inCopyFontsRef = 1
    next
}
inCopyFontsRef==1 && /\};/ {
    print "};"
    inCopyFontsRef = 0
    next
}
inCopyFontsRef!=1 {print}
' "$PROJECT_FILE" > "$TEMP_FILE"

cp "$TEMP_FILE" "$PROJECT_FILE"

# Clean up temporary files
rm -f /tmp/fix_shell_script_phase.txt
rm -f /tmp/fix_font_group.txt
rm -f "$TEMP_FILE"

echo "Project file has been fixed. You can now open it in Xcode."
echo "If the issue persists, restore the original with: cp $BACKUP_FILE $PROJECT_FILE" 