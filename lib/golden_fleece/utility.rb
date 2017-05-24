module GoldenFleece
  module Utility
    def json_path(parent_path, key_name)
      "#{parent_path}#{'/' unless parent_path =~ /\/$/}#{key_name}"
    end

    def error_suffix(attribute, path)
      "'#{path}' on column '#{attribute}'"
    end
  end
end
