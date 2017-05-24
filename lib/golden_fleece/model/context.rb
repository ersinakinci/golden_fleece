require 'golden_fleece/context'
require 'pry'

module GoldenFleece
  module Model
    module Context
      def self.included(base)
        base.extend ClassMethods

        base.instance_eval do
          @fleece_context = GoldenFleece::Context.new(self)
        end
      end

      module ClassMethods
        attr_reader :fleece_context

        def fleece(&block)
          fleece_context.instance_eval(&block)
          fleece_context.run_setup_callbacks
        end
      end
    end
  end
end
