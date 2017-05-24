module GoldenFleece
  module Utility
    def config_path(parent_path, config_name)
      "#{parent_path}#{'/' unless parent_path =~ /\/$/}#{config_name}"
    end

    def error_suffix(attribute, path)
      "'#{path}' on column '#{attribute}'"
    end
  end
end
