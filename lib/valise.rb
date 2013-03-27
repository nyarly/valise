require 'valise/set'
require 'valise/errors'

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
