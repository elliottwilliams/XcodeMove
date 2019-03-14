require 'xcodeproj'
require_relative 'xcmv/file'
require_relative 'xcmv/header_visibility'
require_relative 'xcmv/group_membership'
require_relative 'xcmv/project_cache'
require_relative 'xcmv/version'

module XcodeMove

  # Moves from one `XcodeMove::File` to another
  def self.mv(src, dst, options, indent=0)
    puts("#{"  " * indent}#{src.path} => #{dst.path}")

    if src.path.directory?
      # Process all children first
      children = src.path.children.map { |c| c.directory? ? Group.new(c) : File.new(c) }
      children.each do | c |
        dst_file = c.with_dirname(dst.path)
        XcodeMove.mv(c, dst_file, options, indent + 1)
      end

      # Remove src group from project
      src.remove_from_project

      # Remove src group from disk
      remover = "rmdir"
      command = "#{remover} '#{src.path}'"
      system(command) || abort
    else
      # Remove files from xcodeproj (including dst if the file is being overwritten)
      if src.pbx_file
        src.remove_from_project
      else
        warn("warning: #{src.path.realdirpath} not found in #{src.project.path.basename}. moving anyway...")
      end
      if dst.pbx_file
        dst.remove_from_project
      end

      # Add to the new xcodeproj
      dst.create_file_reference
      dst.add_to_targets(options[:targets], options[:headers])

      # Move the actual file
      if options[:git]
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
end
