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
