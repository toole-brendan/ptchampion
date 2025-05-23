require 'xcodeproj'

# Open the project
project_path = 'ptchampion.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'ptchampion' }

# Add package dependency
package_refs = project.root_object.package_references
package_repo = 'https://github.com/google/GoogleSignIn-iOS'
package_ref = package_refs.find { |ref| ref.repositoryURL == package_repo }

if package_ref.nil?
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
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
