require 'valise/debugging'
require 'valise/errors'
require 'valise/search-root'
require 'valise/utils'
require 'valise/stack'
require 'valise/path-matcher'
require 'valise/stem-decorator'
require 'valise/set/definer'
require 'valise/sub-set'

module Valise
  class Set
    include Debugging
    include Enumerable

    def initialize
      @search_roots = []
      @merge_diff = PathMatcher.new
      @serialization = PathMatcher.new
    end

    def inspect
      @search_roots.inspect
    end

    def to_s
      @search_roots.map(&:to_s).join(":")
    end

    def reverse
      set = Set.new
      set.search_roots = @search_roots.reverse
      set.merge_diff = @merge_diff.dup
      set.serialization = @serialization.dup
      set
    end

    def sub_set(path)
      set = Set.new
      set.search_roots = @search_roots.map do |root|
        SearchRoot.new(root.segments + path)
      end
      set.merge_diff = @merge_diff.dup
      set.serialization = @serialization.dup
      set
    end

    def define(&block)
      definer = Definer.new(self)
      definer.instance_eval(&block)
      return self
    end

    def self.define(&block)
      return self.new.define(&block)
    end

    def prepend_search_root(search_root)
      @search_roots.unshift(search_root)
    end

    def add_search_root(search_root)
      @search_roots << search_root
    end

    def add_handler(segments, serialization_class, merge_diff_class)
      @merge_diff[segments] = merge_diff_class unless merge_diff_class.nil?
      @serialization[segments] = serialization_class unless serialization_class.nil?
    end

    def +(other)
      result = self.class.new
      result.search_roots = @search_roots + other.search_roots
      result.merge_handlers(*other.handler_lists)
      result.merge_handlers(*handler_lists)
      return result
    end

    attr_accessor :search_roots, :merge_diff, :serialization
    protected :search_roots=, :search_roots,
      :merge_diff=, :merge_diff,
      :serialization=, :serialization

    include Unpath
    def get(path)
      return Stack.new(path, self,
                       merge_diff(path),
                       serialization(path))
    end

    def merge_diff(path)
      @merge_diff[unpath(path)]
    end

    def serialization(path)
      @serialization[unpath(path)]
    end

    def merge_handlers(merge_diff, serialization)
      @merge_diff.merge!(merge_diff)
      @serialization.merge!(serialization)
    end

    def handler_lists
      [@merge_diff, @serialization]
    end

    def find(path)
      item = get(path).present.first
      return item unless item.nil?
      raise Errors::NotFound, "#{path} not found in #{@search_roots.inspect}"
    end

    def each(&block)
      @search_roots.each(&block)
    end

    def glob(path_matcher)
      unless block_given?
        return self.enum_for(:glob, path_matcher)
      end

      visited = {}
      path_matcher = PathMatcher.build(path_matcher)

      @search_roots.each do |root|
        root.each do |segments|
          next unless path_matcher === segments
          unless visited.has_key?(segments)
            item = get(segments).present.first
            visited[segments] = item
            yield(item)
          end
        end
      end
      return visited
    end

    ALL_FILES = PathMatcher.build("**")
    def files(&block)
      glob(ALL_FILES, &block)
    end

    def not_above(root)
      index = @search_roots.index(root)
      raise Errors::RootNotInSet if index.nil?
      set = self.class.new
      set.search_roots = @search_roots[index..-1]
      set
    end

    def below(root)
      index = @search_roots.index(root)
      raise Errors::RootNotInSet if index.nil?
      set = self.class.new
      set.search_roots = @search_roots[(index+1)..-1]
      set
    end

    def depth_of(root)
      return @search_roots.index(root)
    end

    def [](index)
      return @search_roots[index]
    end

    def populate(to = self)
      files do |item|
        contents = item.contents
        to_stack = to.get(item.segments)
        to_stack = yield(to_stack) if block_given?
        target = to_stack.writable.first
        next if target.present?
        target.contents = contents
      end
    end
  end
end
