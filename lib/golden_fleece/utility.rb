module GoldenFleece
  module Utility
    FALSE_VALUES = [false, 0, "0", "f", "F", "false", "FALSE", "off", "OFF"].to_set

    def build_json_path(parent_path, key_name)
      "#{parent_path}#{'/' unless parent_path =~ /\/$/}#{key_name}"
    end

    def error_suffix(attribute, path)
      "'#{path}' on column '#{attribute}'"
    end

    # Copied from ActiveModel::Type::Boolean
    # https://github.com/rails/rails/blob/master/activemodel/lib/active_model/type/boolean.rb
    def cast_boolean(value)
      if value == ""
        nil
      else
        !FALSE_VALUES.include?(value)
      end
    end
  end
end
