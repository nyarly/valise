module Valise
  module Debugging
    def remark
    end

    class << self
      attr_reader :remark_to

      def enable(destination)
        @remark_to = destination
        class_eval do
          def remark
            self.class.remark_to.puts(yield)
          end
        end
      end
    end
  end
end
