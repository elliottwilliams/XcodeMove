class Xcodeproj::Project::Object::PBXGroup
  # Returns an array of targets that have build files in `group`.
  def sibling_targets
    siblings = children.to_set
    compiled_targets = project.targets.select{ |t| t.respond_to?(:source_build_phase) }
    compiled_targets.select{ |t| t.source_build_phase.files_references.any?{ |f| siblings.include?(f) } }
  end
end

module XcodeMove
  class GroupMembership
    attr_reader :group, :parent, :project
    def initialize(group)
      @group = group
      @project = group.project
      @siblings = @group.children.to_set
      @parent = @group == @project.main_group ? nil : @group.parent
    end

    # Returns an array of targets that the `group` should reasonably
    # belong to -- either based on `sibling_targets` or the `sibling_targets`
    # of some ancestor group.
    def inferred_targets
      target_group = self.group
      targets = []
      while targets.empty? and target_group.respond_to?(:sibling_targets) do
        targets += target_group.sibling_targets
        target_group = target_group.parent
      end
      targets
    end
        
    def max_header_visibility(target)
      sibling_headers = target.headers_build_phase.files.filter{ |f| @siblings.include?(file_ref) }
      sibling_headers.map{ |f| HeaderVisibility.from_file_settings(f.settings) }.max
    end
  end
end
