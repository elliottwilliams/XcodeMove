require 'xcodeproj'
require 'xcmv'
require 'pathname'

describe XcodeMove do
  let(:options) do 
    {targets: ["a", "b"], headers: [XcodeMove::HeaderVisibility::PUBLIC]}
  end

  around do |ex|
    Dir.mktmpdir do |dir|
      dir = Pathname.new(dir)
      (dir/"a").mkdir
      (dir/"a/a.swift").write ""
      (dir/"b").mkdir
      (dir/"b/b.swift").write ""
      (dir/"main.swift").write ""
      Dir.chdir(dir) { ex.run }
    end
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
        XcodeMove::File.new(src), XcodeMove::File.new(dst), options
      )

      subject.mv(src, dst, options)
    end

    it 'moves a file into an existing directory' do
      # xcmv a/a.swift b
      src = Pathname.new("a/a.swift")
      dst = Pathname.new("b/a.swift")
      expect(subject).to receive(:project_mv).with(
        XcodeMove::File.new(src), XcodeMove::File.new(dst), options
      )

      subject.mv(src, dst, options)
    end

    xit 'moves a directory to a destination path' do
      # xcmv a c
      src = Pathname.new("a")
      dst = Pathname.new("c")
      expect(subject).to receive(:project_mv).with(
        XcodeMove::Group.new(src), XcodeMove::Group.new(dst), options
      )

      subject.mv(src, dst, options)
    end

    it 'does not move a directory onto an existing file' 
  end

  describe '::project_mv' do
    context 'moving a file' do
      subject(:src) { XcodeMove::File.new "a/a.swift" }
      subject(:dst) { XcodeMove::File.new "a/aa.swift" }

      it 'removes src file and creates dst' do
         
      end
    end

    context 'moving a directory'
  end
end
