require 'decpack/assertion'

module Decpack
  # utility
  module Util
    LOG10_LOG2 = Math.log(10) / Math.log(2)

    def D2B(d)
      Assertion::assert_type d, Integer
      Assertion::assert_min d, 1, 'argument must be positive'
      (LOG10_LOG2 * d).ceil
    end

    def d2b(d); D2B(d) + 1 end

    module_function :D2B, :d2b

    RE_FORMAT_SPEC = /^(?:([BDbd])(\d+)|([FRfr])(\d+)\.(\d+))/

    def parse_format(spec)
      Assertion::assert_type spec, String, 'format'
      raise TypeError, 'format is an empty String' if spec.empty?
      format = []
      s = spec.strip
      while (match = s.match RE_FORMAT_SPEC)
        format << if match[1]
          w = match[2].to_i
          case t = match[1].to_sym
            when :B, :b then [t, w]
            when :D then [:B, D2B(w)]
            when :d then [:b, d2b(w)]
          end
        else
          w = match[4].to_i
          f = match[5].to_i
          case t = match[3].to_sym
            when :R, :r then [t, w, f]
            when :F then [:R, D2B(w), f]
            when :f then [:r, d2b(w), f]
          end
        end
        s = match.post_match.strip
      end
      raise TypeError, "invalid format: #{spec}" unless s.empty?
      format
    end
  end

  include Decpack::Util
  module_function :D2B, :d2b, :parse_format
end
