require 'active_model'
require 'golden_fleece/validations/active_model/fleece_schema_conformance_validator'

module GoldenFleece
  module Model
    module ActiveModel
      module Validation
        def self.included(base)
          base.class_eval do
            validate_attributes = -> fleece_context {
              fleece_context.model_class.class_eval do
                validates *fleece_context.attributes, 'GoldenFleece::Validations::ActiveModel::FleeceSchemaConformance' => true
              end
            }

            fleece_context.setup_callbacks << validate_attributes
          end
        end
      end
    end
  end
end
