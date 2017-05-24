require "golden_fleece/context/export"
require "golden_fleece/context/formats"
require "golden_fleece/context/getters"
require "golden_fleece/context/normalizers"
require "golden_fleece/context/schemas"
require 'golden_fleece/schema'

module GoldenFleece
  class Context
    include ::GoldenFleece::Context::Export
    include ::GoldenFleece::Context::Formats
    include ::GoldenFleece::Context::Getters
    include ::GoldenFleece::Context::Normalizers
    include ::GoldenFleece::Context::Schemas

    attr_accessor :rules
    attr_reader :model_class, :normalizers, :formats, :attributes, :schemas, :setup_callbacks

    def initialize(model_class)
      @model_class = model_class
      @normalizers = {}
      @formats = {}
      @attributes = []
      @schemas = Schema.new(self, '/', {})
      @setup_callbacks = []
    end

    def run_setup_callbacks
      @setup_callbacks.each do |cb|
        cb.call self
      end
    end
  end
end
