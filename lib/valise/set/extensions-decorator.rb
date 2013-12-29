require 'valise/set'

module Valise
  class Set
    class Decorator < Set
      def initialize(set)
        @set = set
      end

      attr_reader :set
      protected :set

      def search_roots
        set.search_roots
      end

      def merge_diff
        set.merge_diff
      end

      def serialization
        set.serialization
      end
    end

    class PrefixesDecorator < Decorator
      def initialize(set)
        super
        @prefixes = []
      end
      attr_accessor :prefixes

      def inspect
        "#{prefixes.inspect}x#{set.inspect}"
      end

      def get(path)
        set.get(path).exts(*prefixes)
      end
    end

    class ExtensionsDecorator < Decorator
      def initialize(set)
        super
        @extensions = []
      end
      attr_accessor :extensions

      def inspect
        "#{set.inspect}x#{extensions.inspect}"
      end

      def get(path)
        set.get(path).exts(*extensions)
      end
    end
  end
end
