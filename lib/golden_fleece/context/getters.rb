module GoldenFleece
  class Context
    module Getters
      def define_getters(*attributes)
        # For each attribute...
        attributes.each do |attribute|
          # ...and each top-level schema of each attribute...
          schemas[attribute.to_sym].each do |schema_name, schema|
            # ...if there isn't already an instance method named after the schema...
            if !model_class.method_defined?(schema_name)
              # ...define a getter for that schema's value!
              model_class.class_eval do
                define_method schema_name do
                  self.class.fleece_context.schemas[attribute.to_sym][schema_name].value.compute(self)
                end
              end
            end
          end
        end
      end
    end
  end
end
