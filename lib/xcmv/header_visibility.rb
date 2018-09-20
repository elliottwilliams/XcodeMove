
module XcodeMove
  class HeaderVisibility
    include Comparable

    PRIVATE = 1
    PROJECT = 2
    PUBLIC = 3

    attr_reader :value

    def initialize(value)
      @value = value
    end

    def self.from_file_settings(settings)
      case settings["ATTRIBUTES"]
      when "Public"
        HeaderVisibility.new(PUBLIC)
      when "Private"
        HeaderVisibility.new(PRIVATE)
      when nil
        HeaderVisibility.new(PROJECT)
      end
    end

    def file_settings
      case value
      when PUBLIC
        visibility = "Public"
      when PRIVATE
        visibility = "Private"
      when PROJECT
        visibility = nil
      end
      { "ATTRIBUTES": visibility }
    end

    def <=>(other)
      value <=> other.value
    end
  end
end
