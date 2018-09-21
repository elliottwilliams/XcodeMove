require 'xcodeproj'
require_relative 'xcmv/file'
require_relative 'xcmv/header_visibility'
require_relative 'xcmv/group_membership'
require_relative 'xcmv/project_cache'
require_relative 'xcmv/version'

module XcodeMove

  # Moves from one `XcodeMove::File` to another
  def self.mv(src, dst, options)
    puts("#{src.path} => #{dst.path}")

    # Remove files from xcodeproj (including dst if the file is being overwritten)
    if src.pbx_file
      src.remove_from_project
    else
      warn("#{src.path.basename} not found in #{src.project.path.basename}")
    end
    if dst.pbx_file
      dst.remove_from_project
    end

    # Add to the new xcodeproj
    dst.create_file_reference
    dst.add_to_targets(options[:targets], options[:headers])

    # Move the actual file
    if options[:git] || system("git rev-parse")
      mover = "git mv"
    else 
      mover = "mv"
    end
    command = "#{mover} '#{src.path}' '#{dst.path}'"
    system(command) || abort

    # Save
    src.save_and_close
    dst.save_and_close
  end
end
