require 'xcodeproj'
require_relative 'xcmv/file'
require_relative 'xcmv/header_visibility'
require_relative 'xcmv/group_membership'

module XcodeMove
  VERSION = '0.0.1' 

  # Moves from one `XcodeMove::File` to another
  def self.mv(src, dst, git=false)
    # Move the actual file
    # TODO optional --git argument
    mover = git ? "git mv" : "mv"
    command = "#{mover} '#{src.path}' '#{dst.path}'"
    system(command) || abort

    # Remove the file from the source xcodeproj
    src.remove_from_project

    # Add to the new xcodeproj
    dst.create_file_reference
    # TODO optional header visibility argument
    dst.configure_like_siblings

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
