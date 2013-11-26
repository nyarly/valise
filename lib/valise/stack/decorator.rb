require 'valise/stack'

module Valise
  class Stack
    class Decorator < Stack
      def initialize(stack)
        @stack = stack
        @stacks = Hash.new do |h,segments|
          h[segments] = @stack.valise.get(segments)
        end
      end

      def valise
        @stack.valise
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
          decorate_item(item){|decorated| yield(decorated)}
        end
      end
    end
  end
end
