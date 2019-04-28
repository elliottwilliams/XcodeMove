require 'xcmv'
require 'xcmv/parser'
require 'pathname'

module XcodeMove
  describe Parser do
    include_context 'in project directory'
    subject { Parser }

    it 'allows renaming a file' do
      expect(XcodeMove).to receive(:mv).with(
        Pathname.new('a/a.swift'),
        Pathname.new('a/aa.swift'),
        subject.options
      )
      subject.run!(['a/a.swift', 'a/aa.swift'])
    end

    it 'allows moving a file into a directory' do
      expect(XcodeMove).to receive(:mv).with(
        Pathname.new('a/a.swift'),
        Pathname.new('b'),
        subject.options
      )
      subject.run!(['a/a.swift', 'b'])
    end

    it 'allows renaming a directory' do
      expect(XcodeMove).to receive(:mv).with(
        Pathname.new('b'),
        Pathname.new('c'),
        subject.options
      )
      subject.run!(%w[b c])
    end

    it 'allows moving multiple files into a directory' do
      expect(XcodeMove).to receive(:mv).with(Pathname.new('b/c.swift'), Pathname.new('a'), subject.options)
      expect(XcodeMove).to receive(:mv).with(Pathname.new('b/b.swift'), Pathname.new('a'), subject.options)
      subject.run!(['b/b.swift', 'b/c.swift', 'a'])
    end

    it 'fails when moving mutliple files to another file' do
      expect { subject.run!(['a/a.swift', 'b/b.swift', 'main.swift']) }.to raise_error(InputError)
    end
  end
end
