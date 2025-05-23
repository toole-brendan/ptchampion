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
