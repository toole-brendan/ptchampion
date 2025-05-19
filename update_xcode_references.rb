#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Xcode project
project_path = 'ios/ptchampion/ptchampion.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Debug: Print all top-level groups
main_group = project.main_group
puts "Main groups in project:"
main_group.groups.each do |group|
  puts "- #{group.display_name} (path: #{group.path})"
end

# Find the project's main target group (might not be named "ptchampion")
target_group = nil
main_group.groups.each do |group|
  if group.path == 'ptchampion' || group.display_name == 'ptchampion'
    target_group = group
    break
  end
end

if target_group.nil?
  puts "Could not find main target group. Using main_group directly."
  target_group = main_group
end

# Find or create the necessary groups
services_group = nil
grading_group = nil
utils_group = nil

target_group.groups.each do |group|
  case group.display_name
  when 'Services'
    services_group = group
  when 'Grading'
    grading_group = group
  when 'Utils' 
    utils_group = group
  end
end

puts "Found groups:"
puts "- Services: #{services_group ? 'Yes' : 'No'}"
puts "- Grading: #{grading_group ? 'Yes' : 'No'}"
puts "- Utils: #{utils_group ? 'Yes' : 'No'}"

# Create groups if they don't exist
services_group ||= target_group.new_group('Services', 'Services')
grading_group ||= target_group.new_group('Grading', 'Grading')
utils_group ||= target_group.new_group('Utils', 'Utils')

# Remove all file references in these groups
services_group.clear
grading_group.clear
utils_group.clear

# Re-add file references with correct paths

# Services files
Dir.glob('ios/ptchampion/Services/*.swift').each do |file_path|
  file_name = File.basename(file_path)
  file_ref = services_group.new_reference(file_path)
  puts "Added: #{file_path}"
end

# Grading files
Dir.glob('ios/ptchampion/Grading/*.swift').each do |file_path|
  file_name = File.basename(file_path)
  file_ref = grading_group.new_reference(file_path)
  puts "Added: #{file_path}"
end

# Utils files
Dir.glob('ios/ptchampion/Utils/*.swift').each do |file_path|
  file_name = File.basename(file_path)
  file_ref = utils_group.new_reference(file_path)
  puts "Added: #{file_path}"
end

# Add ContentView.swift to the root
content_view_path = 'ios/ptchampion/ContentView.swift'
if File.exist?(content_view_path)
  content_view_ref = target_group.new_reference(content_view_path)
  puts "Added: ContentView.swift to root"
end

# Save the changes
project.save
puts "Xcode project references updated successfully!" 