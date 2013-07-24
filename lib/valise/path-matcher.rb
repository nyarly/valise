require 'valise/utils'

module Valise
  class PathMatcher
    include Unpath
    include Enumerable

    def self.build(path, value = true)
      return path if PathMatcher === path
      path = Unpath::make_pathname(path).to_s
      self.new(path, value)
    end

    def initialize(first_pattern=nil, first_value=true)
      @pattern_pairs = []
      set(first_pattern, first_value) unless first_pattern.nil?
    end

    def ===(path)
      path = make_pathname(path)
      fetch(path)
      return true
    rescue KeyError
      return false
    end

    def fetch(path)
      @pattern_pairs.each do |pattern, value|
        if path.fnmatch?(pattern)
          return value
        end
      end
      raise KeyError, "No pattern matches #{path.to_s}"
    end

    def [](path)
      fetch(path)
    rescue KeyError
      nil
    end

    def set(pattern, value)
      @pattern_pairs.delete_if do |old_pattern, _|
        pattern == old_pattern
      end
      @pattern_pairs << [pattern.to_s, value]
    end
    alias []= set

    def each_pair
      @pattern_pairs.each do |pattern, value|
        yield pattern, value
      end
    end

    def merge!(other)
      other.each_pair do |pattern, value|
        set(pattern, value)
      end
    end
  end
end
