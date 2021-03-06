require 'valise/utils'
require 'valise/item-enum'
require 'valise/strategies/merge-diff'
require 'valise/stack/extensions-decorator'
require 'valise/stack/prefixes-decorator'

module Valise
  class Stack
    include Unpath
    include ItemEnum

    def inspect
      "<default>:#{(@segments||%{?})} #{@valise.inspect}"
    end

    def initialize(path, set)
      @segments = make_pathname(path)
      @valise = set
    end

    attr_reader :segments, :valise

    def rel_path
      @segments
    end

    def merge_diff
      valise.merge_diff_for(self)
    end

    def dump_load
      valise.serialization_for(self)
    end

    def merged(item)
      merge_diff.merge(item)
    end

    def diffed(item, value)
      merge_diff.diff(item, value)
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

    def raw_find
      item = present.first
      return item unless item.nil?
      raise Errors::NotFound, "#{self.inspect} not found"
    end

    def find
      valise.cached(:find, rel_path) do
        raw_find
      end
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

    def reget(root)
      root.get(segments)
    end

    def item_for(root)
      Item.new(self, root, dump_load)
    end

    def each
      valise.each do |root|
        yield(item_for(root))
      end
    end
  end
end
