module Valise
  class MergeDiff
    @@classes = {}
    def self.[](index)
      @@classes[index]
    end

    def self.register(index)
      @@classes[index] = self
    end

    def initialize(stack)
      @stack = stack
    end

    class TopMost < MergeDiff
      register :topmost

      def merge(item)
        item.load_contents
      end

      def diff(item, value)
        value
      end
    end

    class HashMerge < MergeDiff
      register :hash_merge

      def merge(item)
        merge_stack(@stack.not_above(item).reverse)
      end

      def merge_stack(stack)
        stack.present.inject({}) do |hash, item|
          deep_merge(hash, item.load_contents)
        end
      end

      def deep_merge(collect, item)
        item.each_pair do |key, value|
          case value
          when Hash
            collect[key] ||= {}
            deep_merge(collect[key], value)
          else
            collect[key] = value
          end
        end
        collect
      end

      def diff(item, new_contents)
        diff_with = merge_stack(@stack.below(item).reverse)
        result = new_contents.dup

        diff_with.each_pair do |key, value|
          if result.has_key?(key)
            if result[key] == value
              result.delete(key)
            end
          else
            result[key] = nil
          end
        end

        result
      end
    end
  end
end
