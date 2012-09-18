require 'valise/utils'

module Valise
  class SubSet
    include Unpath

    def initialize(source, sub_path)
      @source = source
      @sub_path = unpath(sub_path)
    end

    def find(path)
      @source.find(@sub_path + unpath(path))
    end

    def glob(path)
      @source.glob(@sub_path + unpath(path))
    end
  end
end
