# New plan here: Stack is returned by "find" and responds to many of the
# methods that Item current responds to.  It caches results, essentially, of
# the find search - maybe at creation, with possiblity for reload/update.
# Also, makes possible use cases like file promotion, merging, etc.
#
# Still need to resolve the interface for parsing and merging files.
#
# * something from the Valise definition - would have to be part of defaults,
# which further is a problem if a file doesn't exist in the defaults
#
# * a filetype mapping
#
# * Is it a find-time user thing

require 'valise/utils'

module Valise
  module ItemEnum
    include Enumerable

    class Enumerator
      include ItemEnum

      def initialize(list, &filter)
        @list = list
        @filter = proc(&filter)
      end

      def each
        @list.each do |item|
          next unless @filter[item]
          yield(item)
        end
      end
    end

    def writable
      Enumerator.new(self) do |item|
        item.writable?
      end
    end

    def absent
      Enumerator.new(self) do |item|
        not item.present?
      end
    end

    def present
      Enumerator.new(self) do |item|
        item.present?
      end
    end
  end

  class MergeDiff
    @@classes = {}
    def self.[](index)
      @@classes[index]
    end

    def self.register(index)
      @@classes[index] = self
    end

    def initialize(stack)
      @stack = stack
    end

    class TopMost < MergeDiff
      register :topmost

      def merge(item)
        item.load_contents
      end

      def diff(item, value)
        value
      end
    end

    class HashMerge < MergeDiff
      register :hash_merge

      def merge(item)
        merge_stack(@stack.not_above(item).reverse)
      end

      def merge_stack(stack)
        stack.present.inject({}) do |hash, item|
          deep_merge(hash, item.load_contents)
        end
      end

      def deep_merge(collect, item)
        item.each_pair do |key, value|
          case value
          when Hash
            collect[key] ||= {}
            deep_merge(collect[key], value)
          else
            collect[key] = value
          end
        end
        collect
      end

      def diff(item, new_contents)
        diff_with = merge_stack(@stack.below(item).reverse)
        result = new_contents.dup

        diff_with.each_pair do |key, value|
          if result.has_key?(key)
            if result[key] == value
              result.delete(key)
            end
          else
            result[key] = nil
          end
        end

        result
      end
    end
  end

  class Stack
    include Unpath
    include ItemEnum

    def inspect
      "<default>:#{@segments.join "/"} #{@valise.inspect}"
    end

    def initialize(path, set, merge_class, dump_load)
      @segments = collapse(unpath(path))
      @valise = set
      @merge_diff = (merge_class || MergeDiff::TopMost).new(self)
      @dump_load = dump_load
    end

    attr_reader :segments, :valise

    def rel_path
      repath(@segments)
    end

    def merged(item)
      @merge_diff.merge(item)
    end

    def diffed(item, value)
      @merge_diff.diff(item, value)
    end

    def not_above(item)
      reget(valise.not_above(item.root))
    end

    def below(item)
      reget(valise.below(item.root))
    end

    def reverse
      reget(valise.reverse)
    end

    def depth_of(item)
      valise.depth_of(item.root)
    end

    def find
      item = present.first
      return item unless item.nil?
      raise Errors::NotFound, "#{rel_path} not found in #{@valise.inspect}"
    end

    def exts(*extensions)
      exts = ExtensionsSearchDecorator.new(self)
      exts.extensions = extensions
      return exts
    end

    def reget(root)
      root.get(@segments)
    end

    def item_for(root)
      Item.new(self, root, @dump_load)
    end

    def each
      valise.each do |root|
        yield(item_for(root))
      end
    end
  end

  class ExtensionsSearchDecorator < Stack
    def initialize(stack)
      @stack = stack
      @extensions = []
      @stacks = Hash.new{|h,segments| h[segments] = @stack.valise.get(segments) }
    end

    attr_accessor :extensions

    def valise
      @stack.valise
    end

    def reget(root)
      decorated = self.new(super)
      decorated.extensions = self.extensions
      decorated
    end

    def merged(item)
      item.stack.merged(item)
    end

    def diffed(item, value)
      item.stack.diffed(item, value)
    end

    def rel_path
      @stack.rel_path
    end

    def each
      return enum_for(:each) unless block_given?
      @stack.each do |item|
        @extensions.each do |ext|
          dir = item.segments.dup
          file = dir.pop
          ext_stack = @stacks[dir + [file + ext]]
          yield(ext_stack.item_for(item.root))
        end
      end
    end
  end
end
