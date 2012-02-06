require 'valise/errors'
require 'valise/search-root'
require 'valise/utils'
require 'valise/stack'
require 'valise/path-matcher'
require 'valise/stem-decorator'

module Valise
  module Debugging
    def remark
    end

    class << self
      attr_reader :remark_to

      def enable(destination)
        @remark_to = destination
        class_eval do
          def remark
            self.class.remark_to.puts(yield)
          end
        end
      end
    end
  end

  class Set
    include Debugging
    include Enumerable

    class StemmedDefiner
      include Unpath
      def initialize(path, set)
        @segments = unpath(path)
        @target = set
      end

      def rw(name)
        @target.add_search_root(
          StemDecorator.new(@segments, SearchRoot.new(name)))
      end

      def ro(name)
        @target.add_search_root(
          StemDecorator.new(@segments, ReadOnlySearchRoot.new(name)))
      end
    end

    class Definer
      include Unpath
      def initialize(set)
        @target = set
      end

      def rw(name, path = nil)
        @target.add_search_root(SearchRoot.new(name))
      end

      def ro(name, path = nil)
        @target.add_search_root(ReadOnlySearchRoot.new(name))
      end

      def stemmed(path, &block)
        definer = StemmedDefiner.new(path, @target)
        definer.instance_eval(&block) unless block.nil?
        return definer
      end

      def from_here(rel_path)
        m = /(.*):\d+/.match(caller[0])
        dir = ::File::dirname(::File::expand_path(m[1]))

        unpath(dir) + unpath(rel_path)
      end

      def handle(path, serialization, merge_diff = nil)
        @target.add_handler(unpath(path),
                            Valise::Serialization[serialization],
                            Valise::MergeDiff[merge_diff])
      end

      def defaults(name=nil, &block)
        loc = DefinedDefaults.define(&block)
        @target.add_search_root(loc)
      end
    end

    def initialize
      @search_roots = []
      @merge_diff = PathMatcher.new
      @serialization = PathMatcher.new
    end

    def inspect
      @search_roots.inspect
    end

    def reverse
      set = Set.new
      set.search_roots = @search_roots.reverse
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

    attr_accessor :search_roots
    protected :search_roots, :search_roots=

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
      raise "#{path} not found in #{@search_roots.inspect}"
    end

    def each(&block)
      @search_roots.each(&block)
    end

    def files
      unless block_given?
        return self.enum_for(:files)
      end

      visited = {}
      @search_roots.each do |root|
        root.each do |segments|
          unless visited.has_key?(segments)
            item = find(segments)
            visited[segments] = item
            yield(item)
          end
        end
      end
      return visited
    end

    def not_above(root)
      index = @search_roots.index(root)
      raise RootNotInSet if index.nil?
      set = self.class.new
      set.search_roots = @search_roots[index..-1]
      set
    end

    def below(root)
      index = @search_roots.index(root)
      raise RootNotInSet if index.nil?
      set = self.class.new
      set.search_roots = @search_roots[(index+1)..-1]
      set
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
