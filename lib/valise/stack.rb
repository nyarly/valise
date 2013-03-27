require 'valise/utils'
require 'valise/item-enum'
require 'valise/merge-diff'
require 'valise/stack/extensions-decorator'

module Valise
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
      exts = ExtensionsDecorator.new(self)
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
end
