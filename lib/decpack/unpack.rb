require 'decpack/assertion'
require 'decpack/decoder'
require 'decpack/util'

module Decpack
  # unpack implementation
  module Unpack
    class Base
      include Assertion
      include Decpack::Util

      def initialize(input, type, eof)
        klass = if type == :binary
          eof ? Decpack::Decoder::BinaryE : Decpack::Decoder::Binary
        else
          eof ? Decpack::Decoder::TextE : Decpack::Decoder::Text
        end
        @dec = klass.new input
      end

      def text?; @dec.text? end
      def binary?; @dec.binary? end
      def support_eof?; @dec.support_eof? end
      def eof?; @dec.eof? end   # raises NoMethodError for non-EOF decoders

      def decoder; @dec end
      def raw(w);  @dec.decode w end

      def R(w, f)
        assert_type f, Integer, 'fraction'
        assert_min f, 0, 'fraction must be non-negative'
      end

      alias r R

      def D(w); B D2B(w) end
      def d(w); b d2b(w) end
      def F(w, f); R D2B(w), f end
      def f(w, f); r d2b(w), f end

      def array(format)
        format = Decpack.parse_format(format) if format.is_a? String
        raise TypeError, "format must be String or Array" unless
          format.is_a? Array
        format.map {|f| send f[0], *f[1, 2] }
      end
    end

    class R < Base      # no nil
      def use_nil?; false end

      alias :B :raw
      def b(w); raw(w) - (1 << w - 1) end
      def R(w, f); super; B(w) * 0.1 ** f end
      def r(w, f); super; b(w) * 0.1 ** f end
    end

    class N < Base      # use nil
      def use_nil?; true end

      def B(w); (n = raw w) == 0 ? nil : n - 1 end
      def b(w); (n = raw w) == 0 ? nil : n - (1 << w - 1) end
      def R(w, f); super; (n = B w) ? n * 0.1 ** f : nil end
      def r(w, f); super; (n = b w) ? n * 0.1 ** f : nil end
    end
  end
end
