require 'valise/utils'

module Valise
  class PathMatcher
    include Unpath
    include Enumerable

    def self.build(path, value = true)
      case path
      when PathMatcher
        return path
      when String, Array
        matcher = PathMatcher.new
        matcher[path] = value
        return matcher
      else
        raise ArgumentError, "Path matchers can only be built from arrays or strings"
      end
    end

    def initialize(segment = nil)
      @children = []
      @segment = segment
      @value = nil
    end

    attr_reader :segment

    def each_pair(prefix = [])
      segments = prefix.dup
      segments << @segment if @segment
      @children.each do |child|
        child.each_pair(segments) do |segments, value|
          yield(segments, value)
        end
      end
      yield(segments, @value) if @value
    end

    def each(prefix = [])
      each_pair do |segments, value|
        yield(segments) if !!value
      end
    end

    def merge!(other)
      other.each_pair do |path, value|
        self[path] = value
      end
    end

    def [](path)
      retreive(unpath(path))
    end

    def retreive(segments)
      if segments.empty?
        return @value
      else
        @children.each do |child|
          val = child.access(segments)
          return val unless val.nil?
        end
      end
      return nil
    end

    def access(segments)
      return retreive(segments.drop(1)) if match?(segments.first)
      return nil
    end

    def match?(segment)
      @segment == segment
    end

    def []=(pattern, result)
      store(unpath(pattern), result)
    end

    def ===(path)
      return !!self[path]
    end

    def store(segments, result)
      if segments.empty?
        @value = result
      else
        index = segments.shift
        target = @children.find {|child| child.segment == index } ||
          case index
          when "**"; DirGlob.new.tap{|m| @children << m}
          when /.*[*].*/; FileGlob.new(index).tap{|m| @children << m}
          else; PathMatcher.new(index).tap{|m| @children << m}
          end
        target.store(segments, result)
      end
    end
  end

  class DirGlob < PathMatcher
    def initialize
      super('**')
    end

    def match?(segment)
      true
    end

    def access(segments)
      if segments.empty?
        return nil
      else
        super || access(segments.drop(1))
      end
    end
  end

  class FileGlob < PathMatcher
    def initialize(segment)
      super
      @regex = %r{^#{segment.gsub(/[.]/, "[.]").gsub(/[*]/,".*")}$}
    end

    def match?(segment)
      @regex =~ segment
    end

    def store(segments, result)
      if segments.empty?
        @value = result
      else
        raise ArgumentError, "File globs can only be used as suffixes"
      end
    end
  end
end
