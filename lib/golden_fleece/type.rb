module GoldenFleece
  class Type
    attr_reader :name, :classes

    def initialize(name, *classes)
      @name = name.to_sym
      @classes = classes
    end

    def matches?(value)
      classes.any? { |klass| value.is_a? klass }
    end

    def to_s
      ":#{name}"
    end

    def inspect
      to_s
    end
  end
end
