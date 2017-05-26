module GoldenFleece
  module Model
    module Normalization
      include Utility

      def normalize_fleece
        self.class.fleece_context.schemas.each do |attribute, schema|
          persisted_json = read_attribute attribute
          computed_json = deep_stringify_keys schema.reduce({}) { |memo, (schema_name, schema)|
            memo[schema_name] = schema.value.compute(self)
            memo
          }

          if !persisted_json.nil? && persisted_json != computed_json
            write_attribute attribute, computed_json
          end
        end
      end
    end
  end
end
