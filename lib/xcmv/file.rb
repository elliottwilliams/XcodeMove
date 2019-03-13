
module XcodeMove
  class File
    attr_reader :path

    def initialize(path)
      path = Pathname.new path
      @path = path.realdirpath
    end

    def project
      @project ||= project_load
    end

    def pbx_file
      @pbx_file ||= pbx_load
    end

    def header?
      path.extname == '.h'
    end
    

    # Traverses up from the `path` to enumerate over xcodeproj directories
    def reachable_projects
      path.ascend.find_all{ |p| p.directory? }.flat_map do |dir|
        dir.children.select{ |p| p.extname == '.xcodeproj' }
      end
    end

    def remove_from_project
      project.targets.select{ |t| t.respond_to?(:build_phases) }.each do |native_target|
        native_target.build_phases.each{ |p| p.remove_file_reference(pbx_file) }
      end
      pbx_file.remove_from_project
      @pbx_file = nil
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

    def infer_target_membership
      # attempt to infer target membership from sibling files
      group = GroupMembership.new(pbx_file.parent)
      targets = group.sibling_targets

      # if we can't infer target membership from immediate siblings,
      # we traverse up the project until we can, or we hit the main group
      while targets.empty? && group.group != project.main_group do
        group = GroupMembership.new(group.parent)
        targets = group.sibling_targets
      end

      # fallback: if we can't infer any target membership by traveling up the project,
      # we just assign the first target of the project and emit a warning
      warn "⚠️  Warning: Unable to infer target membership of #{path} -- assigning to first target of project."
      targets = [project.targets.select{ |t| t.respond_to?(:source_build_phase) }[0]] if targets.empty?
      targets
    end

    def add_to_targets(target_names, header_visibility)
      unless target_names
        targets = infer_target_membership
      else
        name_set = target_names.to_set
        targets = project.targets.select{ |t| name_set.include?(t.name) }
        abort "No targets found in #{target_names}" if targets.empty?
      end

      targets.each do |target|
        build_file = target.add_file_references([@pbx_file])
        if header?
          visibility = header_visibility || HeaderVisibility.default_for_target(target)
          build_file.each{ |b| b.settings = visibility.file_settings }
        end
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
      @project = ProjectCache.open(project_dir)
    end

    def pbx_load
      @pbx_file = project.files.find{ |f| f.real_path == path }
    end
  end
end
