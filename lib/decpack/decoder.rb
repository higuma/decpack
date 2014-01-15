require 'decpack/encoder'

module Decpack
  # internal: decoding engines
  module Decoder
    class Base
      include Assertion

      def initialize(input)
        assert_type input, String, 'input'
        @data = input
        @bit_off = @byte_off = 0
      end

      def support_eof?; false end

      def assert_decode(w)
        assert_type w, Integer, 'width'
        assert_min w, 1, 'width must be positive'
      end

      def decode(w)
        assert_decode w
        exec_decode w
      end
    end

    class Binary < Base
      def initialize(input)
        super
        raise TypeError, 'input encoding must be ASCII-8bit' if
          input.encoding != Encoding::ASCII_8BIT
      end

      def text?; false end
      def binary?; true end

      def exec_decode(w)
        n = 0
        if @bit_off > 0
          n = @data[@byte_off].ord & (1 << 8 - @bit_off) - 1
          if @bit_off + w < 8
            @bit_off += w
            return n >> 8 - @bit_off
          end
          w -= 8 - @bit_off
          @byte_off += 1
        end
        while w >= 8
          n = (n << 8) + @data[@byte_off].ord
          w -= 8
          @byte_off += 1
        end
        n = (n << w) + (@data[@byte_off].ord >> 8 - w) if w > 0
        @bit_off = w
        n
      end
    end

    class Text < Base
      DECODE_MAP = Hash.new do |hash, key|
        raise KeyError, "invalid character: #{key}"
      end
      Decpack::Encoder::Text::ENCODE_MAP.each_with_index do |c, i|
        DECODE_MAP[c] = i
      end

      def initialize(input)
        super
        raise TypeError, 'input encoding must be ASCII compatible' unless
          input.encoding.ascii_compatible?
      end

      def text?; true end
      def binary?; false end

      def exec_decode(w)
        n = 0
        if @bit_off > 0
          n = DECODE_MAP[@data[@byte_off]] & (1 << 6 - @bit_off) - 1
          if @bit_off + w < 6
            @bit_off += w
            return n >> 6 - @bit_off
          end
          w -= 6 - @bit_off
          @byte_off += 1
        end
        while w >= 6
          n = (n << 6) + DECODE_MAP[@data[@byte_off]]
          w -= 6
          @byte_off += 1
        end
        n = (n << w) + (DECODE_MAP[@data[@byte_off]] >> 6 - w) if w > 0
        @bit_off = w
        n
      end
    end

    class BinaryE < Binary
      def initialize(input)
        super
        raise ArgumentError, 'input too short' if @data.size < 4
        @size = exec_decode 32
        raise ArgumentError, 'invalid format' if @size > (@data.size - 4) * 8
        @bits_read = 0
      end

      def support_eof?; true end

      def assert_decode(w)
        super
        raise EOFError, 'end of data' if (@bits_read += w) > @size
      end

      def eof?; @bits_read >= @size end
    end

    class TextE < Text
      def initialize(input)
        super
        raise ArgumentError, 'input too short' if @data.size < 4
        @size = exec_decode 30
        raise ArgumentError, 'invalid format' if @size > (@data.size - 4) * 6
        @bits_read = 0
      end

      def support_eof?; true end

      def assert_decode(w)
        super
        raise EOFError, 'end of data' if (@bits_read += w) > @size
      end

      def eof?; @bits_read >= @size end
    end
  end
end
