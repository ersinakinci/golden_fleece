module GoldenFleece
  module Model
    module ActiveModel
      module Normalization
        def self.included(base)
          base.class_eval do
            before_save do
              fleece_context.normalize_fleece
            end
          end
        end
      end
    end
  end
end
