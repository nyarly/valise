require 'valise/errors'

module Valise
  module Strategies
    class Set
      class << self
        def root_class(&block)
          if superclass == Valise::Strategies::Set
            instance_eval(&block)
          elsif self == Valise::Strategies::Set
            raise "Complete class hierarchy fail"
          else
            superclass.root_class(&block)
          end
        end

        def classes
          root_class{@classes ||= {}}
        end

        def instances
          root_class{@instances ||= {}}
        end

        def [](index)
          classes[index]
        end

        def register(index)
          classes[index] = self
        end

        def set_default(klass)
          classes.default = klass
        end

        def default
          set_default(self)
        end

        def check!(type)
          classes.fetch(type)
        rescue KeyError
          raise Errors::UnregisteredStrategy.new(self.name, type)
        end

        def instance(type, options = nil)
          instances[[type, options]] ||= classes[type].new(options)
        end
      end
    end
  end
end
