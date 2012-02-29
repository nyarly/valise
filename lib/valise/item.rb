require 'yaml'
require 'valise/utils'

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

  class Item
    include Unpath

    def initialize(stack, root, dump_load)
      @stack = stack
      @root = root
      @dump_load = dump_load || Serialization::Raw
      @contents = nil
    end

    attr_reader :stack, :root
    attr_accessor :contents

    def inspect
      "#{@root.inspect}//#{@stack.inspect}"
    end

    def segments
      @stack.segments
    end

    def full_path
      @root.full_path(segments)
    end

    def writable?
      @root.writable?(segments)
    end

    def present?
      @root.present?(segments)
    end

    def raw_file
      File::open(full_path)
    end

    def open(&block)
      File::open(full_path, "r", &block)
    end

    def save
      root.write(self)
    end

    def contents
      return @stack.merged(self)
    end

    def contents=(value)
      @contents = @stack.diffed(self, value)
      save
      @contents
    end

    def dump_contents
      @dump_load.dump(load_contents) #@contents?
    end

    def load_contents
      @contents ||= @dump_load.load(@root.get_from(self))
    end
  end
end
