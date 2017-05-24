require 'golden_fleece/type'

module GoldenFleece
  module Definitions
    TYPES = {
      array: Type.new(:array, Array),
      boolean: Type.new(:boolean, FalseClass, TrueClass),
      null: Type.new(:null, NilClass),
      number: Type.new(:number, Numeric),
      object: Type.new(:object, Hash),
      string: Type.new(:string, String)
    }.freeze
  end
end
