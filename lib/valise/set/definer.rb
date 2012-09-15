require 'valise/utils'
require 'valise/search-root'
require 'valise/item'

module Valise
  class Set
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
  end
end
