require 'xcodeproj'
require 'xcmv'
require 'pathname'

module XcodeMove
  describe self do
    include_context 'in project directory'

    subject(:xcmv) { XcodeMove }

    let(:options) do
      { targets: %w[a b], headers: [HeaderVisibility::PUBLIC] }
    end

    before do
      allow(XcodeMove).to receive(:puts)
    end

    matcher :be_in do |project|
      match do |path|
        path = Pathname.new(path)
        path.exist? &&
          project.objects.any? { |o| o.respond_to?(:real_path) && (o.real_path == path.expand_path) }
      end
      description { "be referenced in #{project.path.relative_path_from(Pathname.getwd)}" }
    end

    shared_examples 'mv' do |src, dst|
      before { XcodeMove.mv(Pathname.new(src), Pathname.new(dst), options) }

      describe 'src' do
        subject { Pathname.new(src) }

        it { is_expected.not_to be_in(project) }
        it { is_expected.not_to exist }
      end

      describe 'dst' do
        subject { Pathname.new(dst) }

        it { is_expected.to exist }
        it { is_expected.to be_in(project) }
      end
    end

    context 'when moving a file' do
      it_behaves_like 'mv', 'a/a.swift', 'a/aa.swift'
    end

    context 'when overwriting a file' do
      let(:src) { Pathname.new('a/a.swift') }
      let(:dst) { Pathname.new('a/b.swift') }
      let!(:dst_text) { dst.read }

      before { XcodeMove.mv src, dst, options }

      it('overwrites the file') { expect(dst.read).not_to eq(dst_text) }
    end

    context 'when moving a file into an existing directory' do
      it_behaves_like 'mv', 'a/a.swift', 'b/a.swift'

      describe 'old parent' do
        subject { Pathname.new('a') }

        it { is_expected.to be_in(project) }
      end

      describe 'new sibling' do
        subject { Pathname.new('b/b.swift') }

        it { is_expected.to be_in(project) }
      end
    end

    context 'when renaming a directory' do
      it_behaves_like 'mv', 'a', 'c'

      describe 'its children' do
        subject { Pathname.new('c/a.swift') }

        before { XcodeMove.mv Pathname.new('a'), Pathname.new('c'), options }

        it { is_expected.to exist }
        it { is_expected.to be_in(project) }
      end
    end

    context 'when moving between projects' do
      let(:src) { Pathname.new('a') }
      let(:dst) { Pathname.new('subproject/c') }

      before { XcodeMove.mv(src, dst, options) }

      describe 'src' do
        subject { src }

        it { is_expected.not_to be_in(project) }
        it { is_expected.not_to be_in(subproject) }
      end

      describe 'dst' do
        subject { dst }

        it { is_expected.not_to be_in(project) }
        it { is_expected.to be_in(subproject) }
      end
    end

    context 'when moving a file outside a project' do
      it 'raises' do
        src = Pathname.new('../outer.swift')
        dst = Pathname.new('.')
        expect { xcmv.mv(src, dst, options) }.to raise_error(InputError)
      end
    end
  end
end
