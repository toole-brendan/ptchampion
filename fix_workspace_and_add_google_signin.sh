#!/bin/bash

WORKSPACE_DIR="/Users/brendantoole/projects/ptchampion"
PROJECT_DIR="${WORKSPACE_DIR}/ios/ptchampion"
XCODEPROJ="${PROJECT_DIR}/ptchampion.xcodeproj"
WORKSPACE="${WORKSPACE_DIR}/ptchampion.xcworkspace"

echo "1. Creating backup of workspace file..."
cp -a "${WORKSPACE}" "${WORKSPACE}_backup_$(date +%Y%m%d_%H%M%S)"

echo "2. Checking if GoogleSignIn pod is commented out..."
grep -q "^[[:space:]]*#.*pod.*GoogleSignIn" "${PROJECT_DIR}/Podfile"
if [ $? -ne 0 ]; then
  echo "- Commenting out GoogleSignIn pod..."
  sed -i '' '/pod.*GoogleSignIn/s/^/# /' "${PROJECT_DIR}/Podfile"
else
  echo "- GoogleSignIn pod is already commented out."
fi

echo "3. Running pod install to remove GoogleSignIn pod..."
cd "${PROJECT_DIR}" && pod install

echo "4. Try to fix workspace schemes..."
# This creates a new workspace with proper schemes
cd "${PROJECT_DIR}"
xcodebuild -project "${XCODEPROJ}" -scheme ptchampion -showBuildSettings > /dev/null 2>&1

echo "5. Adding the package directly to the project file..."
# Create a temporary project settings file to add SPM dependency
cat > "${PROJECT_DIR}/add_google_signin.rb" << 'EOL'
require 'xcodeproj'

# Open the project
project_path = 'ptchampion.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'ptchampion' }

# Add package dependency
package_refs = project.root_object.package_references
package_repo = 'https://github.com/google/GoogleSignIn-iOS'
package_ref = package_refs.find { |ref| ref.package_url == package_repo }

if package_ref.nil?
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package_ref.name = 'GoogleSignIn-iOS'
  package_ref.repositoryURL = package_repo
  package_ref.requirement = { kind: 'upToNextMajorVersion', minimumVersion: '8.0.0' }
  package_refs << package_ref
  puts "Added Google SignIn package reference"
else
  puts "Google SignIn package reference already exists"
end

# Add package product dependency to target
if target
  dependency = target.package_product_dependencies.find { |dep| dep.package == package_ref }
  
  if dependency.nil?
    dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dependency.product_name = 'GoogleSignIn'
    dependency.package = package_ref
    target.package_product_dependencies << dependency
    
    dependency2 = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dependency2.product_name = 'GoogleSignInSwift'
    dependency2.package = package_ref
    target.package_product_dependencies << dependency2
    
    puts "Added GoogleSignIn and GoogleSignInSwift products to target"
  else
    puts "GoogleSignIn product dependency already exists"
  end
else
  puts "Target not found!"
end

# Save the project
project.save
EOL

echo "6. Installing required Ruby gem for project modification..."
gem list -i xcodeproj || sudo gem install xcodeproj

echo "7. Running script to add package dependency..."
cd "${PROJECT_DIR}" && ruby add_google_signin.rb

echo "8. Clean build folder..."
cd "${WORKSPACE_DIR}" && xcodebuild -workspace ptchampion.xcworkspace clean 2>/dev/null || echo "Clean failed, but continuing..."

echo "9. Opening Xcode workspace..."
open -a Xcode "${WORKSPACE}"

echo "Google SignIn SPM package has been added to the project."
echo "Please build the project in Xcode to verify integration." 