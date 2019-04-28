require 'xcmv'
require 'tempfile'
require 'pathname'
require 'xcodeproj'

module XcodeMove
  describe File do
    context 'with filesystem' do
      before(:context) do |_ex|
        @dir = Pathname.new(Dir.mktmpdir('Project'))
        (@dir / 'Main.xcodeproj').mkdir
        (@dir / 'Info.plist').write ''
        (@dir / 'Sources').mkdir
        (@dir / 'Sources/a.swift').write ''
        (@dir / 'Framework').mkdir
        (@dir / 'Framework/Framework.xcodeproj').mkdir
        (@dir / 'Framework/Sources').mkdir
        (@dir / 'Framework/Sources/b.swift').write ''
      end

      describe '#reachable_projects' do
        after(:context) do
          FileUtils.remove_entry(@dir)
        end

        it 'traverses up to an xcodeproj bundle' do
          a = File.new(@dir / 'Sources/a.swift')
          expect(a.reachable_projects.map { |p| p.basename.to_s }).to \
            eq(['Main.xcodeproj'])

          b = File.new(@dir / 'Framework/Sources/b.swift')
          expect(b.reachable_projects.map { |p| p.basename.to_s }).to \
            eq(['Framework.xcodeproj', 'Main.xcodeproj'])

          info = File.new(@dir / 'Info.plist')
          expect(info.reachable_projects.map { |p| p.basename.to_s }).to \
            eq(['Main.xcodeproj'])
        end
      end
    end

    context 'with xcodeproj' do
      subject { File.new('spec') }
      let(:project) { Xcodeproj::Project.new('spec.xcodeproj').tap(&:initialize_from_scratch) }
      let(:pbx_file) { project.new_file('spec') }

      describe '#remove_from_project' do
        let(:target) { project.new_target(:framework, 'kit', :ios).tap { |t| t.add_file_references([pbx_file]) } }

        before(:example) do
          expect(subject).to receive(:project_load).and_return(project)
          expect(subject).to receive(:pbx_load).and_return(pbx_file)
        end

        it 'remove the reference from a project' do
          expect(project.main_group.files.count).to eq(1)
          expect(target.source_build_phase.files.count).to eq(1)
          subject.remove_from_project
          expect(project.main_group.files.count).to eq(0)
          expect(target.source_build_phase.files.count).to eq(0)
        end

        it 'clears the pbx_file' do
          expect(subject.pbx_file).to be
          subject.remove_from_project

          expect(subject).to receive(:pbx_load).and_return(nil)
          expect(subject.pbx_file).not_to be
        end
      end

      describe '#add_to_targets' do
        let!(:target_a) { project.new_target(:framework, 'a', :ios) }
        let!(:target_b) { project.new_target(:framework, 'b', :ios) }

        it 'adds to targets when given by name' do
          expect(subject).to receive(:project_load).and_return(project)
          expect(subject).to receive(:pbx_load).and_return(pbx_file)

          subject.add_to_targets(%w[a b], :public)
          expect(target_a.source_build_phase.files_references).to \
            include(subject.pbx_file)
          expect(target_b.source_build_phase.files_references).to \
            include(subject.pbx_file)
        end

        it 'infers target membership' do
          expect(subject).to receive(:pbx_load).and_return(pbx_file)

          expect_any_instance_of(GroupMembership).to \
            receive(:inferred_targets).and_return([target_a])

          subject.add_to_targets(nil, :public)
          expect(target_a.source_build_phase.files_references).to \
            include(subject.pbx_file)
        end
      end

      describe '#create_file_reference' do
        it 'inserts at the top-level group' do
          file = File.new('spec')
          expect(file).to receive(:project_load).and_return(project)

          file.create_file_reference
          expect(project.main_group.files).to include(file.pbx_file)
        end

        it 'inserts into an existing group' do
          group_a = project.main_group.new_group('a', 'a')
          group_b = group_a.new_group('b', 'b')

          file = File.new('a/b/spec')
          expect(file).to receive(:project_load).and_return(project)

          file.create_file_reference
          expect(group_b.files).to include(file.pbx_file)
        end

        it 'creates new groups' do
          file = File.new('c/spec')
          expect(file).to receive(:project_load).and_return(project)

          file.create_file_reference
          new_group = project.main_group.children.find { |g| g.path == 'c' }
          expect(new_group).to be
          expect(new_group.files).to include(file.pbx_file)
        end
      end
    end
  end

  describe Group do
    subject { Group.new('a') }
    let(:project) { Xcodeproj::Project.new('spec.xcodeproj').tap(&:initialize_from_scratch) }
    let(:pbxgroup) { project.main_group.new_group('a', 'a') }

    before(:example) do
      expect(subject).to receive(:pbx_load).and_return(pbxgroup)
    end

    describe '#remove_from_project' do
      it 'recursively removes files' do
        files = [
          pbxgroup.new_file('a.swift'),
          pbxgroup.new_file('b.swift'),
          pbxgroup.new_file('c.swift')
        ]

        expect(project.main_group.children).to include(pbxgroup)
        expect(pbxgroup.children.objects).to include(*files)

        subject.remove_from_project

        expect(project.main_group.children).not_to include(pbxgroup)
      end

      it 'recursively removes groups' do
        group_b = pbxgroup.new_group('b', 'b')
        group_c = group_b.new_group('c', 'c')
        file_c = group_c.new_file('c.swift')

        expect(pbxgroup.recursive_children).to include(group_b, group_c, file_c)

        subject.remove_from_project

        expect(pbxgroup.recursive_children).to be_empty
        expect(project.main_group.children).not_to include(pbxgroup)
      end
    end
  end
end
