#!/bin/bash
# Enhanced Fix for PT Champion Xcode Project Error - v2
# Comprehensive script to repair the damaged Xcode project file

# Path variables
PROJECT_DIR="/Users/brendantoole/projects/ptchampion"
PROJECT_FILE="$PROJECT_DIR/ios/ptchampion/ptchampion.xcodeproj/project.pbxproj"
BACKUP_FILE="$PROJECT_DIR/ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.v2.backup"
TEMP_FILE="/tmp/project.pbxproj.temp"

# Make sure we're in the right directory
cd "$PROJECT_DIR" || { echo "Error: Cannot find project directory"; exit 1; }

# Backup the current file
echo "Backing up current project file to $BACKUP_FILE"
cp "$PROJECT_FILE" "$BACKUP_FILE"

echo "Performing comprehensive repair of the project file..."

# Step 1: Extract all UUIDs for proper reference checks
echo "Extracting metadata and UUIDs..."
FONTS_GROUP_UUID="BF90A0002DBAF50000000000"
COPY_FONTS_SCRIPT_UUID="BF90A0072DBAF50000000007"
MAIN_TARGET_UUID="BF63E3B82DB1C84E0037CD02"

# Step 2: Create a clean definition for the PBXShellScriptBuildPhase
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

# Create the clean Fonts group definition
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

# Create consistent font file references
cat > /tmp/fix_font_references.txt << 'EOF'
		BF90A0012DBAF50000000001 /* BebasNeue-Bold.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; name = "BebasNeue-Bold.ttf"; path = "Resources/Fonts/BebasNeue-Bold.ttf"; sourceTree = "<group>"; };
		BF90A0022DBAF50000000002 /* Montserrat-Regular.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; name = "Montserrat-Regular.ttf"; path = "Resources/Fonts/Montserrat-Regular.ttf"; sourceTree = "<group>"; };
		BF90A0032DBAF50000000003 /* Montserrat-Bold.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; name = "Montserrat-Bold.ttf"; path = "Resources/Fonts/Montserrat-Bold.ttf"; sourceTree = "<group>"; };
		BF90A0042DBAF50000000004 /* Montserrat-SemiBold.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; name = "Montserrat-SemiBold.ttf"; path = "Resources/Fonts/Montserrat-SemiBold.ttf"; sourceTree = "<group>"; };
		BF90A0052DBAF50000000005 /* RobotoMono-Bold.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; name = "RobotoMono-Bold.ttf"; path = "Resources/Fonts/RobotoMono-Bold.ttf"; sourceTree = "<group>"; };
		BF90A0062DBAF50000000006 /* RobotoMono-Medium.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; name = "RobotoMono-Medium.ttf"; path = "Resources/Fonts/RobotoMono-Medium.ttf"; sourceTree = "<group>"; };
		BF90A0072DBAF50000000007 /* CopyFonts.sh */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.script.sh; path = CopyFonts.sh; sourceTree = "<group>"; };
EOF

# Step 3: Make a complete pass through the file to clean up any references
echo "Performing comprehensive cleanup of project file..."

# Cleanup pass 1: Fix font reference definitions in PBXFileReference section
awk '
BEGIN { in_file_reference = 0; fonts_fixed = 0; }

/\/\* Begin PBXFileReference section \*\// {
    in_file_reference = 1;
    print;
    
    # Add all font file references right after the PBXFileReference section starts
    if (!fonts_fixed) {
        system("cat /tmp/fix_font_references.txt");
        fonts_fixed = 1;
    }
    next;
}

/\/\* End PBXFileReference section \*\// {
    in_file_reference = 0;
    print;
    next;
}

# Skip existing font references while in the PBXFileReference section
in_file_reference && /BF90A00[0-7]2DBAF5000000000[0-7]/ {
    # Skip these lines as we already added the correct ones
    next;
}

# Print everything else
{ print; }
' "$PROJECT_FILE" > "$TEMP_FILE"

cp "$TEMP_FILE" "$PROJECT_FILE"

# Cleanup pass 2: Fix the PBXShellScriptBuildPhase section
awk '
BEGIN { in_script_phase = 0; phase_fixed = 0; }

/\/\* Begin PBXShellScriptBuildPhase section \*\// {
    in_script_phase = 1;
    print;
    
    # Replace with our fixed copy fonts script phase
    if (!phase_fixed) {
        system("cat /tmp/fix_shell_script_phase.txt | grep -v \"Begin PBXShellScriptBuildPhase\" | grep -v \"End PBXShellScriptBuildPhase\"");
        phase_fixed = 1;
    }
    next;
}

/\/\* End PBXShellScriptBuildPhase section \*\// {
    in_script_phase = 0;
    print;
    next;
}

# Skip everything within the script phase section as we already output the fixed version
in_script_phase {
    next;
}

# Skip any incorrect shell script phase definitions outside their section
/BF90A0072DBAF50000000007.*=.*{/ && !/PBXFileReference/ {
    if (!/isa = PBXShellScriptBuildPhase/) {
        # Skip corrupted shell script definitions 
        next;
    }
}

# Print everything else
{ print; }
' "$PROJECT_FILE" > "$TEMP_FILE"

cp "$TEMP_FILE" "$PROJECT_FILE"

# Cleanup pass 3: Fix the Font group definition 
awk '
BEGIN { in_font_group = 0; group_fixed = 0; }

/BF90A0002DBAF50000000000 \/\* Fonts \*\/ = {/ {
    in_font_group = 1;
    if (!group_fixed) {
        system("cat /tmp/fix_font_group.txt");
        group_fixed = 1;
    }
    next;
}

in_font_group && /};/ {
    in_font_group = 0;
    next;
}

in_font_group {
    # Skip everything in the corrupted font group
    next;
}

# Print everything else
{ print; }
' "$PROJECT_FILE" > "$TEMP_FILE"

cp "$TEMP_FILE" "$PROJECT_FILE"

# Cleanup pass 4: Ensure the Copy Fonts build phase is correctly in the target's buildPhases
awk '
BEGIN { in_build_phases = 0; fonts_added = 0; }

/('"$MAIN_TARGET_UUID"'.*buildPhases = \()/ {
    in_build_phases = 1;
    print;
    next;
}

in_build_phases && /\);/ {
    # If we havent added the Copy Fonts phase yet, add it before the closing parenthesis
    if (!fonts_added) {
        print "\t\t\t\tBF90A0072DBAF50000000007 /* Copy Fonts */,";
        fonts_added = 1;
    }
    print;
    in_build_phases = 0;
    next;
}

in_build_phases && /BF90A0072DBAF50000000007/ {
    # If it already exists, mark it as added
    fonts_added = 1;
    print;
    next;
}

# Print everything else
{ print; }
' "$PROJECT_FILE" > "$TEMP_FILE"

cp "$TEMP_FILE" "$PROJECT_FILE"

# Cleanup pass 5: Final pass to catch anything that might reference the Copy Fonts build phase incorrectly
awk '
# Skip any group methods being called on the PBXShellScriptBuildPhase
/\[PBXShellScriptBuildPhase group\]/ {
    next;
}

# Print everything else
{ print; }
' "$PROJECT_FILE" > "$TEMP_FILE"

cp "$TEMP_FILE" "$PROJECT_FILE"

# Clean up temporary files
rm -f /tmp/fix_shell_script_phase.txt
rm -f /tmp/fix_font_group.txt
rm -f /tmp/fix_font_references.txt
rm -f "$TEMP_FILE"

echo "Enhanced project repair complete. The project file should now be fixed."
echo "If issues persist, restore the backup with: cp $BACKUP_FILE $PROJECT_FILE" 