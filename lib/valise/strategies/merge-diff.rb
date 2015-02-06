require 'valise/strategies/set'

module Valise
  module Strategies
    class MergeDiff < Set
      def initialize(options)
        @stack = options[:stack]
      end

      class TopMost < MergeDiff
        register :topmost
        default

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
          merge_stack(@stack.not_above(item))
        end

        def merge_stack(stack)
          stack.present.reverse_each.inject({}) do |hash, item|
            deep_merge(hash, item.load_contents)
          end
        end

        def deep_merge(collect, item)
          item.each_pair do |key, value|
            case value
            when Hash
              existing = collect[key] ||= {}
              case existing
              when Hash
                deep_merge(existing, value)
              else
                collect[key] = value
              end
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
end
