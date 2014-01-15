require 'test/unit'
require 'decpack'

# srand 12345678

# encoding/decoding engine test
# -----------------------------
class TestEngine < Test::Unit::TestCase
  EncB = Decpack::Encoder::Binary
  EncT = Decpack::Encoder::Text
  EncBE = Decpack::Encoder::BinaryE
  EncTE = Decpack::Encoder::TextE
  DecB = Decpack::Decoder::Binary
  DecT = Decpack::Decoder::Text
  DecBE = Decpack::Decoder::BinaryE
  DecTE = Decpack::Decoder::TextE

  # encoder constructor argument test
  def check_encoder_ctor_arg(klass)
    assert_nothing_raised { klass.new }
    assert_raise(ArgumentError) { klass.new 1 }
  end

  def test_encoder_ctor_arg
    check_encoder_ctor_arg EncB
    check_encoder_ctor_arg EncT
    check_encoder_ctor_arg EncBE
    check_encoder_ctor_arg EncTE
  end

  # decoder constructor argument test
  def test_decoder_ctor_arg
    enc_b = EncB.new
    enc_be = EncBE.new
    enc_t = EncT.new
    enc_te = EncTE.new

    # DecB
    assert_raise(ArgumentError) { DecB.new }
    assert_raise(TypeError) { DecB.new 123 }
    assert_nothing_raised { DecB.new enc_b.output }
    assert_raise(TypeError) { DecB.new enc_t.output }
    assert_raise(ArgumentError) { DecB.new enc_b.output, 1 }

    # DecT
    assert_raise(ArgumentError) { DecT.new }
    assert_raise(TypeError) { DecT.new 123 }
    assert_nothing_raised { DecT.new enc_t.output }
    assert_nothing_raised { DecT.new enc_b.output }
    assert_raise(TypeError) { DecT.new ''.encode Encoding::UTF_16LE }
    assert_raise(ArgumentError) { DecT.new enc_t.output, 1 }

    # DecBE
    dummy_ok = EncB.new
    dummy_ok.encode 32, 16      # simulate size
    dummy_ok.encode 16, 12345

    dummy_ng = EncB.new
    dummy_ng.encode 32, 64      # (greater than real size)
    dummy_ng.encode 16, 12345

    assert_raise(ArgumentError) { DecBE.new }
    assert_raise(TypeError) { DecBE.new 123 }
    assert_raise(ArgumentError) { DecBE.new enc_b.output }    # size too short
    assert_nothing_raised { DecBE.new dummy_ok.output }
    assert_raise(ArgumentError) { DecBE.new dummy_ng.output } # invalid format
    assert_raise(ArgumentError) { DecBE.new dummy_ok.output, 1 }

    # DecTE
    dummy_ok = EncT.new
    dummy_ok.encode 30, 16      # simulate size
    dummy_ok.encode 16, 12345

    dummy_ng = EncT.new
    dummy_ng.encode 30, 64      # (greater than real size)
    dummy_ng.encode 16, 12345

    assert_raise(ArgumentError) { DecTE.new }
    assert_raise(TypeError) { DecTE.new 123 }
    assert_raise(ArgumentError) { DecTE.new enc_t.output }    # size too short
    assert_nothing_raised { DecTE.new dummy_ok.output }
    assert_raise(ArgumentError) { DecTE.new dummy_ng.output } # invalid format
    assert_raise(ArgumentError) { DecTE.new dummy_ok.output, 1 }
  end

  # encoder method argument test
  def check_encoder_method_arg(klass)
    enc = klass.new
    assert_raise(ArgumentError) { enc.encode(1) }
    assert_nothing_raised { enc.encode(4, 1) }
    assert_raise(ArgumentError) { enc.encode(4, 1, 1) }
    assert_raise(TypeError) { enc.encode("4", 1) }
    assert_raise(TypeError) { enc.encode(4, "1") }
    assert_nothing_raised { enc.encode(4, 1.0) }
    assert_raise(TypeError) { enc.encode(4.0, 1) }
    assert_raise(RangeError) { enc.encode(0, 1) }
    assert_raise(RangeError) { enc.encode(4, -1) }
    assert_raise(RangeError) { enc.encode(4, 16) }
    assert_nothing_raised { enc.encode(4, 15) }
  end

  def test_encoder_method_arg
    check_encoder_method_arg EncB
    check_encoder_method_arg EncBE
    check_encoder_method_arg EncT
    check_encoder_method_arg EncTE
  end

  # decoder method argument test
  def check_decoder_method_arg(klass_dec, klass_enc)
    enc = klass_enc.new
    8.times {|i| enc.encode 4, i }
    dec = klass_dec.new enc.output
    assert_raise(ArgumentError) { dec.decode }
    assert_nothing_raised { dec.decode 4 }
    assert_raise(ArgumentError) { dec.decode 4, 1 }
    assert_raise(TypeError) { dec.decode 4.0 }
    assert_raise(TypeError) { dec.decode "4" }
    assert_raise(RangeError) { dec.decode 0 }
    assert_raise(RangeError) { dec.decode -4 }
  end

  def test_decoder_method_args
    check_decoder_method_arg DecB, EncB
    check_decoder_method_arg DecT, EncT
    check_decoder_method_arg DecBE, EncBE
    check_decoder_method_arg DecTE, EncTE
  end

  # read-out-of bounds test for non EOF supported encoder/decoder
  def check_read_after_end_of_data(klass_enc, klass_dec, klass_raise)
    enc = klass_enc.new
    256.times {|i| enc.encode 8, i }
    dec = klass_dec.new enc.output
    256.times do |i|
      assert_equal i, dec.decode(8)
    end
    assert_raise (klass_raise) { dec.decode(8) }
  end

  def test_end_of_data
    check_read_after_end_of_data EncB, DecB, NoMethodError
    check_read_after_end_of_data EncT, DecT, KeyError
  end

  # EOF detection test for EOF supported encoder/decoder
  def check_eof(klass_enc, klass_dec, support_eof)
    enc = klass_enc.new
    256.times {|i| enc.encode 8, i }
    dec = klass_dec.new enc.output
    256.times do |i|
      assert !dec.eof? if support_eof
      assert_equal i, dec.decode(8)
    end
    if support_eof
      assert dec.eof?
      assert_raise(EOFError) { dec.decode 8 }
      assert dec.eof?
    else
      assert_raise(NoMethodError) { dec.eof? }
    end
  end

  def test_eof_detection
    check_eof EncB, DecB, false
    check_eof EncT, DecT, false
    check_eof EncBE, DecBE, true
    check_eof EncTE, DecTE, true
  end

  # sequencial loopback test
  #
  # bit pattern
  # -----------
  #
  # 001011011101111011111011111101111111...
  # +--+++----+++++------+++++++--------...
  # 12 3  4   5    6     7      8
  def encode_sequencial(enc, wmax, repeat)
    repeat.times do
      for w in (1..wmax)
        enc.encode w, (1 << w - 1) - 1
      end
    end
  end

  def decode_sequencial_check(dec, wmax, repeat)
    repeat.times do
      for w in (1..wmax)
        assert_equal dec.decode(w), (1 << w - 1) - 1
      end
    end
  end

  def sequencial_loopback(enc_class, dec_class)
    enc = enc_class.new
    encode_sequencial enc, 100, 10
    dec = dec_class.new enc.output
    decode_sequencial_check dec, 100, 10
  end

  # random bit pattern loopback
  def encode_random(enc, wmax, repeat)
    data = []
    repeat.times do
      w = rand 1..wmax
      n = rand 0..(1 << w) - 2
      enc.encode w, n
      data << [w, n]
    end
    data
  end

  def decode_random_check(dec, data)
    for d in data
      w, n = d
      assert_equal dec.decode(w), n
    end
  end

  def random_loopback(enc_class, dec_class)
    enc = enc_class.new
    data = encode_random enc, 32, 10000
    dec = dec_class.new enc.output
    decode_random_check dec, data
  end

  def test_loopback
    sequencial_loopback EncB, DecB
    sequencial_loopback EncT, DecT
    sequencial_loopback EncBE, DecBE
    sequencial_loopback EncTE, DecTE
    random_loopback EncB, DecB
    random_loopback EncT, DecT
    random_loopback EncBE, DecBE
    random_loopback EncTE, DecTE
  end

  # character code check for text decoder
  def test_text_charcode
    dec = DecT.new "123ABCabc"    # 6 * 9 = 54 bit
    assert_nothing_raised { dec.decode(54) }
    dec = DecT.new "123ABCab@"
    assert_raise(KeyError) { dec.decode(54) }
  end
end
