#!/usr/bin/env ruby
require 'xcodeproj'

# Path to your .xcodeproj file
project_path = 'ptchampion.xcodeproj'
entitlements_path = 'ptchampion.entitlements'

begin
  project = Xcodeproj::Project.open(project_path)
  puts "Project opened successfully: #{project_path}"
  
  # Get the main target
  target = project.targets.find { |t| t.name == 'ptchampion' }
  
  if target
    puts "Found target: #{target.name}"
    
    # Get all the build configurations
    target.build_configurations.each do |config|
      puts "Updating build configuration: #{config.name}"
      config.build_settings['CODE_SIGN_ENTITLEMENTS'] = entitlements_path
    end
    
    # Save the project
    project.save
    puts "Project saved successfully with entitlements configuration."
  else
    puts "Target 'ptchampion' not found."
  end
rescue => e
  puts "Error: #{e.message}"
end 