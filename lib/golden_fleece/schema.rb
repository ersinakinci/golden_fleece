require 'golden_fleece/definitions'
require 'golden_fleece/schema'
require 'golden_fleece/utility'

module GoldenFleece
  class Schema
    include Utility

    attr_reader :attribute, :name, :path, :json_path, :types, :normalizers, :format, :value, :default

    def initialize(context, path, definitions)
      @context = context
      @path = path
      @name = path.split("/").last
      @attribute = path.split("/")[1]
      @json_path = path.split("/")[2..-1]
      @json_path = @json_path.join("/") if @json_path
      @subschemas = {}

      # .count == 1 means we're at the root
      # .count == 2 means we're at the attribute
      # .count >= 3 means we're cookin'
      if path.split("/").count <= 2
        @types = [Definitions::TYPES[:object]]
        map_subschemas(definitions)
      else
        map_value
        map_types(definitions[:type], definitions[:types])
        map_normalizers(definitions[:normalizer], definitions[:normalizers])
        map_format(definitions[:format])
        map_default(definitions[:default])
        map_subschemas(definitions[:subschemas])
      end
    end

    def [](subschema_name)
      subschemas[subschema_name]
    end

    def []=(subschema_name, subschema_definition)
      subschemas[subschema_name] = Schema.new(context, build_json_path(path, subschema_name), subschema_definition)
    end

    def each(&block)
      subschemas.each(&block)
    end

    def reduce(memo, &block)
      subschemas.reduce(memo, &block)
    end

    def parent?
      subschemas.count > 0
    end

    def keys
      subschemas.keys
    end

    def values
      subschemas.values
    end

    private

    attr_reader :context, :subschemas

    def map_value
      @value = Value.new self
    end

    def map_types(*args)
      @types = args.flatten.compact.map { |type|
        type = type.to_sym

        raise ArgumentError.new("Invalid type '#{type}' specified for #{error_suffix(attribute, json_path)}}") unless Definitions::TYPES.include? type

        Definitions::TYPES[type]
      }.uniq
    end

    def map_normalizers(*args)
      @normalizers = args.flatten.compact.map { |normalizer|
        normalizer = normalizer.to_sym

        raise ArgumentError.new("Invalid normalizer(s) '#{normalizer}' specified for #{error_suffix(attribute, json_path)}") unless context.normalizers.include?(normalizer)

        context.normalizers[normalizer]
      }.uniq
    end

    def map_format(fmt)
      unless fmt.nil?
        fmt = fmt.to_sym

        raise ArgumentError.new("Invalid format '#{fmt}' specified for #{error_suffix(attribute, json_path)}") unless context.formats.include?(fmt)

        @format = context.formats[fmt]
      end
    end

    def map_default(default)
      @default = default
    end

    def map_subschemas(subschema_definitions)
      @subschemas = subschema_definitions.reduce({}) { |memo, (subschema_name, subschema_definition)|
        raise ArgumentError.new("'subschemas' option can only be set for 'object' type schemas, attempted to provide subschemas for #{error_suffix(attribute, json_path)}") unless types.include? Definitions::TYPES[:object]
        raise ArgumentError.new("The 'subschemas' option must be passed a hash, please check #{error_suffix(attribute, json_path)}") unless subschema_definition.is_a?(Hash)

        subschema_path = build_json_path(path, subschema_name)
        memo[subschema_name] = Schema.new(context, subschema_path, subschema_definition)
        memo
      } if subschema_definitions.present?
    end
  end
end
