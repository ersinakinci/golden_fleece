require 'golden_fleece/normalizer'

module GoldenFleece
  class Context
    module Normalizers
      def normalize_fleece
        schemas.each do |attribute, schema|
          persisted_json = read_attribute attribute

          schema.each do |schema_name, schema|
            schema_name = schema_name.to_s
            computed_json = schema.value.compute(self)
            computed_json.deep_stringify_keys! if computed_json.is_a? Hash

            if !persisted_json[schema_name].nil? && persisted_json[schema_name] != computed_json
              write_attribute attribute, computed_json
            end
          end
        end
      end

      def define_normalizers(lambdas = {})
        lambdas.each do |name, fn|
          name = name.to_sym

          normalizers[name] = Normalizer.new(name, fn)
        end
      end
    end
  end
end
