require 'weakref'

module Valise
  class Cache
    class Store
      def initialize
        @hash = {}
      end

      def []=(key, object)
        @hash[key] = WeakRef.new(object)
      end

      def [](key)
        ref = @hash.fetch(key) do
          return nil
        end
        return live_ref(key, ref)
      rescue WeakRef::RefError
        nil
      end

      def live_ref(key, ref)
        ref.__getobj__
      rescue WeakRef::RefError
        @hash.delete(key)
        raise
      end

      def has_key?(key)
        ref = @hash.fetch(key) do
          false
        end
        live_ref(key, ref)
        true
      rescue WeakRef::RefError
        false
      end
    end

    def initialize
      @stores = Hash.new{|h,k| h[k] = Store.new}
    end

    def domain(key)
      @stores[key]
    end
  end
end
