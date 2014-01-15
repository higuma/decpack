require 'zlib'
require 'decpack'

NAME = 'tokyo_hourly_weather'
CSV = NAME + '.csv'
PACK = NAME + '.pack'
DP6 = NAME + '.dp6'
DP8 = NAME + '.dp8'
CSVGZ = CSV + '.gz'
DP8GZ = DP8 + '.gz'

# read CSV and compress with pack and Decpack 6/8
pack = ''.encode Encoding::ASCII_8BIT
PACK_FORMAT = 'lf2'
dp6 = Decpack.pack eof: true
dp8 = Decpack.pack type: :binary, eof: true
DP_FORMAT = Decpack.parse_format 'B31 r10.1 R11.1'
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
    printf "%7d  %-s\n", File.stat(path).size, path
    system "rm #{path}" if path != CSV
  end
end

__END__
補足説明

元データのtest_hourly_weather.csvは気象庁から入手した東京の1時間気象統計データ(1990-01-01 .. 2013-10-31)。一行のデータフォーマットは次の通り。

(epoch time[sec]),(気温[C]),(降水量[mm])

result
------
$ time _../lib ruby test_real_data_2.rb 
4021507  tokyo_hourly_weather.csv
 928861  tokyo_hourly_weather.csv.gz
 850316  tokyo_hourly_weather.csv.bz2
2506908  tokyo_hourly_weather.pack
 989541  tokyo_hourly_weather.pack.gz
 861129  tokyo_hourly_weather.pack.bz2
1810550  tokyo_hourly_weather.dp6
1061045  tokyo_hourly_weather.dp6.gz
1100604  tokyo_hourly_weather.dp6.bz2
1357913  tokyo_hourly_weather.dp8
1001055  tokyo_hourly_weather.dp8.gz
1027800  tokyo_hourly_weather.dp8.bz2
