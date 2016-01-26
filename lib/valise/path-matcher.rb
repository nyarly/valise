require 'valise/utils'

module Valise
  class PathMatcher
    include Unpath
    include Enumerable

    class Pattern
      FLAG_NAMES = {
        :extended   => File::FNM_EXTGLOB,
        :noextended => ~File::FNM_EXTGLOB,
        :case       => ~File::FNM_CASEFOLD,
        :nocase     => File::FNM_CASEFOLD,
        :pathname   => File::FNM_PATHNAME,
        :nopathname => ~File::FNM_PATHNAME,
        :escape     => ~File::FNM_NOESCAPE,
        :noescape   => File::FNM_NOESCAPE,
        :dotmatch   => File::FNM_DOTMATCH,
        :nodotmatch => ~File::FNM_DOTMATCH,
      }

      def initialize(match, include, flags)
        @match, @include = match, include
        @flags = 0
        set_flags(flags)
      end
      attr_accessor :match, :include, :flags

      def set_flags(flags)
        if flags.is_a?(Array)
          flags = flags.reduce(0) do |flags, name|
            flag = FLAG_NAMES.fetch(name) do
              raise "Path match flag name #{name.inspect} not in recognized list: #{FLAG_NAMES.keys.inspect}"
            end
            if flag < 0
              flags & flag
            else
              flags | flag
            end
          end
        end
        @flags = flags
      end
    end

    def self.build(path, value = true, flags = nil)
      return path if PathMatcher === path
      path = Unpath::make_pathname(path).to_s
      self.new(path, value, flags)
    end

    DEFAULT_FLAGS = File::FNM_EXTGLOB
    def initialize(first_pattern=nil, first_value=true, first_flags = nil)
      @pattern_pairs = []
      @default_flags = DEFAULT_FLAGS
      set(first_pattern, first_value, first_flags) unless first_pattern.nil?
    end
    attr_accessor :default_flags

    def ===(path)
      path = make_pathname(path)
      fetch(path)
      return true
    rescue KeyError
      return false
    end

    def fetch(path)
      @pattern_pairs.each do |pattern|
        if path.fnmatch?(pattern.match, pattern.flags || default_flags)
          return pattern.include
        end
      end
      raise KeyError, "No pattern matches #{path.to_s}"
    end

    def [](path)
      fetch(path)
    rescue KeyError
      nil
    end

    def set(pattern, value, flags = nil)
      add_pattern(Pattern.new(pattern.to_s, value, flags))
    end
    alias []= set

    def add_pattern(pattern)
      @pattern_pairs.delete_if do |old_pattern|
        pattern.match == old_pattern.match
      end
      @pattern_pairs << pattern
    end

    def each(&block)
      @pattern_pairs.each(&block)
    end

    def merge!(other)
      other.each do |pattern|
        add_pattern(pattern)
      end
    end
  end
end
