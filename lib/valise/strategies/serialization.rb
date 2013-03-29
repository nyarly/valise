require 'valise/strategies/set'

module Valise
  module Strategies
    class Serialization < Set
      register :raw
      default

      def initialize(options)
      end

      def dump(item)
        item.load_contents
      end

      def load(item)
        item.raw_contents
      end

      class YAML < Serialization
        register :yaml

        def dump(item)
          ::YAML::dump(super)
        end

        def load(item)
          ::YAML::load(super)
        end
      end
    end
  end
end
