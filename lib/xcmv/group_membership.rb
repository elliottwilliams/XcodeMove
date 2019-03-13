
module XcodeMove
  class GroupMembership
    attr_reader :group, :parent
    def initialize(group)
      @group = group
      @project = group.project
      @siblings = @group.children.to_set
      @parent = @group == @project.main_group ? nil : @group.parent
    end

    # Returns an array of targets that have build files in `group`.
    def sibling_targets
      compiled_targets = @project.targets.select{ |t| t.respond_to?(:source_build_phase) }
      compiled_targets.select{ |t| t.source_build_phase.files_references.any?{ |f| @siblings.include?(f) } }
    end

    def max_header_visibility(target)
      sibling_headers = target.headers_build_phase.files.filter{ |f| @siblings.include?(file_ref) }
      sibling_headers.map{ |f| HeaderVisibility.from_file_settings(f.settings) }.max
    end
  end
end
