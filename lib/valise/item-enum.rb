module Valise
  module ItemEnum
    include Enumerable

    class Enumerator
      include ItemEnum

      def initialize(list, &filter)
        @list = list
        @filter = proc(&filter)
      end

      def each
        @list.each do |item|
          next unless @filter[item]
          yield(item)
        end
      end
    end

    def writable
      Enumerator.new(self) do |item|
        item.writable?
      end
    end

    def absent
      Enumerator.new(self) do |item|
        not item.present?
      end
    end

    def present
      Enumerator.new(self) do |item|
        item.present?
      end
    end
  end
end
