require 'decpack'

SEED = 9871427

FILENAME = 'random_data'
CSV = FILENAME + '.csv'
PACK = FILENAME + '.pack'
DP6 = FILENAME + '.dp6'
DP8 = FILENAME + '.dp8'

# maximum digit is given from single-precision float data bit width (23)

MAX_DIGITS = 6  # (23bit[6.92 decimal digits]).floor
REPEAT = 100000

def generate_random_data
  d = rand 1..MAX_DIGITS
  f = rand 0..d
  max = 10 ** d - 1
  if rand(0..1) == 0
    [d, rand(-max..max)]
  else
    [d, f, rand(-max..max) * 0.1 ** f]
  end
end

def test_create_file(name)
  srand SEED
  open name, "w:ascii-8bit" do |f|
    f.write yield
  end
  system "gzip -c -9 #{name} > #{name}.gz"    # -9 = best compression
  system "bzip2 -c -9 #{name} > #{name}.bz2"  # same as above
  # or => system "bzip2 -k -9 #{name}"

  [name, name + '.gz', name + '.bz2'].each do |path|
    printf "%6d  %-s\n", File.stat(path).size, path
  end
end

def generate_decpack(type)
  pack = Decpack.pack type: type
  REPEAT.times do
    d = generate_random_data
    d.unshift d.size == 2 ? :d : :f
    pack.send *d
  end
  pack.output
end

test_create_file(CSV) do
  data = []
  REPEAT.times do
    d = generate_random_data
    data << (d.size == 2 ? sprintf("%d", d[1]) : sprintf("%.#{d[1]}f", d[2]))
  end
  data.join ','
end

test_create_file(PACK) do
  pack = ''.encode Encoding::ASCII_8BIT
  REPEAT.times do
    d = generate_random_data
    pack << (d.size == 2 ? [d[1]].pack('l') : [d[2]].pack('f'))
  end
  pack
end

test_create_file(DP6) { generate_decpack :text }

test_create_file(DP8) { generate_decpack :binary }

system "rm #{FILENAME}.*"

__END__

result
------
$ ruby -I../lib test_random_data.rb 
642512  random_data.csv
308138  random_data.csv.gz
273362  random_data.csv.bz2
400000  random_data.pack
328320  random_data.pack.gz
323111  random_data.pack.bz2
273232  random_data.dp6
206587  random_data.dp6.gz
206446  random_data.dp6.bz2
204924  random_data.dp8
204993  random_data.dp8.gz
206232  random_data.dp8.bz2
