module GoldenFleece
  class Format
    attr_reader :name

    def initialize(name, fn)
      @name = name
      @fn = fn
    end

    def validate(record, value)
      fn.call record, value
    end

    private

    attr_reader :fn
  end
end
