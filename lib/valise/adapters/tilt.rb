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
    def templates(rel_path=nil)
      rel_path ||= "templates"
      new_set = self.sub_set(rel_path)
      new_set = new_set.exts(*([""] + Tilt.mappings.map{|mapping, _| "." + mapping}))
      ::Tilt.mappings.each do |mapping, _|
        options = nil
        if block_given?
          options = yield(mapping)
        end
        new_set.add_serialization_handler("**/*.#{mapping}", :tilt, options)
      end
      new_set
    end
  end
end
