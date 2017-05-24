require "golden_fleece/model/context"
require "golden_fleece/model/export"
require "golden_fleece/model/active_model/normalization"
require "golden_fleece/model/active_model/validation"

module GoldenFleece
  module Model
    def self.included(base)
      # Include ORM-specific modules depending on what ORM we're using
      orm = if defined? ::ActiveModel
        "ActiveModel"
      end
      orm_module = "GoldenFleece::Model::#{orm}".constantize

      base.class_eval do
        include GoldenFleece::Model::Context
        include GoldenFleece::Model::Export
        include orm_module::Normalization
        include orm_module::Validation
      end
    end
  end
end
