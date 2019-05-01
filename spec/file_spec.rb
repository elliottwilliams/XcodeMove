require 'xcmv'
require 'ext'
require 'tempfile'
require 'pathname'
require 'xcodeproj'

module XcodeMove
  describe File do
    include_context 'in project directory'

    describe '#reachable_projects' do
      context 'with a file in the root directory' do
        subject { File.new('main.swift').reachable_projects }

        it { is_expected.to eq [project.path] }
      end

      context 'with a file in a subproject' do
        subject { File.new('subproject/main.swift').reachable_projects }

        it { is_expected.to eq [subproject.path, project.path] }
      end

      context 'with a file in a subdirectory' do
        subject { File.new('a/a.swift').reachable_projects }

        it { is_expected.to eq [project.path] }
      end
    end

    describe '#remove_from_project' do
      let(:group) { project['b'] }
      let(:target) { project.native_targets.find { |t| t.name == 'b' } }
      let(:file) { File.new('b/b.swift') }
      let!(:pbx_file) { file.pbx_file }

      before { file.remove_from_project }

      it('removes the file from the group') { expect(group.files).not_to include pbx_file }
      it('removes the file from the target') { expect(target.source_build_phase.files).not_to include pbx_file }
      it('clears the pbx_file') { expect(file.pbx_file).to eq nil }
    end

    describe '#add_to_targets' do
      let(:file) { File.new('a/new.swift') }
      let(:target_a) { project.native_targets.find { |t| t.name == 'a' }.source_build_phase.files_references }
      let(:target_b) { project.native_targets.find { |t| t.name == 'b' }.source_build_phase.files_references }

      context 'when targets given' do
        before { file.tap(&:create_file_reference).add_to_targets(%w[a b], nil) }

        it('creates references in both targets') do
          files_references = [target_a, target_b]
          expect(files_references).to all include file.pbx_file
        end
      end

      context 'when targets not given' do
        before { file.tap(&:create_file_reference).add_to_targets(%w[a b], nil) }

        it('infers target membership') { expect(target_a).to include file.pbx_file }
      end
    end

    describe '#create_file_reference' do
      shared_examples 'in_group' do |group|
        subject { project[group].files }

        before { file.create_file_reference }

        it { is_expected.to include file.pbx_file }
      end

      context 'when inserting into an existing group' do
        let(:file) { File.new('a/new.swift') }

        include_examples 'in_group', 'a'
      end

      context 'when creating a new group' do
        let(:file) { File.new('new/new.swift') }

        include_examples 'in_group', 'new'
      end
    end

    describe Group do
      subject { Group.new('a') }

      describe '#remove_from_project' do
        before { Group.new('a').remove_from_project }

        it 'removes the group' do
          expect(project['a']).to be nil
        end

        it 'removes files from the project' do
          all_filenames = project.files.map(&:name)
          expect(all_filenames).not_to include 'a.swift'
        end
      end
    end
  end
end
