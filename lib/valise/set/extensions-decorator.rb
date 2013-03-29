require 'valise/set'

module Valise
  class Set
    class ExtensionsDecorator < Set
      def initialize(set)
        @set = set
        @extensions = []
      end
      attr_accessor :extensions
      attr_reader :set
      protected :set

      def inspect
        super + "x#{extensions.inspect}"
      end

      def search_roots
        set.search_roots
      end

      def merge_diff
        set.merge_diff
      end

      def serialization
        set.serialization
      end

      def get(path)
        set.get(path).exts(*extensions)
      end
    end
  end
end
