require 'valise/path-matcher'

module Valise
  class SetFilter
    def initialize
      @path_matcher = PathMatcher.new
      @set = nil
    end
    attr_reader :path_matcher
    attr_accessor :set

    def include(pattern, flags = nil)
      path_matcher.set(pattern, true, flags)
    end

    def exclude(pattern, flags = nil)
      path_matcher.set(pattern, false, flags)
    end

    def files
      visited = {}
      set.each do |root|
        root.each do |segments|
          next unless path_matcher === segments
          unless visited.has_key?(segments)
            item = set.get(segments).present.first
            visited[segments] = item
            yield(item)
          end
        end
      end
      return visited
    end
  end
end
