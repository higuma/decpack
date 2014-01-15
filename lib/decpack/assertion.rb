module Decpack
  # internal: assertion
  module Assertion
    extend self

    def assert_type(arg, type, name = nil)
      raise TypeError, "#{name || 'argument'} must be #{type.name}" unless
        arg.is_a? type
    end

    def assert_min(arg, min, msg)
      raise RangeError, msg if arg < min
    end

    def assert_max(arg, max, msg)
      raise RangeError, msg if arg > max
    end

    def assert_range(arg, min, max, msg)
      raise RangeError, msg if arg < min || arg > max
    end
  end
end
