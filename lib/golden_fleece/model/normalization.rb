module GoldenFleece
  module Model
    module Normalization
      include Utility

      def normalize_fleece
        self.class.fleece_context.schemas.each do |attribute, schema|
          persisted_json = read_attribute attribute

          schema.each do |schema_name, schema|
            schema_name = schema_name.to_s
            computed_json = { schema_name => schema.value.compute(self) }
            deep_stringify_keys computed_json if computed_json.is_a? Hash

            if !persisted_json[schema_name].nil? && persisted_json[schema_name] != computed_json[schema_name]
              write_attribute attribute, computed_json
            end
          end
        end
      end
    end
  end
end
