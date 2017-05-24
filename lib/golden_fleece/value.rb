require 'golden_fleece/definitions'
require 'hana'

module GoldenFleece
  class Value
    def initialize(schema)
      @schema = schema
      self.value_initialized = false
    end

    def compute(record)
      @record = record

      if dirty?
        @value = Hana::Pointer.new(schema.json_path).eval(record.read_attribute(schema.attribute))

        cast_booleans
        apply_normalizers
        apply_default

        self.value_initialized = true
      end

      value
    end

    private

    attr_accessor :value_initialized
    attr_reader :schema, :record, :value

    def dirty?
      record.send("#{schema.attribute}_changed?") || !value_initialized
    end

    # Cast boolean values the way that Rails normally does on boolean columns
    def cast_booleans
      if schema.types.include? Definitions::TYPES[:boolean]
        @value = ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
      end
    end

    def apply_normalizers
      @value = schema.normalizers.reduce(value) { |memo, normalizer| normalizer.call record, memo }
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
        value
      end
    end
  end
end
