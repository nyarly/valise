require 'valise/cache'
require 'valise/errors'
require 'valise/search-root'
require 'valise/utils'
require 'valise/stack'
require 'valise/path-matcher'
require 'valise/stem-decorator'
require 'valise/set/definer'
require 'valise/set/extensions-decorator'
require 'valise/set-filter'

module Valise
  class Set
    include Enumerable
    include Unpath

    def initialize
      @search_roots = []
      @merge_diff = PathMatcher.new
      @serialization = PathMatcher.new
      @cache = Cache.new
    end

    def inspect
      search_roots.inspect
    end

    def to_s(joiner=nil)
      search_roots.map(&:to_s).join(joiner||":")
    end

    def exts(*extensions)
      exts = ExtensionsDecorator.new(self)
      exts.extensions = extensions
      return exts
    end

    def pfxs(*prefixes)
      pfxs = PrefixesDecorator.new(self)
      pfxs.prefixes = prefixes
      return pfxs
    end

    def transform
      set = self.class.new
      set.search_roots = yield search_roots
      set.merge_diff = merge_diff.dup
      set.serialization = serialization.dup
      return set
    end

    def reverse
      transform do |roots|
        roots.reverse
      end
    end

    def sub_set(path)
      segments = make_pathname(path)
      transform do |roots|
        roots.map do |root|
          new_root = root.dup
          new_root.segments += segments
          new_root
        end
      end
    end

    def stemmed(path)
      segments = make_pathname(path)
      transform do |roots|
        roots.map do |root|
          StemDecorator.new(segments, root)
        end
      end
    end

    def not_above(root)
      index = search_roots.index(root)
      raise Errors::RootNotInSet if index.nil?
      transform do |roots|
        roots[index..-1]
      end
    end

    def below(root)
      index = search_roots.index(root)
      raise Errors::RootNotInSet if index.nil?
      transform do |roots|
        roots[(index+1)..-1]
      end
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
      search_roots.unshift(search_root)
    end

    def add_search_root(search_root)
      search_roots << search_root
    end

    def clean_pattern(pattern)
      #deprecation warning maybe
      pattern.sub(%r{^[*][*]/[*]}, '**')
    end

    def add_handler(segments, serialization_class, merge_diff_class)
      segments = clean_pattern(segments)
      add_serialization_handler(segments, serialization_class)
      add_merge_handler(segments, merge_diff_class)
    end

    def add_serialization_handler(pattern, serializer, options = nil)
      return if serializer.nil?
      Strategies::Serialization.check!(serializer)
      serialization[pattern] = [serializer, options]
    end

    def add_merge_handler(pattern, merger, options = nil)
      return if merger.nil?
      Strategies::MergeDiff.check!(merger)
      merge_diff[pattern] = [merger, options]
    end

    def +(other)
      result = self.class.new
      result.search_roots = search_roots + other.search_roots
      result.merge_handlers(*other.handler_lists)
      result.merge_handlers(*handler_lists)
      return result
    end

    attr_accessor :search_roots, :merge_diff, :serialization
    protected :search_roots=, :search_roots,
      :merge_diff=, :merge_diff,
      :serialization=, :serialization

    def merge_diff_for(stack)
      type, options = *(merge_diff[make_pathname(stack.segments)] || [])
      options = (options || {}).merge(:stack => stack)
      Strategies::MergeDiff.instance(type, options)
    end

    def serialization_for(stack)
      type, options = *serialization[make_pathname(stack.segments)]
      Strategies::Serialization.instance(type, options)
    end

    def merge_handlers(new_merge_diff, new_serialization)
      merge_diff.merge!(new_merge_diff)
      serialization.merge!(new_serialization)
    end

    def handler_lists
      [merge_diff, serialization]
    end

    def cached(domain, key)
      @cache.domain(domain)[key] ||= yield
    end

    def get(path)
      Stack.new(path, self)
    end

    def find(path)
      get(path).find
    end

    def contents(path)
      find(path).contents
    end

    def each(&block)
      search_roots.each(&block)
    end

    def filter(glob = nil, flags = nil)
      filter = SetFilter.new
      filter.set = self
      unless glob.nil?
        filter.include(glob, flags)
      end
      yield filter if block_given?
      return filter
    end

    def glob(path_matcher, &block)
      unless block_given?
        return self.enum_for(:glob, path_matcher)
      end

      filter(path_matcher).files(&block)
    end

    ALL_FILES = "**"
    def files(&block)
      glob(ALL_FILES, &block)
    end

    def depth_of(root)
      return search_roots.index(root)
    end

    def [](index)
      return search_roots[index]
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
