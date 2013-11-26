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
        "#{prefixes.inspect}x#{@stack.inspect}"
      end

      def reget(root)
        decorated = self.new(super)
        decorated.prefixes = self.prefixes
        decorated
      end

      def decorate_item(item)
        dir, file = *item.segments.split
        @prefixes.each do |pfx|
          dec_stack = @stacks[dir + (pfx + file.to_s)]
          yield(dec_stack.item_for(item.root))
        end
      end
    end
  end
end
