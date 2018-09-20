
module XcodeMove
  class GroupMembership
    def initialize(group)
      @group = group
      @project = group.project
    end

    def siblings
      @group.children.to_set
    end

    # Returns an array of targets that have build files in `group`.
    def sibling_targets
      compiled_targets = @project.targets.select{ |t| t.respond_to?(:source_build_phase) }
      compiled_targets.select{ |t| t.source_build_phase.files_references.any?{ |f| siblings.include?(f) } }
    end

    def max_header_visibility
      header_targets = project.targets.select{ |t| t.respond_to?(:headers_build_phase) }
      header_build_files = header_targets.flat_map{ |t| t.headers_build_phase.files.filter{ |f| siblings.include?(file_ref) } }
      header_build_files.map{ |f| HeaderVisibility.from_file_settings(f.settings) }.max
    end
  end
end
