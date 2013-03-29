require 'valise/set'
require 'valise/errors'
require 'valise/adapters'

module Valise
  def self.define(&block)
    Valise::Set.define(&block)
  end

  def self.read_only(*dirs)
    Valise::Set.define do
      dirs.each do |dir|
        ro dir
      end
    end
  end
end
