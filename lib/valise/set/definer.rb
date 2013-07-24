require 'valise/utils'
require 'valise/search-root'
require 'valise/item'

module Valise
  class Set
    class StemmedDefiner
      include Unpath
      def initialize(path, set)
        @segments = make_pathname(path)
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

      def handle(path, serialization, merge_diff = nil)
        @target.add_handler(make_pathname(path),
                            serialization,
                            merge_diff)
      end

      def serialize(path, serialization, options = nil)
        @target.add_serialization_handler(path, serialization, options)
      end

      def merge(path, merge_diff, options = nil)
        @target.add_merge_diff_handler(path, merge_diff, options)
      end

      def defaults(name=nil, &block)
        loc = DefinedDefaults.define(&block)
        @target.add_search_root(loc)
      end
    end
  end
end
