require 'xcodeproj'
require_relative 'xcmv/file'
require_relative 'xcmv/header_visibility'
require_relative 'xcmv/group_membership'
require_relative 'xcmv/project_cache'
require_relative 'xcmv/version'

module XcodeMove
  class InputError < RuntimeError
  end

  # Moves from one `Pathname` to another
  def self.mv(src, dst, options)
    src_file = src.directory? ? Group.new(src) : File.new(src) 
    dst_file = dst.directory? ? src_file.with_dirname(dst) : src_file.class.new(dst)

    puts("#{src_file.path} => #{dst_file.path}")

    project_mv(src_file, dst_file, options)
    disk_mv(src_file, dst_file, options)
    save(src_file, dst_file)
  end

  private

  # Prepare the project file(s) for the move
  def self.project_mv(src_file, dst_file, options)
    if src_file.path.directory?
      # Process all children first
      children = src_file.path.children.map { |c| c.directory? ? Group.new(c) : File.new(c) }
      children.each do | src_child |
        dst_child = src_child.with_dirname(dst_file.path)
        project_mv(src_child, dst_child, options)
      end
    else
      # Remove old destination file reference if it exists
      if dst_file.pbx_file
        dst_file.remove_from_project
      end

      # Add new destination file reference to the new xcodeproj
      dst_file.create_file_reference 
      dst_file.add_to_targets(options[:targets], options[:headers])
    end

    # Remove original directory/file from xcodeproj
    if src_file.pbx_file
      src_file.remove_from_project
    else
      warn("⚠️  Warning: #{src_file.path.basename} not found in #{src_file.project.path.basename}, moving anyway...")
    end
  end

  # Move the src_file to the dst_file on disk
  def self.disk_mv(src_file, dst_file, options)
    mover = options[:git] ? "git mv" : "mv"
    command = "#{mover} '#{src_file.path}' '#{dst_file.path}'"
    system(command) or raise InputError, "#{command} failed"
  end

  # Save the src_file and dst_file project files to disk
  def self.save(src_file, dst_file)
    src_file.save_and_close
    dst_file.save_and_close
  end
end
