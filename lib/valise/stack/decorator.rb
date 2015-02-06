require 'valise/stack'

module Valise
  class Stack
    class Decorator < Stack
      def initialize(stack)
        @stack = stack
        @stacks = {}
      end

      def sub_stack(segments)
        @stacks[segments] ||= @stack.valise.get(segments)
      end

      def segments
        @stack.segments
      end

      def valise
        @stack.valise
      end

      def rel_path
        @stack.rel_path
      end

      def each
        return enum_for(:each) unless block_given?
        @stack.each do |item|
          decorate_item(item){|decorated| yield(decorated)}
        end
      end
    end
  end
end
