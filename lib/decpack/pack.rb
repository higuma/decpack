require 'decpack/encoder'
require 'decpack/util'

module Decpack
  # pack implementation
  module Pack
    class Base
      include Assertion
      include Decpack::Util

      def initialize(type, eof)
        klass = if type == :binary
          eof ? Decpack::Encoder::BinaryE : Decpack::Encoder::Binary
        else
          eof ? Decpack::Encoder::TextE : Decpack::Encoder::Text
        end
        @enc = klass.new
      end

      def text?; @enc.text? end
      def binary?; @enc.binary? end
      def support_eof?; @enc.support_eof? end
      def use_nil?; false end
      def limit?; false end

      def encoder; @enc end
      def output; @enc.output end

      def raw(w, n); @enc.encode w, n end
      alias bits raw
      def Nil(w); @enc.encode w, 0 end

      def assert_args(w, n)
        assert_type w, Integer, 'width'
        assert_type n, Numeric, 'number'
        assert_min w, 1, 'width must be positive'
      end

      alias B assert_args
      alias b assert_args

      def R(w, f, n)
        assert_args w, n
        assert_type f, Integer, 'fraction'
        assert_min f, 0, 'fraction must be non-negative'
      end

      alias r R

      def D(d, n); B D2B(d), n end
      def d(d, n); b d2b(d), n end
      def F(d, f, n); R D2B(d), f, n end
      def f(d, f, n); r d2b(d), f, n end

      def array(format, data)
        format = Decpack.parse_format(format) if format.is_a? String
        raise TypeError, "format must be String or Array" unless
          format.is_a? Array
        format.each_with_index {|f, i| send *f, data[i] }
      end
    end

    class R < Base      # raise, no nil
      def B(w, n); super; bits w, n end
      def b(w, n); super; bits w, n + (1 << w - 1) end
      def R(w, f, n); super; B(w, (n * 10 ** f).round) end
      def r(w, f, n); super; b(w, (n * 10 ** f).round) end
    end

    class RN < Base     # raise, use nil
      def use_nil?; true end

      def B(w, n)
        return Nil(w) unless n
        super
        bits w, n >= 0 ? n + 1 : -1
      end

      def b(w, n);
        return Nil(w) unless n
        super
        n += 1 << w - 1
        bits w, n > 0 ? n : -1
      end

      def R(w, f, n)
        return Nil(w) unless n
        super;
        B w, (n * 10 ** f).round
      end

      def r(w, f, n)
        return Nil(w) unless n
        super;
        b w, (n * 10 ** f).round
      end
    end

    class L < R         # limit, no nil
      def limit?; true end

      def bits(w, n)
        if n < 0
          n = 0
        else
          max = (1 << w) - 1
          n = max if n > max
        end
        @enc.encode w, n
      end
    end

    class LN < RN       # limit, use nil
      def use_nil?; true end
      def limit?; true end

      def bits(w, n)
        if n != 0       # if 0 (i.e. nil), just fall through
          if n < 0
            n = 1       # => minimum value
          else
            max = (1 << w) - 1
            n = max if n > max
          end
        end
        @enc.encode w, n
      end
    end
  end
end
