module GoldenFleece
  class Context
    module Schemas
      def define_schemas(attribute, schema_definitions = {})
        attribute_schema = schemas[attribute.to_sym]

        # Allow redefining individual schemas
        if attribute_schema
          schema_definitions.each do |schema_name, schema_definition|
            schemas[attribute.to_sym][schema_name.to_sym] = schema_definition
          end
        else
          schemas[attribute.to_sym] = schema_definitions
        end

        attributes << attribute unless attributes.include? attribute
      end
    end
  end
end
