
module XcodeMove
  class HeaderVisibility
    include Comparable

    PRIVATE = HeaderVisibility.new(1)
    PROJECT = HeaderVisibility.new(2)
    PUBLIC = HeaderVisibility.new(3)

    attr_reader :value

    def self.from_file_settings(settings)
      case settings["ATTRIBUTES"]
      when "Public"
        PUBLIC
      when "Private"
        PRIVATE
      when nil
        PROJECT
      end
    end

    def file_settings
      case self
      when PUBLIC
        visibility = "Public"
      when PRIVATE
        visibility = "Private"
      when PROJECT
        visibility = nil
      end
      { "ATTRIBUTES": [visibility] }
    end

    def <=>(other)
      value <=> other.value
    end

    private
    def initialize(value)
      @value = value
    end
  end
end
