require 'valise/stack/decorator'
module Valise
  class Stack
    class ExtensionsDecorator < Decorator
      def initialize(stack)
        super
        @extensions = []
      end

      attr_accessor :extensions

      def inspect
        @stack.inspect + "xS#{extensions.inspect}"
      end

      def reget(root)
        decorated = self.new(super)
        decorated.extensions = self.extensions
        decorated
      end

      def decorate_item(item)
        dir, file = *item.segments.split
        @extensions.each do |ext|
          ext_stack = @stacks[dir + (file.to_s + ext)]
          yield(ext_stack.item_for(item.root))
        end
      end
    end
  end
end
