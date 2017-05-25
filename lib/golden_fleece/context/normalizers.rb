require 'golden_fleece/normalizer'

module GoldenFleece
  class Context
    module Normalizers
      def define_normalizers(lambdas = {})
        lambdas.each do |name, fn|
          name = name.to_sym

          normalizers[name] = Normalizer.new(name, fn)
        end
      end
    end
  end
end
