require 'decpack/assertion'

module Decpack
  # internal: encoding engines
  module Encoder
    class Base
      include Assertion

      def initialize
        @byte = @off = 0
      end

      def support_eof?; false end

      def assert_encode(w, n)
        assert_type w, Integer, 'width'
        assert_type n, Numeric, 'number'
        assert_min w, 1, 'width must be positive'
        assert_range n, 0, (1 << w) - 1, "number out of range: #{n}"
      end

      def encode(w, n)
        assert_encode w, n
        exec_encode w, n.to_i
      end
    end

    class Binary < Base
      def initialize
        super
        @data = ''.encode Encoding::ASCII_8BIT
      end

      def text?; false end
      def binary?; true end

      def exec_encode(w, n)
        if @off + w < 8
          @byte += n << 8 - w - @off
          @off += w
          return
        end
        byte = 0
        off = (@off + w) % 8
        if off > 0
          byte = (n << 8 - off) & 0xff
          n >>= off
          w -= off
        end
        buf = []
        while w >= 8
          buf << (n & 0xff)
          n >>= 8
          w -= 8
        end
        @data << (@byte + n).chr(Encoding::ASCII_8BIT) if @off > 0
        for b in buf.reverse
          @data << b.chr(Encoding::ASCII_8BIT) end
        @byte = byte
        @off = off
      end

      def output()
        return @data if @off == 0
        @data + @byte.chr(Encoding::ASCII_8BIT)
      end
    end

    class Text < Base
      ENCODE_MAP = Array('0'..'9') +
                   Array('A'..'Z') +
                   Array('a'..'z') +
                   ['-', '_']

      def initialize
        super
        @data = ''
      end

      def text?; true end
      def binary?; false end

      def exec_encode(w, n)
        if @off + w < 6
          @byte += n << 6 - w - @off
          @off += w
          return
        end
        byte = 0
        off = (@off + w) % 6
        if off > 0
        byte = (n << 6 - off) & 0x3f
          n >>= off
          w -= off
        end
        buf = []
        while w >= 6
          buf << (n & 0x3f)
          n >>= 6
          w -= 6
        end
        @data << ENCODE_MAP[@byte + n] if @off > 0
        for b in buf.reverse
          @data << ENCODE_MAP[b]
        end
        @byte = byte
        @off = off
      end

      def output()
        return @data if @off == 0
        @data + ENCODE_MAP[@byte]
      end
    end

    class BinaryE < Binary
      def initialize
        super
        @size = 0
      end

      def support_eof?; true end

      def assert_encode(w, n)
        super
        assert_max @size += w, 0xffffffff, 'total size is too large'
      end

      def output
        (@size >> 24).chr(Encoding::ASCII_8BIT) +
        ((@size >> 16) & 0xff).chr(Encoding::ASCII_8BIT) +
        ((@size >> 8) & 0xff).chr(Encoding::ASCII_8BIT) +
        (@size & 0xff).chr(Encoding::ASCII_8BIT) +
        super
      end
    end

    class TextE < Text
      def initialize
        super
        @size = 0
      end

      def support_eof?; true end

      def assert_encode(w, n)
        super
        assert_max @size += w, 0x3fffffff, 'total size is too large'
      end

      def output
        ENCODE_MAP[@size >> 24] +
        ENCODE_MAP[(@size >> 18) & 0x3f] +
        ENCODE_MAP[(@size >> 12) & 0x3f] +
        ENCODE_MAP[(@size >> 6) & 0x3f] +
        ENCODE_MAP[@size & 0x3f] +
        super
      end
    end
  end
end
