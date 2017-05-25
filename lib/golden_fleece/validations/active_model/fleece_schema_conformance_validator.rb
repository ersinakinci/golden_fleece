require 'active_model'
require 'golden_fleece/validations/validator_context'

module GoldenFleece
  module Validations
    module ActiveModel
      class FleeceSchemaConformanceValidator < ::ActiveModel::EachValidator
        def validate_each(record, attribute, persisted_json)
          context = record.class.fleece_context
          errors = ValidatorContext.new(record, attribute, persisted_json, context.schemas[attribute], '/').validate

          errors.each { |e| record.errors.add attribute, e }
          errors.empty?
        end
      end
    end
  end
end
