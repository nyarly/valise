require 'valise/stack'

module Valise
  class Stack
    class ExtensionsDecorator < Stack
      def initialize(stack)
        @stack = stack
        @extensions = []
        @stacks = Hash.new do |h,segments|
          h[segments] = @stack.valise.get(segments)
        end
      end

      attr_accessor :extensions

      def inspect
        @stack.inspect + "x#{extensions.inspect}"
      end

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
            dir, file = *item.segments.split
            ext_stack = @stacks[dir + (file.to_s + ext)]
            yield(ext_stack.item_for(item.root))
          end
        end
      end
    end
  end
end
