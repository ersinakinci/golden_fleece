require 'golden_fleece/format'

module GoldenFleece
  class Context
    module Formats
      def define_formats(lambdas = {})
        lambdas.each do |name, fn|
          name = name.to_sym

          formats[name] = Format.new(name, fn)
        end
      end
    end
  end
end
