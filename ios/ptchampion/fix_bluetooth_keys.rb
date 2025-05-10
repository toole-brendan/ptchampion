#!/usr/bin/env ruby
require 'xcodeproj'

# Path to your .xcodeproj file
project_path = 'ptchampion.xcodeproj'

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
      
      # Add Bluetooth-related keys to the build settings
      config.build_settings['INFOPLIST_KEY_NSBluetoothAlwaysUsageDescription'] = 'PT Champion needs Bluetooth access to connect to fitness devices for heart rate, GPS, pace, and cadence monitoring.'
      config.build_settings['INFOPLIST_KEY_NSBluetoothPeripheralUsageDescription'] = 'PT Champion needs Bluetooth access to connect to fitness devices for heart rate, GPS, pace, and cadence monitoring.'
    end
    
    # Save the project
    project.save
    puts "Project saved successfully with Bluetooth keys added to build settings."
  else
    puts "Target 'ptchampion' not found."
  end
rescue => e
  puts "Error: #{e.message}"
end 