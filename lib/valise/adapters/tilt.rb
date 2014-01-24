module Valise
  module Strategies
    class Serialization
      class Tilt < Serialization
        register :tilt

        def self.template_cache
          @template_cache ||= ::Tilt::Cache.new
        end

        def initialize(options)
          options ||= {}
          @template_options = options[:template_options] || {}
          @template_cache = options[:template_cache] || self.class.template_cache
        end

        def dump(item)
          super.data
        end

        def load(item)
          @template_cache.fetch(item.full_path, @template_options) do
            ::Tilt.new(item.full_path, @template_options) do |tmpl|
              super
            end
          end
        end
      end
    end
  end

  class Set
    class TiltTemplateConfiguration
      def initialize
        @template_types = {}
        @plain_files = true
      end

      attr_reader :template_types
      attr_accessor :plain_files

      def add_type(type, options)
        template_types[type] = options
      end

      def extensions
        template_types.keys.map{|type| ".#{type}"} + (@plain_files ? [""] : [])
      end

      def add_extenstions(set)
        set.exts(*extensions)
      end

      def add_serializations(set)
        template_types.each do |mapping, options|
          set.add_serialization_handler("**.#{mapping}", :tilt, options)
        end
      end

      def apply(set)
        set = add_extenstions(set)
        add_serializations(set)
        set
      end
    end

    def handle_templates(&block)
      config = TiltTemplateConfiguration.new

      if block.arity == 1
        yield config
      else
        config.instance_eval(&block)
      end

      config.apply(self)
    end

    def default_mappings
      if ::Tilt.respond_to? :default_mapping
        mapping = ::Tile.default_mapping
        mapping.template_map.merge(mapping.lazy_map).keys
      else
        ::Tilt.mappings.keys
      end
    rescue => ex
      warn "Couldn't access Tilt's default template mappings"
      warn "  The specific error was #{ex}"
      warn "  Falling back to an *empty* template list"
      warn "  To add by hand, change #templates to #handle_template{|cfg| cfg.add_type('ext') }"
      []
    end

    def templates(rel_path=nil)
      rel_path ||= "templates"
      new_set = self.sub_set(rel_path)
      new_set = new_set.pfxs("", "_")
      new_set.handle_templates do |config|
        ::Tilt.mappings.each do |mapping, _|
          options = nil
          if block_given?
            options = yield(mapping)
          end
          config.add_type(mapping, options)
        end
      end
    end
  end
end
