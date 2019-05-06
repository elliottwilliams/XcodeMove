# frozen_string_literal: true

require 'xcmv'
require 'xcmv/parser'
require 'ext'
require 'pathname'
require 'rspec/its'

module XcodeMove
  describe Parser do
    include_context 'with test project'
    subject { Parser.parse! argv }

    let(:options) { Parser.options }

    shared_examples 'passes paths through' do |*argv|
      let(:argv) { argv }

      its(:srcs) { is_expected.to eq argv[0...-1].map(&:to_pathname) }
      its(:dst) { is_expected.to eq argv.last.to_pathname }
    end

    context 'when renaming a file' do
      include_examples 'passes paths through', 'a/a.swift', 'a/aa.swift'
    end

    context 'when moving a file into a directory' do
      include_examples 'passes paths through', 'a/a.swift', 'b'
    end

    context 'when moving a directory into a directory' do
      include_examples 'passes paths through', 'a', 'b'
    end

    context 'when renaming a directory' do
      include_examples 'passes paths through', 'b', 'c'
    end

    context 'when moving multiple files into a directory' do
      let(:argv) { %w[b/b.swift b/c.swift a] }

      its(:srcs) { is_expected.to eq ['b/b.swift'.to_pathname, 'b/c.swift'.to_pathname] }
      its(:dst) { is_expected.to eq 'a'.to_pathname }
    end

    context 'when moving multiple files to the same path' do
      subject { -> { Parser.parse! argv } }

      let(:argv) { %w[a/a.swift b/b.swift main.swift] }

      it { is_expected.to raise_error(InputError) }
    end
  end
end
