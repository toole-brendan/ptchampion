#!/bin/bash
# Create a backup of the original workspace
cp -a ptchampion.xcworkspace ptchampion.xcworkspace.bak

# Create a new workspace file with the correct path
cat > ptchampion.xcworkspace/contents.xcworkspacedata << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:ios/ptchampion/ptchampion.xcodeproj">
   </FileRef>
   <FileRef
      location = "group:ios/ptchampion/Pods/Pods.xcodeproj">
   </FileRef>
   <FileRef
      location = "group:ios/PTDesignSystem">
   </FileRef>
</Workspace>
EOL

echo "Workspace file updated with correct paths" 