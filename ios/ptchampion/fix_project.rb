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
