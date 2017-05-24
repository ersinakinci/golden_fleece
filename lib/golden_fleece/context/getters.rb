module GoldenFleece
  class Context
    module Getters
      def define_getters(*attributes)
        # For each attribute...
        attributes.each do |attribute|
          # ...and each top-level schema of each attribute...
          schemas[attribute.to_sym].each do |config_name, schema|
            # ...if there isn't already an instance method named after the schema...
            if !model_class.new.respond_to?(config_name)
              # ...define a getter for that schema's value!
              model_class.class_eval do
                define_method config_name do
                  self.class.fleece_context.schemas[attribute.to_sym][config_name].value.compute(self)
                end
              end
            end
          end
        end
      end
    end
  end
end
