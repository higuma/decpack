require 'zlib'
require 'decpack'

NAME = 'tokyo_daily_weather'
CSV = NAME + '.csv'
PACK = NAME + '.pack'
DP6 = NAME + '.dp6'
DP8 = NAME + '.dp8'
CSVGZ = CSV + '.gz'
DP8GZ = DP8 + '.gz'

# read CSV and compress with pack and Decpack 6/8
pack = ''.encode Encoding::ASCII_8BIT
PACK_FORMAT = 'lf3'
dp6 = Decpack.pack eof: true
dp8 = Decpack.pack type: :binary, eof: true
DP_FORMAT = Decpack.parse_format 'b32 r10.1 r10.1 R12.1'
open CSV do |f|
  while line = f.gets
    data = line.split(',').map {|s| s.to_f }
    pack << data.pack(PACK_FORMAT)
    dp6.array DP_FORMAT, data
    dp8.array DP_FORMAT, data
  end
end

# save compressed data
open(PACK, 'w:ascii-8bit') {|f| f.write pack }
open(DP6, 'w:us-ascii') {|f| f.write dp6.output }
open(DP8, 'w:ascii-8bit') {|f| f.write dp8.output }

# compress files with GZIP and BZIP2
[CSV, PACK, DP6, DP8].each do |name|
  system "gzip -c -9 #{name} > #{name}.gz"      # -9 = best compression
  system "bzip2 -c -9 #{name} > #{name}.bz2"    # same as above
  [name, "#{name}.gz", "#{name}.bz2"].each do |path|
    printf "%6d  %-s\n", File.stat(path).size, path
    system "rm #{path}" if path != CSV
  end
end

__END__
補足説明

元データのtest_daily_weather.csvは気象庁から入手した東京の一日気象統計データ(1949-01-01 .. 2013-10-31)。一行のデータフォーマットは次の通り(1970年以前のデータもあるためepoch timeが負の値から始まっていることに注意)。

(epoch time[sec]),(最低気温[C]),(最高気温[C]),(降水量[mm])

result
------
$ ruby -I../lib test_real_data.rb 
568375  tokyo_daily_weather.csv
179617  tokyo_daily_weather.csv.gz
142359  tokyo_daily_weather.csv.bz2
378432  tokyo_daily_weather.pack
188392  tokyo_daily_weather.pack.gz
152139  tokyo_daily_weather.pack.bz2
252292  tokyo_daily_weather.dp6
173440  tokyo_daily_weather.dp6.gz
169978  tokyo_daily_weather.dp6.bz2
189220  tokyo_daily_weather.dp8
157542  tokyo_daily_weather.dp8.gz
152757  tokyo_daily_weather.dp8.bz2
