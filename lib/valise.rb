require 'valise/set'
require 'valise/errors'

module Valise
  def self.define(&block)
    Valise::Set.define(&block)
  end
end
