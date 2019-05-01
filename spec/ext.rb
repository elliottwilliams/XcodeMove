require 'xcmv'
require 'pathname'

class String
  def to_pathname
    Pathname.new(self)
  end
end

class Pathname
  def to_pathname
    self
  end
end

module XcodeMove
  RSpec.shared_context 'with test project' do
    def make_dir(dir)
      dir.mkdir unless dir.exist?
      (dir / 'a').mkdir
      (dir / 'a/a.swift').write 'a/a.swift'
      (dir / 'a/b.swift').write 'a/b.swift'
      (dir / 'a/aa').mkdir
      (dir / 'a/aa/a.swift').write 'a/aa/a.swift' # aaaa!
      (dir / 'b').mkdir
      (dir / 'b/b.swift').write 'b/b.swift'
      (dir / 'main.swift').write 'main.swift'
      (dir / 'spec.xcodeproj').mkdir # loads of this project bundle are mocked
    end

    def xcodeproj(dir)
      project = Xcodeproj::Project.new(dir / 'spec.xcodeproj')
      app = project.new_target(:application, 'spec', :ios)

      group_a = project.main_group.new_group('a', 'a')
      group_aa = group_a.new_group('aa', 'aa')
      target_a = project.new_target(:framework, 'a', :ios)

      a_a = group_a.new_file('a.swift')
      a_b = group_a.new_file('b.swift')
      a_aa_a = group_aa.new_file('a.swift')
      target_a.add_file_references([a_a, a_b, a_aa_a])

      group_b = project.main_group.new_group('b', 'b')
      target_b = project.new_target(:framework, 'b', :ios)
      b_b = group_b.new_file('b.swift')
      target_b.add_file_references([b_b])

      main = project.main_group.new_file('main.swift')
      app.add_file_references([main])

      project
    end

    attr_reader :dir, :project, :subproject

    before do
      allow(project).to receive(:save)

      allow(Xcodeproj::Project).to receive(:open)
        .with(dir / 'project/spec.xcodeproj').and_return(project)

      allow(Xcodeproj::Project).to receive(:open)
        .with(dir / 'project/subproject/spec.xcodeproj').and_return(subproject)
    end

    around do |ex|
      Dir.mktmpdir do |dir|
        dir = dir.to_pathname.realpath
        make_dir(dir / 'project')
        make_dir(dir / 'project/subproject')
        (dir / 'outer.swift').write('outer.swift')

        @dir = dir
        @project = xcodeproj(dir / 'project')
        @subproject = xcodeproj(dir / 'project/subproject')

        Dir.chdir(dir / 'project') { ex.run }
      end
    end
  end
end
