module GoldenFleece
  class Context
    module Schemas
      def define_schemas(attribute, schema_definitions = {})
        schemas[attribute.to_sym] ||= schema_definitions
        attributes << attribute
      end
    end
  end
end
