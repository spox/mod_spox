module Splib
  # secs:: number of seconds
  # Converts seconds into a human readable string (This is an estimate
  # and does not account for leaps)
  def self.format_seconds(secs)
    arg = [{:year => 31536000},
        {:month => 2678400},
        {:week => 604800},
        {:day => 86400},
        {:hour => 3600},
        {:minute => 60},
        {:second => 1}]
    res = ''
    arg.each do |val|
      val.each_pair do |k,v|
        z = (secs / v).to_i
        next unless z > 0
        res += " #{z} #{k}#{z == 1 ? '':'s'}"
        secs = secs % v
      end
    end
    res = '0 seconds' if res.empty?
    return res.strip
  end

  # bytes:: number of bytes
  # Converts bytes into easy human readable form
  # O(1) version by Ryan "pizza_milkshake" Flynn
  Suff = [
  "",     # 1024^0
  "Kilo",   # 1024^1
  "Mega",   # 1024^2
  "Giga",   # 1024^3
  "Tera",   # 1024^4
  "Peta",   # 1024^5
  "Exa",  # 1024^6
  "Zetta",  # 1024^7
  "Yotta"   # 1024^8
  ]
  def self.format_size(bytes)
    return "0 bytes" if bytes == 0
    mag = (Math.log(bytes) / Math.log(1024)).floor
    mag = [ Suff.length - 1, mag ].min
    val = bytes.to_f / (1024 ** mag)
    ("%.2f %sbyte%s" % [ val, Suff[mag], val == 1 ? "" : "s" ]).strip
  end
end