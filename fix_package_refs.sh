#!/bin/bash

echo "Fixing package resolution issues..."

# 1. Close Xcode
echo "1. Closing Xcode..."
killall Xcode 2>/dev/null || true
sleep 2

# 2. Create a backup of the workspace
echo "2. Creating backup of workspace..."
cp -a /Users/brendantoole/projects/ptchampion/ptchampion.xcworkspace /Users/brendantoole/projects/ptchampion/ptchampion.xcworkspace.backup.$(date +%Y%m%d%H%M%S)

# 3. Fix the workspace file with correct paths
echo "3. Updating workspace with correct package references..."
cat > /Users/brendantoole/projects/ptchampion/ptchampion.xcworkspace/contents.xcworkspacedata << 'EOL'
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

# 4. Clean derived data (which contains package build artifacts)
echo "4. Cleaning package caches and derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/org.swift.swiftpm

# 5. Create a reset package state file
echo "5. Resetting package state..."
mkdir -p /Users/brendantoole/projects/ptchampion/ptchampion.xcworkspace/xcshareddata/swiftpm/
cat > /Users/brendantoole/projects/ptchampion/ptchampion.xcworkspace/xcshareddata/swiftpm/Package.resolved << 'EOL'
{
  "pins" : [
    {
      "identity" : "appauthcore",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/openid/AppAuth-iOS.git",
      "state" : {
        "revision" : "71c8c3081bf2fdb3031a411f36483b54cdeaed99",
        "version" : "1.7.6"
      }
    },
    {
      "identity" : "app-check",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/google/app-check.git",
      "state" : {
        "revision" : "a5cc162e1628b99d2f538c0b74b0179dfc7e6d32",
        "version" : "10.21.0"
      }
    },
    {
      "identity" : "googlesignin-ios",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/google/GoogleSignIn-iOS",
      "state" : {
        "revision" : "8a7ec2e91830fa1d5a7d981092ae1bfbd0b67a51",
        "version" : "8.0.0"
      }
    },
    {
      "identity" : "googleutilities",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/google/GoogleUtilities.git",
      "state" : {
        "revision" : "bc27fad73504f3d4af235de451f02ee22586ebd3",
        "version" : "7.12.1"
      }
    },
    {
      "identity" : "gtmappauth",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/google/GTMAppAuth.git",
      "state" : {
        "revision" : "10c1a50d8ddde805422e30c21cd4554e89a6f141",
        "version" : "4.1.1"
      }
    },
    {
      "identity" : "gtm-session-fetcher",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/google/gtm-session-fetcher.git",
      "state" : {
        "revision" : "76135c9f4e1ac85459d5fec61b6f76ac47ab3a4c",
        "version" : "3.3.1"
      }
    },
    {
      "identity" : "mediapipe",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/google/mediapipe.git",
      "state" : {
        "revision" : "6303f2d3ca9a10276a566682792bdce03960e24b",
        "version" : "0.10.8"
      }
    },
    {
      "identity" : "promises",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/google/promises.git",
      "state" : {
        "revision" : "540318ecedd63d883069ae7f1ed811a2df00b6ac",
        "version" : "2.4.0"
      }
    },
    {
      "identity" : "swiftui-introspect",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/siteline/SwiftUI-Introspect.git",
      "state" : {
        "revision" : "121c146fe591b1320238d054ae35c81ffa45f45a",
        "version" : "1.0.0"
      }
    }
  ],
  "version" : 2
}
EOL

# 6. Fix the Xcode project to correctly reference packages
echo "6. Fix GoogleSignIn package references in the project..."
cd /Users/brendantoole/projects/ptchampion/ios/ptchampion
cat > fix_project.rb << 'EOL'
require 'xcodeproj'

project_path = 'ptchampion.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'ptchampion' }

if target
  puts "Found target: #{target.name}"
  
  # Clear out problematic package references
  bad_deps = target.package_product_dependencies.select do |dep|
    dep.product_name == 'GoogleSignIn' || 
    dep.product_name == 'GoogleSignInSwift' || 
    dep.product_name == 'Components' || 
    dep.product_name == 'DesignTokens' || 
    dep.product_name == 'PTDesignSystem'
  end
  
  bad_deps.each do |dep|
    target.package_product_dependencies.delete(dep)
    puts "Removed problematic dependency: #{dep.product_name}"
  end

  # Add packages back properly
  package_refs = project.root_object.package_references
  
  # Find or add GoogleSignIn package
  google_signin_repo = 'https://github.com/google/GoogleSignIn-iOS'
  google_signin_ref = package_refs.find { |ref| ref.repositoryURL == google_signin_repo }
  
  if !google_signin_ref
    google_signin_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
    google_signin_ref.repositoryURL = google_signin_repo
    google_signin_ref.requirement = { kind: 'upToNextMajorVersion', minimumVersion: '8.0.0' }
    package_refs << google_signin_ref
    puts "Added GoogleSignIn package reference"
  end
  
  # Add product dependencies
  dep1 = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep1.product_name = 'GoogleSignIn'
  dep1.package = google_signin_ref
  target.package_product_dependencies << dep1
  puts "Added GoogleSignIn product"
  
  dep2 = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep2.product_name = 'GoogleSignInSwift'
  dep2.package = google_signin_ref
  target.package_product_dependencies << dep2
  puts "Added GoogleSignInSwift product"
  
  # Find PT Design System reference
  pt_design_ref = project.root_object.file_references.find { |ref| ref.path.to_s.end_with?('PTDesignSystem') }
  
  if pt_design_ref
    puts "Found PTDesignSystem reference at: #{pt_design_ref.path}"
    
    # Add DesignTokens dependency
    dep3 = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dep3.product_name = 'DesignTokens'
    dep3.package = pt_design_ref
    target.package_product_dependencies << dep3
    puts "Added DesignTokens product"
    
    # Add Components dependency
    dep4 = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dep4.product_name = 'Components'
    dep4.package = pt_design_ref
    target.package_product_dependencies << dep4
    puts "Added Components product"
    
    # Add PTDesignSystem dependency
    dep5 = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dep5.product_name = 'PTDesignSystem'
    dep5.package = pt_design_ref
    target.package_product_dependencies << dep5
    puts "Added PTDesignSystem product"
  else
    puts "WARNING: Could not find PTDesignSystem reference"
  end
else
  puts "ERROR: Could not find target 'ptchampion'"
end

project.save
puts "Project saved successfully"
EOL

# Install xcodeproj gem if needed
gem list -i xcodeproj || sudo gem install xcodeproj

# Run the fix script
ruby fix_project.rb

# 7. Fix duplicate font resources (optional)
echo "7. Fixing duplicate font resources..."
cat > fix_duplicate_fonts.rb << 'EOL'
require 'xcodeproj'

project_path = 'ptchampion.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'ptchampion' }
if target
  # Get the copy resources build phase
  copy_phase = target.build_phases.find { |phase| phase.is_a?(Xcodeproj::Project::Object::PBXResourcesBuildPhase) }
  
  if copy_phase
    # Find duplicate font files
    font_files = {}
    
    copy_phase.files.each do |file|
      if file.file_ref && file.file_ref.path && file.file_ref.path.end_with?('.ttf')
        font_name = File.basename(file.file_ref.path)
        font_files[font_name] ||= []
        font_files[font_name] << file
      end
    end
    
    # Remove duplicates
    font_files.each do |font_name, files|
      if files.length > 1
        # Keep the first occurrence, remove the rest
        files[1..-1].each do |file|
          copy_phase.files.delete(file)
          puts "Removed duplicate font file: #{font_name}"
        end
      end
    end
    
    project.save
    puts "Fixed duplicate font files"
  end
end
EOL

ruby fix_duplicate_fonts.rb

# 8. Open Xcode with the workspace
echo "8. Opening Xcode with the fixed workspace..."
open -a Xcode /Users/brendantoole/projects/ptchampion/ptchampion.xcworkspace

echo "Fix completed. Xcode should now be able to resolve packages properly."
echo "If you still see issues, try building the project (⌘+B) in Xcode." 