require 'xcodeproj'
require_relative 'xcmv/file'
require_relative 'xcmv/header_visibility'
require_relative 'xcmv/group_membership'
require_relative 'xcmv/project_cache'

module XcodeMove
  VERSION = '0.0.1' 

  # Moves from one `XcodeMove::File` to another
  def self.mv(src, dst, options)
    # Remove files from xcodeproj (include dst if the file is being overwritten)
    src.remove_from_project
    dst.remove_from_project if dst.pbx_file

    # Add to the new xcodeproj
    dst.create_file_reference
    dst.configure_like_siblings(options[:targets], options[:headers])

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

  # Copies from one `XcodeMove::File` to another
  def self.cp(src, dst)
    command = "cp '#{src.path}' '#{dst.path}'"
    system(command) || raise(command)

    # Add to the new xcodeproj
    dst.create_file_reference
    # TODO optional header visibility argument
    dst.configure_like_siblings

    # Save
    src.save_and_close
    dst.save_and_close
  end
end
