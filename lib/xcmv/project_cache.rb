module XcodeMove
  class ProjectCache
    @@cache = {}

    def self.open(path)
      path = Pathname.new(path).realpath
      @@cache[path] ||= Xcodeproj::Project.open(path)
    end
  end
end
