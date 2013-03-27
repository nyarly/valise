module Valise
  class Serialization
    @@classes = {}

    class << self
      def [](index)
        @@classes[index]
      end

      def register(index)
        @@classes[index] = self
      end
    end

    class Raw < Serialization
      register :raw

      def self.dump(value)
        value
      end

      def self.load(raw)
        raw
      end
    end

    class YAML < Serialization
      register :yaml

      def self.dump(value)
        ::YAML::dump(value)
      end

      def self.load(raw)
        ::YAML::load(raw)
      end
    end
  end
end
