
module Valise
  module Adapters
    def self.adapter_for(library, valise_file=nil)
      begin
        require library
      rescue LoadError
        return false
      end

      valise_file ||= "valise/adapters/#{library}"
      require valise_file
      return true
    end

    adapter_for "tilt"
  end
end
