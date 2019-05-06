# frozen_string_literal: true

module XcodeMove
  # An enumeration that determines file settings for headers of a target.
  class HeaderVisibility
    include Comparable

    private

    def initialize(value)
      @value = value
    end

    public

    PRIVATE = HeaderVisibility.new(1)
    PROJECT = HeaderVisibility.new(2)
    PUBLIC = HeaderVisibility.new(3)

    attr_reader :value

    def self.default_for_target(native_target)
      case native_target.product_type
      when 'com.apple.product-type.framework'
        PUBLIC
      else
        PROJECT
      end
    end

    def self.from_file_settings(settings)
      case settings['ATTRIBUTES']
      when 'Public'
        PUBLIC
      when 'Private'
        PRIVATE
      when nil
        PROJECT
      end
    end

    def file_settings
      case self
      when PUBLIC
        visibility = 'Public'
      when PRIVATE
        visibility = 'Private'
      when PROJECT
        visibility = nil
      end
      { "ATTRIBUTES": [visibility] }
    end

    def <=>(other)
      value <=> other.value
    end
  end
end
