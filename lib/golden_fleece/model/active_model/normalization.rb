require 'active_model'

module GoldenFleece
  module Model
    module ActiveModel
      module Normalization
        def self.included(base)
          base.class_eval do
            before_save do
              normalize_fleece
            end
          end
        end
      end
    end
  end
end
