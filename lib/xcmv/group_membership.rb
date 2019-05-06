# frozen_string_literal: true

# Private extension methods to power GroupMemebership
class Xcodeproj::Project::Object::PBXGroup # rubocop:disable Style/ClassAndModuleChildren
  private

  # Returns an array of targets that have build files in `group`.
  def sibling_targets
    siblings = children.to_set
    compiled_targets = project.targets.select { |t| t.respond_to?(:source_build_phase) }
    compiled_targets.select { |t| t.source_build_phase.files_references.any? { |f| siblings.include?(f) } }
  end
end

module XcodeMove
  # A representation of a PBXGroup, which guesses attributes of the group based
  # on its contents and the contents of neighboring groups in the project.
  class GroupMembership
    attr_reader :group, :project
    def initialize(group)
      @group = group
      @project = group.project
      @siblings = @group.children.to_set
    end

    # Returns an array of targets that the `group` should reasonably
    # belong to -- either based on `sibling_targets` or the `sibling_targets`
    # of some ancestor group.
    def inferred_targets
      target_group = group
      targets = []
      while targets.empty? && target_group.respond_to?(:sibling_targets)
        targets += target_group.sibling_targets
        target_group = target_group.parent
      end
      targets
    end

    def max_header_visibility(target)
      sibling_headers = target.headers_build_phase.files.filter { |_f| @siblings.include?(file_ref) }
      sibling_headers.map { |f| HeaderVisibility.from_file_settings(f.settings) }.max
    end
  end
end
