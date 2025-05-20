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
