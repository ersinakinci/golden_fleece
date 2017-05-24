module GoldenFleece
  class Context
    module Export
      def export(record, export_attributes)
        export_attributes = Array.wrap export_attributes

        schemas.reduce({}) { |memo, (attribute, schema)|
          if export_attributes.include? attribute
            memo[attribute] = schema.reduce({}) { |memo, (schema_name, schema)|
              memo[schema_name] = schema.value.compute(record)
              memo
            }
          end
          memo
        }
      end
    end
  end
end
