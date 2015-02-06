require 'valise/stack/decorator'
module Valise
  class Stack
    class PrefixesDecorator < Decorator
      def initialize(stack)
        super
        @prefixes = []
      end

      attr_accessor :prefixes

      def inspect
        "P#{prefixes.inspect}x#{@stack.inspect}"
      end

      def reget(root)
        decorated = self.new(super)
        decorated.prefixes = self.prefixes
        decorated
      end

      def sub_stack(stack, pfx)
        SinglePrefixDecorator.new(stack, self, pfx)
      end

      def decorate_item(item)
        @prefixes.each do |pfx|
          dec_stack = sub_stack(item.stack, pfx)
          yield(dec_stack.item_for(item.root))
        end
      end
    end

    class SinglePrefixDecorator < Decorator
      def initialize(stack, lead_decco, pfx)
        super(stack)
        @leader = lead_decco
        @pfx = pfx

        dir, file = *(stack.segments.split.map(&:to_s))
        @segments = make_pathname([dir, (pfx + file.to_s)])
      end

      def inspect
        @stack.inspect + "^#@pfx"
      end

      def segments
        @segments
      end

      def reget(root)
        @leader.reget(root)
      end
    end
  end
end
