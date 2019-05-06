# frozen_string_literal: true

module XcodeMove
  # Holds references to Xcodeproj::Project instances to make performant to open
  # a large project multiple times.
  class ProjectCache
    @cache = {}

    def self.open(path)
      path = Pathname.new(path).realpath
      @cache[path] ||= Xcodeproj::Project.open(path)
    end
  end
end
