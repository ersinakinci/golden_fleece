require 'golden_fleece/definitions'
require 'hana'

module GoldenFleece
  class Value
    include Utility

    def initialize(schema)
      @schema = schema
    end

    def compute(record)
      @record = record
      @value = Hana::Pointer.new(schema.json_path).eval(record.read_attribute(schema.attribute))

      cast_booleans
      apply_normalizers
      apply_default

      value
    end

    private

    attr_reader :schema, :record, :value

    # Cast boolean values the way that Rails normally does on boolean columns
    def cast_booleans
      if schema.types.include? Definitions::TYPES[:boolean]
        @value = cast_boolean(value)
      end
    end

    def apply_normalizers
      @value = schema.normalizers.reduce(value) { |memo, normalizer| normalizer.normalize record, memo }
    end

    # If there's a persisted value, use that
    # If not, use the default value; if the default is a lambda, call it
    def apply_default
      @value = if value.nil?
        if schema.parent?
          d = schema.reduce({}) { |memo, (subschema_name, subschema)|
            memo[subschema_name] = subschema.value.compute(record)
            memo
          }
          d.values.compact.empty? ? nil : d
        elsif schema.default.respond_to?(:call)
          schema.default.call(record)
        else
          schema.default
        end
      else
        value.is_a?(Hash) ? deep_symbolize_keys(value) : value
      end
    end
  end
end
