require 'decpack/pack'
require 'decpack/unpack'

module Decpack
  VERSION = '0.0.1'

  # constructors
  def self.pack(opt = {})
    klass = if opt[:limit]
      opt[:nil] ? Decpack::Pack::LN : Decpack::Pack::L
    else
      opt[:nil] ? Decpack::Pack::RN : Decpack::Pack::R
    end
    klass.new((opt[:type] || :'').to_sym, opt[:eof])
  end

  def self.unpack(input, opt = {})
    raise TypeError, "argument must be String" if !input.is_a? String
    type = (opt[:type] || :'').to_sym
    unless [:binary, :text].member? type
      type = input.encoding == Encoding::ASCII_8BIT ? :binary : :text
    end
    eof = opt[:eof]
    (opt[:nil] ? Decpack::Unpack::N : Decpack::Unpack::R).new input, type, eof
  end
end
