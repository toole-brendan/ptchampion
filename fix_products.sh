#!/bin/bash

echo "=== Advanced Package Product Fix ==="

# Close Xcode
echo "1. Closing Xcode..."
killall Xcode 2>/dev/null || true
sleep 2

# Create PTDesignSystem package backup
echo "2. Backing up PTDesignSystem..."
cd /Users/brendantoole/projects/ptchampion/ios
cp -R PTDesignSystem PTDesignSystem.bak.$(date +%Y%m%d%H%M%S)

# Reset the Xcode project state
echo "3. Resetting Xcode project state..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/org.swift.swiftpm

# Create a direct file that adds imports for these packages
echo "4. Creating test import file to force package resolution..."
cd /Users/brendantoole/projects/ptchampion/ios/ptchampion
mkdir -p TestImports
cat > TestImports/PackageImports.swift << 'EOL'
import Foundation
import GoogleSignIn
import GoogleSignInSwift
import DesignTokens
import Components
import PTDesignSystem

// This file ensures all package products are properly imported
// It will not be included in the final app
func testImports() {
    // GoogleSignIn test
    let config = GIDConfiguration(clientID: "test_client_id")
    print("GoogleSignIn config: \(config)")
    
    // Design system test - just reference some types
    let _ = AppTheme.shared
}
EOL

# Manually fix the local package reference
echo "5. Fixing local package reference in the Xcode project..."
cd /Users/brendantoole/projects/ptchampion
cat > fix_local_package.rb << 'EOL'
require 'xcodeproj'

# Open the Xcode project
project_path = 'ios/ptchampion/ptchampion.xcodeproj'
puts "Opening project: #{project_path}"
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'ptchampion' }
if !target
  puts "ERROR: Target 'ptchampion' not found"
  exit 1
end

puts "Found target: #{target.name}"

# Remove any existing package product dependencies for our packages
existing_deps = target.package_product_dependencies
to_remove = []

existing_deps.each do |dep|
  if ['GoogleSignIn', 'GoogleSignInSwift', 'DesignTokens', 'Components', 'PTDesignSystem'].include?(dep.product_name)
    to_remove << dep
    puts "Marked for removal: #{dep.product_name}"
  end
end

to_remove.each do |dep|
  target.package_product_dependencies.delete(dep)
  puts "Removed dependency: #{dep.product_name}"
end

# Add the GoogleSignIn package
google_signin_repo = 'https://github.com/google/GoogleSignIn-iOS'
package_refs = project.root_object.package_references || []
google_signin_ref = nil

# Find or create Google Sign-In package reference
package_refs.each do |ref|
  if ref.respond_to?(:repositoryURL) && ref.repositoryURL == google_signin_repo
    google_signin_ref = ref
    puts "Found existing GoogleSignIn package reference"
    break
  end
end

if !google_signin_ref
  google_signin_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  google_signin_ref.repositoryURL = google_signin_repo
  google_signin_ref.requirement = { kind: 'upToNextMajorVersion', minimumVersion: '8.0.0' }
  project.root_object.package_references = (project.root_object.package_references || []) << google_signin_ref
  puts "Added GoogleSignIn package reference"
end

# Add GoogleSignIn product dependencies
gs_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
gs_dep.product_name = 'GoogleSignIn'
gs_dep.package = google_signin_ref
target.package_product_dependencies << gs_dep
puts "Added GoogleSignIn product dependency"

gs_swift_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
gs_swift_dep.product_name = 'GoogleSignInSwift'
gs_swift_dep.package = google_signin_ref
target.package_product_dependencies << gs_swift_dep
puts "Added GoogleSignInSwift product dependency"

# Add PTDesignSystem local package reference
puts "Looking for PTDesignSystem local package..."
design_system_path = '../PTDesignSystem'

# Check if the local package exists
pt_design_ref = nil
project.root_object.project_references.each do |ref|
  if ref[:project_ref] && ref[:project_ref].path && ref[:project_ref].path.include?('PTDesignSystem')
    pt_design_ref = ref[:project_ref]
    puts "Found existing PTDesignSystem reference: #{pt_design_ref.path}"
    break
  end
end

if !pt_design_ref
  puts "Creating PTDesignSystem local package reference..."
  pt_design_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  pt_design_ref.path = design_system_path
  
  # Add to project references
  new_ref = {
    group_ref: nil,
    project_ref: pt_design_ref
  }
  project.root_object.project_references = (project.root_object.project_references || []) << new_ref
  puts "Added PTDesignSystem local package reference"
end

# Add PTDesignSystem product dependencies
dt_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
dt_dep.product_name = 'DesignTokens'
dt_dep.package = pt_design_ref
target.package_product_dependencies << dt_dep
puts "Added DesignTokens product dependency"

comp_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
comp_dep.product_name = 'Components'
comp_dep.package = pt_design_ref
target.package_product_dependencies << comp_dep
puts "Added Components product dependency"

pt_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
pt_dep.product_name = 'PTDesignSystem'
pt_dep.package = pt_design_ref
target.package_product_dependencies << pt_dep
puts "Added PTDesignSystem product dependency"

# Save the project
project.save
puts "Project saved successfully"
EOL

# Install xcodeproj gem if needed
gem list -i xcodeproj || sudo gem install xcodeproj

# Run the fix script
ruby fix_local_package.rb

# Fix the workspace
echo "6. Fixing workspace file..."
cat > ptchampion.xcworkspace/contents.xcworkspacedata << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "absolute:ios/ptchampion/ptchampion.xcodeproj">
   </FileRef>
   <FileRef
      location = "absolute:ios/ptchampion/Pods/Pods.xcodeproj">
   </FileRef>
   <FileRef
      location = "absolute:ios/PTDesignSystem">
   </FileRef>
</Workspace>
EOL

# Clear "Clear Package Cache" script that's causing warnings
echo "7. Removing/fixing 'Clear Package Cache' build phase..."
cat > fix_clear_cache_script.rb << 'EOL'
require 'xcodeproj'

project_path = 'ios/ptchampion/ptchampion.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'ptchampion' }
if target
  # Find the Clear Package Cache script
  clear_cache_phase = target.build_phases.find do |phase|
    phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && 
    phase.name == 'Clear Package Cache'
  end
  
  if clear_cache_phase
    # Either remove it or fix it by setting output paths
    # Option 1: Remove it
    # target.build_phases.delete(clear_cache_phase)
    # puts "Removed 'Clear Package Cache' build phase"
    
    # Option 2: Fix it by adding output paths and turning off dependency analysis
    clear_cache_phase.output_paths = ["$(DERIVED_FILE_DIR)/package-cache-cleaned"]
    clear_cache_phase.always_out_of_date = true
    puts "Fixed 'Clear Package Cache' build phase with output paths"
  else
    puts "No 'Clear Package Cache' build phase found"
  end
  
  project.save
  puts "Project saved successfully"
else
  puts "ERROR: Target 'ptchampion' not found"
end
EOL

ruby fix_clear_cache_script.rb

# Open Xcode with the workspace
echo "8. Opening Xcode workspace..."
open -a Xcode /Users/brendantoole/projects/ptchampion/ptchampion.xcworkspace

echo ""
echo "Fix completed! If you still see issues, try these manual steps in Xcode:"
echo "1. Select the ptchampion project in the navigator"
echo "2. Go to the 'Build Phases' tab"
echo "3. Find the 'Clear Package Cache' script and check 'Run script only when installing'"
echo "4. Clean the build folder (Shift+Cmd+K)"
echo "5. Build the project (Cmd+B)" 