module GoldenFleece
  module Model
    module Export
      def self.included(base)
        base.class_eval do
          def export_fleece(attribs = self.class.fleece_context.attributes)
            self.class.fleece_context.export self, attribs
          end
        end
      end
    end
  end
end
