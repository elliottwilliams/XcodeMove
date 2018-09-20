
module XcodeMove
  class File
    attr_reader :path

    def initialize(path)
      path = Pathname.new path
      @path = path.realpath
    end

    def self.mv(src, dst)
      File.new(src).move_to(dst)
    end

    def project
      project_load unless @project
      @project
    end

    def pbx_file
      pbx_load unless @pbx_file
      @pbx_file 
    end

    def in_repo?
      system("#{local_git} rev-parse")
    end

    def local_git
      "git -C  '#{path.dirname}'"
    end
    
    def move_to(dest_path)
      dest_path = Pathname.new(dest_path)

      # Support moving to an existing directory and keeping the same basename
      if dest_path.directory?
        dest_path += path.basename
      end

      # Move the actual file
      mover = in_repo? ? "#{local_git} mv" : "mv"
      command = "#{mover} #{path} #{dest_path}"
      system(command) || raise(command)

      # Remove the file from the source xcodeproj
      pbx_file.remove_from_project
      @pbx_file = nil

      # Refers to the moved file, which can now be added to a project
      dest = File.new dest_path

      # Add to the new xcodeproj
      dest.create_file_reference
      dest.configure_like_siblings

      # Save
      save_and_close
      dest.save_and_close
      dest
    end

    # Traverses up from the `path` to enumerate over xcodeproj directories
    def reachable_projects
      path.ascend.find_all{ |p| p.directory? }.flat_map do |dir|
        dir.children.select{ |p| p.extname == '.xcodeproj' }
      end
    end

    # Uses the `path` to create a file reference in `project`, setting
    # `pbx_file` along the way.
    def create_file_reference
      relative_path = path.relative_path_from(project.path.dirname)
      group = project.main_group
      relative_path.descend do |subpath|
        if subpath == relative_path
          @pbx_file = insert_at_group(group)
        else
          group = find_or_create_relative_group(group, subpath.basename)
        end
      end
    end

    def configure_like_siblings
      group = GroupMembership.new(@pbx_file.parent)
      build_files = add_to_targets(group.sibling_targets)
    end

    def add_to_targets(native_targets)
      native_targets.flat_map do |target|
        target.add_file_references([@pbx_file])
      end
    end

    def save_and_close
      project.save
      @project = nil
    end

    private

    def find_or_create_relative_group(parent_group, group_name)
      parent_group.children.find { |g| g.path == group_name.to_s } ||
        parent_group.new_group(group_name.to_s, group_name)
    end

    def insert_at_group(group)
      group.new_file(path)
    end

    # Finds a reachable project that contains this file, and sets `project` and `pbx_file`.
    def project_load
      project_dir = reachable_projects.first || abort("Could not find a project file containing #{path}")
      @project = Xcodeproj::Project.open(project_dir)
    end

    def pbx_load
      @pbx_file = project.files.find{ |f| f.real_path == path }
    end
  end
end
