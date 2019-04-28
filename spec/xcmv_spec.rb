require 'xcodeproj'
require 'xcmv'
require 'pathname'

module XcodeMove 
  describe self do
    include_context "in project directory"

    let(:options) do 
      {targets: ["a", "b"], headers: [HeaderVisibility::PUBLIC]}
    end

    describe '::mv' do
      before(:example) do
        expect(subject).to receive(:puts)
        expect(subject).to receive(:disk_mv)
        expect(subject).to receive(:save)
      end

      it 'moves a file to a destination path' do
        # xcmv a/a.swift a/aa.swift
        src = Pathname.new("a/a.swift")
        dst = Pathname.new("a/aa.swift")
        expect(subject).to receive(:project_mv).with(
          File.new(src), File.new(dst), options
        )

        subject.mv(src, dst, options)
      end

      it 'moves a file into an existing directory' do
        # xcmv a/a.swift b
        src = Pathname.new("a/a.swift")
        dst = Pathname.new("b/a.swift")
        expect(subject).to receive(:project_mv).with(
          File.new(src), File.new(dst), options
        )

        subject.mv(src, dst, options)
      end

      it 'moves a directory to a destination path' do
        # xcmv a c
        src = Pathname.new("a")
        dst = Pathname.new("c")
        expect(subject).to receive(:project_mv).with(
          Group.new(src), Group.new(dst), options
        )

        subject.mv(src, dst, options)
      end
    end

    describe '::project_mv' do
      context 'moving a file' do
        let(:src) { File.new "a/a.swift" }
        let(:dst) { File.new "a/aa.swift" }
        let(:src_pbxfile) { instance_double(Xcodeproj::Project::Object::PBXBuildFile) }
        let(:dst_pbxfile) { instance_double(Xcodeproj::Project::Object::PBXBuildFile) }

        before(:example) do
          expect(dst).to receive(:create_file_reference)
          expect(dst).to receive(:add_to_targets)
          expect(src).to receive(:pbx_load).and_return(src_pbxfile)
          expect(dst).to receive(:pbx_load).and_return(dst_pbxfile) 
        end

        context 'when dst exists in a project' do
          it 'removes src file and replaces dst' do
            expect(src).to receive(:remove_from_project)
            expect(dst).to receive(:remove_from_project)
            subject.project_mv(src, dst, options)
          end
        end

        context 'when dst does not exist' do
          let(:dst_pbxfile) { nil }

          it 'removes src file and creates dst' do
            expect(src).to receive(:remove_from_project)
            subject.project_mv(src, dst, options)
          end
        end

        context 'when src does not exist' do
          let(:src_pbxfile) { nil }
          let(:dst_pbxfile) { nil }

          it 'warns of no project' do
            expect(src).to receive(:project).and_return(double(path: Pathname.new("project.xcodeproj")))
            expect(subject).to receive(:warn)
            subject.project_mv(src, dst, options)
          end
        end
      end

      context 'moving a directory' do
        let(:src) { Group.new "a" }
        let(:dst) { Group.new "c" }

        before(:example) do
          expect(src).to receive(:pbx_load).and_return(instance_double(Xcodeproj::Project::Object::PBXGroup))
          expect(src).to receive(:remove_from_project)
        end

        it "recurses with the directory's contents" do
          allow(subject).to receive(:project_mv).and_wrap_original do |original_method, *args|
            original_method.call(*args) if args == [src, dst, options]
          end

          subject.project_mv(src, dst, options)
          expect(subject).to have_received(:project_mv)
            .with(src, dst, options)
            .with(File.new("a/a.swift"), File.new("c/a.swift"), options)
            .with(File.new("a/b.swift"), File.new("c/b.swift"), options)
        end
      end
    end
  end
end
