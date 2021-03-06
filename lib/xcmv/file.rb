# frozen_string_literal: true

module XcodeMove
  # Represents a file which is expected to be in some Xcode project. The file
  # (and its project reference) may not necessarily exist. It can get, create,
  # and delete its project reference and can change its target membership,
  # using its location in the filesystem and its group membership in the
  # project.
  #
  # Files are assumed to have a matching directory hierarchy and project group
  # hierarchy.
  class File
    attr_reader :path

    def initialize(path)
      path = Pathname.new path
      @path = path.expand_path
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

    def ==(other)
      path == other.path
    end

    def with_dirname(root_path)
      new_path = root_path + path.basename
      self.class.new(new_path) # want to return the same kind of object
    end

    # Traverses up from the `path` to enumerate over xcodeproj directories
    def reachable_projects
      path.ascend.find_all { |p| p.exist? && p.directory? }.flat_map do |dir|
        dir.children.select { |p| p.extname == '.xcodeproj' }
      end
    end

    def remove_from_project
      project.targets.select { |t| t.respond_to?(:build_phases) }.each do |native_target|
        native_target.build_phases.each { |p| p.remove_file_reference(pbx_file) }
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

    def add_to_targets(target_names, header_visibility)
      targets = target_names ? find_targets(target_names) : infer_targets
      targets.each do |target|
        build_file = target.add_file_references([pbx_file])
        if header?
          visibility = header_visibility || HeaderVisibility.default_for_target(target)
          build_file.each { |b| b.settings = visibility.file_settings }
        end
      end
    end

    def save_and_close
      project.save
      @project = nil
    end

    private

    def find_targets(target_names)
      name_set = target_names.to_set
      targets = project.targets.select { |t| name_set.include?(t.name) }
      raise InputError, "🛑  Error: No targets found in #{target_names}." if targets.empty?

      targets
    end

    def infer_targets
      group = GroupMembership.new(pbx_file.parent)
      targets = group.inferred_targets

      if targets.empty?
        # fallback: if we can't infer any target membership,
        # we just assign the first target of the project and emit a warning
        fallback_target = project.targets.select { |t| t.respond_to?(:source_build_phase) }[0]
        targets = [fallback_target]
        warn "⚠️  Warning: Unable to infer target membership of #{path} -- assigning to #{fallback_target.name}."
      end
      targets
    end

    def find_or_create_relative_group(parent_group, group_name)
      parent_group.children.find { |g| g.path == group_name.to_s } ||
        parent_group.new_group(group_name.to_s, group_name)
    end

    def insert_at_group(group)
      group.new_file(path)
    end

    # Finds a reachable project that contains this file, and sets `project` and `pbx_file`.
    def project_load
      (project_dir = reachable_projects.first) || raise(InputError, "Could not find a project file containing #{path}")
      @project = ProjectCache.open(project_dir)
    end

    def pbx_load
      @pbx_file = project.files.find { |f| f.real_path == path }
    end
  end

  # Represents a group, which deletes its tree when removed. Otherwise, exactly the same
  # as a `File`.
  class Group < File
    def initialize(path)
      path = Pathname.new path
      @path = path.expand_path
    end

    def remove_from_project
      return if pbx_file.nil?

      pbx_file.children.each(&:remove_from_project)
      pbx_file.remove_from_project
      @pbx_file = nil
    end

    private

    def pbx_load
      @pbx_file = project.main_group.recursive_children.find { |g| g.respond_to?(:real_path) && (g.real_path == path) }
    end
  end
end
