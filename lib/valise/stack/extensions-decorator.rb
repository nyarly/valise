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
        decorated = self.class.new(super(root))
        decorated.extensions = self.extensions
        decorated
      end

      def sub_stack(stack, ext)
        SingleExtensionDecorator.new(stack, self, ext)
      end

      def decorate_item(item)
        @extensions.each do |ext|
          ext_stack = sub_stack(item.stack, ext)
          yield(ext_stack.item_for(item.root))
        end
      end
    end

    class SingleExtensionDecorator < Decorator
      def initialize(stack, lead_decco, ext)
        super(stack)
        @leader = lead_decco
        @ext = ext

        dir, file = *(stack.segments.split.map(&:to_s))
        @segments = make_pathname([dir, (file.to_s + ext)])
      end

      def inspect
        @stack.inspect + @ext
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
