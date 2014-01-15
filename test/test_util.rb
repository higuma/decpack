require 'test/unit'
require 'decpack'

# utility test
# ------------
class TestUtil < Test::Unit::TestCase
  def D2B_strict(d)
    (Math.log(10 ** d + 1) / Math.log(2)).ceil
  end

  def test_D2B_d2b_arg
    assert_raise(TypeError) { Decpack.D2B("abc") }
    assert_raise(TypeError) { Decpack.d2b("abc") }
    assert_nothing_raised { Decpack.D2B(5) }
    assert_nothing_raised { Decpack.d2b(5) }
  end

  def test_D2B_d2b
    for d in (1..100)
      assert_equal Decpack.D2B(d), D2B_strict(d)
      assert_equal Decpack.d2b(d), Decpack.D2B(d) + 1
    end
  end

  def test_parse_format_arg
    assert_raise(TypeError) { Decpack.parse_format 123 }
    assert_raise(TypeError) { Decpack.parse_format '' }
    assert_raise(TypeError) { Decpack.parse_format 'a12.4' }
    assert_nothing_raised { Decpack.parse_format 'B10' }
    assert_nothing_raised { Decpack.parse_format ' B10 ' }
    assert_raise(TypeError) { Decpack.parse_format 'B 10' }
  end

  def unparse_format(format)
    spec = ''
    for fmt in format
      spec << sprintf(fmt.size == 2 ? "%s%d" : "%s%d.%d", *fmt)
    end
    spec
  end

  def test_parse_format
    fmt_in  = ' B14 b7 R20.3 r22.4  D4  d3   F6.4  f8.3   '
    fmt_out = 'B14b7R20.3r22.4B14b11R20.4r28.3'
    spec = Decpack.parse_format fmt_in
    assert_equal unparse_format(spec), fmt_out
  end
end
