require 'test/unit'
require 'zlib'
require 'decpack'

srand 12345678

# pack/unpack test
# ----------------
class TestPackUnpack < Test::Unit::TestCase
  def pack_unpack_test(method)
    send method, Decpack.pack
    send method, Decpack.pack(nil: true)
    send method, Decpack.pack(limit: true)
    send method, Decpack.pack(nil: true, limit: true)
    send method, Decpack.pack(eof: true)
    send method, Decpack.pack(nil: true, eof: true)
    send method, Decpack.pack(limit: true, eof: true)
    send method, Decpack.pack(nil: true, limit: true, eof: true)
  end

  # constructor test
  def pack_ctor_test_by_opt(type, use_nil, limit, eof, klass)
    pack = Decpack.pack type: type, nil: use_nil, limit: limit, eof: eof
    assert_equal pack.class, klass
    assert pack.use_nil? == use_nil
    assert pack.limit? == limit
    assert pack.support_eof? == eof
    assert_equal pack.binary?, type == :binary
    assert_equal pack.text?, type == :text
  end

  def pack_ctor_test_by_type(type, eof)
    pack_ctor_test_by_opt type, false, false, eof, Decpack::Pack::R
    pack_ctor_test_by_opt type, true, false, eof, Decpack::Pack::RN
    pack_ctor_test_by_opt type, false, true, eof, Decpack::Pack::L
    pack_ctor_test_by_opt type, true, true, eof, Decpack::Pack::LN
  end

  def test_pack_ctor
    [:binary, :text].each do |type|
      [false, true].each {|eof| pack_ctor_test_by_type type, eof }
    end
  end

  def test_unpack_ctor
    t = ''.encode Encoding::US_ASCII
    b = ''.encode Encoding::ASCII_8BIT
    assert_equal Decpack.unpack(t).class, Decpack::Unpack::R
    assert_equal Decpack.unpack(t, nil: true).class, Decpack::Unpack::N

    assert_equal Decpack.unpack(b).decoder.class, Decpack::Decoder::Binary
    assert_equal Decpack.unpack(t).decoder.class, Decpack::Decoder::Text
    assert Decpack.unpack(t).decoder.is_a? Decpack::Decoder::Text
    assert_nothing_raised   { Decpack.unpack b, type: :binary }
    assert_raise(TypeError) { Decpack.unpack t, type: :binary }
    assert_nothing_raised   { Decpack.unpack t, type: :text }
    assert_nothing_raised   { Decpack.unpack b, type: :text }
      # => OK (ASCII_8BIT is ASCII-compatible)
  end

  # pack argument type check
  def pack_b_arg_test(pack, method)     # B,b,D,d,raw
    assert_raise(ArgumentError) { pack.send method, 1 }
    assert_nothing_raised       { pack.send method, 8, 1 }
    assert_nothing_raised       { pack.send method, 8, 1.5 }
    assert_raise(ArgumentError) { pack.send method, 8, 1, 1 }
    assert_raise(TypeError)     { pack.send method, "8", 1 }
    assert_raise(TypeError)     { pack.send method, 8, "1" }
    assert_raise(RangeError)    { pack.send method, -2, 1 }
  end

  def pack_r_arg_test(pack, method)     # R,r,F,f
    assert_raise(ArgumentError) { pack.send method, 8, 1 }
    assert_nothing_raised       { pack.send method, 8, 1, 1 }
    assert_raise(ArgumentError) { pack.send method, 8, 1, 1, 1 }
    assert_raise(TypeError)     { pack.send method, "8", 1, 1 }
    assert_raise(TypeError)     { pack.send method, 8, "1", 1 }
    assert_raise(RangeError)    { pack.send method, 0, 1, 1 }
    assert_raise(RangeError)    { pack.send method, 8, -1, 1 }
  end

  def pack_arg_test(pack)
    [:B, :b, :D, :d, :raw].each {|method| pack_b_arg_test pack, method }
    [:R, :r, :F, :f].each {|method| pack_r_arg_test pack, method }
  end

  def test_pack_arg
    pack_unpack_test :pack_arg_test
  end

  # unpack argument type check
  def unpack_b_arg_test(unpack, method) # B,b,D,d
    assert_raise(ArgumentError) { unpack.send method }
    assert_nothing_raised       { unpack.send method, 8 }
    assert_raise(ArgumentError) { unpack.send method, 8, 1 }
    assert_raise(TypeError)     { unpack.send method, "8" }
    assert_raise(RangeError)    { unpack.send method, -2 }
  end

  def unpack_r_arg_test(unpack, method) # R,r,F,f
    assert_raise(ArgumentError) { unpack.send method, 8 }
    assert_nothing_raised       { unpack.send method, 8, 1 }
    assert_raise(ArgumentError) { unpack.send method, 8, 1, 1 }
    assert_raise(TypeError)     { unpack.send method, "8", 1 }
    assert_raise(RangeError)    { unpack.send method, 0, 1 }
    assert_raise(RangeError)    { unpack.send method, 8, -1 }
  end

  def unpack_arg_test(pack)
    [:B, :b, :D, :d].each {|method| unpack_b_arg_test pack, method }
    [:R, :r, :F, :f].each {|method| unpack_r_arg_test pack, method }
  end

  def test_unpack_arg
    input = '0' * 100
    unpack_arg_test Decpack.unpack(input)
    unpack_arg_test Decpack.unpack(input, nil: true)
  end

  # range test
  def pack_range_int(pack, method, w, min, max, limit)
    assert_nothing_raised { pack.send method, w, min }
    assert_nothing_raised { pack.send method, w, max }
    if limit
      assert_nothing_raised { pack.send method, w, min - 1 }
      assert_nothing_raised { pack.send method, w, max + 1 }
    else
      assert_raise(RangeError) { pack.send method, w, min - 1 }
      assert_raise(RangeError) { pack.send method, w, max + 1 }
    end
    if pack.use_nil?
      assert_nothing_raised { pack.send method, w, nil }
    else
      assert_raise(TypeError) { pack.send method, w, nil }
    end
  end

  def pack_range_fixed(pack, method, w, f, min, max, limit)
    assert_nothing_raised    { pack.send method, w, f, min }
    assert_nothing_raised    { pack.send method, w, f, max }
    if limit
      assert_nothing_raised { pack.send method, w, f, min - 0.1 ** f }
      assert_nothing_raised { pack.send method, w, f, max + 0.1 ** f }
    else
      assert_raise(RangeError) { pack.send method, w, f, min - 0.1 ** f }
      assert_raise(RangeError) { pack.send method, w, f, max + 0.1 ** f }
    end
    if pack.use_nil?
      assert_nothing_raised { pack.send method, w, f, nil }
    else
      assert_raise(TypeError) { pack.send method, w, f, nil }
    end
  end

  def pack_range_raw(pack, w)
    assert_nothing_raised { pack.raw w, 0 }
    assert_nothing_raised { pack.raw w, (1 << w) - 1 }
    assert_raise(RangeError) { pack.raw w, -1 }
    assert_raise(RangeError) { pack.raw w, 1 << w }
  end

  def range_test(limit)
    pack = Decpack.pack limit: limit
    pack_range_int pack, :B, 12, 0, 4095, limit
    pack_range_int pack, :b, 12, -2048, 2047, limit
    pack_range_fixed pack, :R, 12, 2, 0, 40.95, limit
    pack_range_fixed pack, :r, 12, 2, -20.48, 20.47, limit
    pack_range_raw pack, 12

    pack = Decpack.pack nil: true, limit: limit
    pack_range_int pack, :B, 12, 0, 4094, limit
    pack_range_int pack, :b, 12, -2047, 2047, limit
    pack_range_fixed pack, :R, 12, 2, 0, 40.94, limit
    pack_range_fixed pack, :r, 12, 2, -20.47, 20.47, limit
    pack_range_raw pack, 12
  end

  def test_range
    range_test false
    range_test true
  end

  # random loopback test
  def assert_fixed_equal(f, n0, n1)
    if n0 && n1
      assert_equal (n0 * 10 ** f).round, (n1 * 10 ** f).round
    else
      assert_equal n0, n1       # i.e. n0.nil? and n1.nil?
    end
  end

  TYPES = [:B, :b, :D, :d, :R, :r, :F, :f]

  def generate_random_data(use_nil)
    t = TYPES[Random.rand TYPES.size]
    # IEEE 754 floating point number has a 52 bit significand.
    # Decimal rounding causes log5/log2 = 3.32... bit error (max).
    #   max. bit width = (52 - log5/log2 = 49.678...).floor = 49
    #   max. digits = ((52 - log5/log2) * log2/log10 = 14.95...).floor = 14
    w = rand 1 .. ([:B, :b, :R, :r].include?(t) ? 49 : 14)
    f = rand 0 .. 8
    case t
    when :B
      n = rand 0 .. (1 << w) - 2
    when :b
      max = (1 << w - 1) - 1
      n = rand -max .. max
    when :R
      n = rand(0 .. (1 << w) - 2) * 0.1 ** f
    when :r
      max = (1 << w - 1) - 1
      n = rand(-max .. max) * 0.1 ** f
    when :D
      n = rand 0 .. 10 ** w - 1
    when :d
      max = 10 ** w - 1
      n = rand -max .. max
    when :F
      n = rand(0 .. 10 ** w - 1) * 0.1 ** f
    when :f
      max = 10 ** w - 1
      n = rand(-max .. max) * 0.1 ** f
    end
    n = nil if use_nil && rand(100) == 0
    if [:R, :r, :F, :f].include? t
      [t, w, f, n]
    else
      [t, w, n]
    end
  end

  def loopback_generate(pack)
    data = []
    10000.times do
      d = generate_random_data pack.use_nil?
      pack.send *d
      data << d
    end
    data
  end

  def loopback_verify(unpack, data)
    data.each do |d|
      n0 = d.pop
      n1 = unpack.send *d
      if d.size == 3
        assert_fixed_equal d[2], n0, n1
      else
        assert_equal n0, n1
      end
    end
  end

  def loopback_test(pack)
    data = loopback_generate pack
    unpack = Decpack.unpack pack.output,
                            nil: pack.use_nil?, eof: pack.support_eof?
    loopback_verify unpack, data
  end

  def test_loopback
    pack_unpack_test :loopback_test
  end

  # array I/O test
  def array_loopback_generate(pack)
    data = []
    frac = []
    format = ''
    10000.times do
      d = generate_random_data pack.use_nil?
      data << d[d.size == 3 ? 2 : 3]
      frac << (d.size == 4 ? d[2] : nil)
      if d.size == 4
        format << sprintf("%s%d.%d", *d[0, 3])
      else
        format << sprintf("%s%d", *d[0, 2])
      end
    end
    pack.array format, data
    [data, frac, format]
  end

  def array_loopback(pack)
    data, frac, format = array_loopback_generate pack
    unpack = Decpack.unpack pack.output,
                            nil: pack.use_nil?, eof: pack.support_eof?
    data2 = unpack.array format
    assert_equal data.size, data2.size
    data.size.times do |i|
      if frac[i]
        assert_fixed_equal frac[i], data[i], data2[i]
      else
        assert_equal data[i], data2[i]
      end
    end
  end

  def test_array_loopback
    pack_unpack_test :array_loopback
  end

  # file I/O test
  TEMPFILE = '__TEMPFILE__'

  def file_loopback_test(pack)
    data = loopback_generate pack
    mode_opt = pack.binary? ? ':ascii-8bit' : ''
    open TEMPFILE, "w#{mode_opt}" do |f|
      f.write pack.output
    end
    unpack = open TEMPFILE, "r#{mode_opt}" do |f|
      Decpack.unpack f.read, nil: pack.use_nil?, eof: pack.support_eof?
    end
    loopback_verify unpack, data
    File.delete TEMPFILE
  end

  def test_file_loopback
    pack_unpack_test :file_loopback_test
  end

  # file I/O via gzip compression using zlib
  def gzip_file_loopback_test(pack)
    data = loopback_generate pack
    Zlib::GzipWriter.open TEMPFILE do |gz|
      gz.write pack.output
    end
    unpack = Zlib::GzipReader.open TEMPFILE do |gz|
      Decpack.unpack gz.read, nil: pack.use_nil?, eof: pack.support_eof?
    end
    loopback_verify unpack, data
    File.delete TEMPFILE
  end

  def test_gzip_file_loopback
    pack_unpack_test :gzip_file_loopback_test
  end
end
