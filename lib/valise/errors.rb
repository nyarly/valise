module Valise
  module Errors
    class Error < ::Exception; end

    class PathOutsideOfRoot < Error; end
    class PathNotInRoot < Error; end
    class PathNotFound < Error; end
    class ReadOnly < Error; end
    class NotFound < Error; end
    class VirtualSearchPath < Error; end
    class MalformedTree < Error; end
    class RootNotInSet < Error; end
    class UnderIndented < Error; end

    class UnregisteredStrategy < Error
      def initialize(klass, type)
        super("No #{klass} strategy is registered for #{type.inspect}")
      end
    end

    class CantPopulate < Error
      def initialize(item, cause)
        @item = item
        @original_exception = cause
        super("Couldn't populate #{item.segments.inspect}: #{cause.class}: #{cause.message}")
      end

      attr_reader :item, :original_exception
    end
  end
end
