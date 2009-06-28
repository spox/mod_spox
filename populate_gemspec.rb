skip = %w(gemspec$ gem$ Rakefile populate_gemspec.rb)
files = `git ls-files`.split("\n").sort
files.each{|f| skip.each{|s| if(f =~ /#{s}/);files.delete(f);next;end;}}

spec = File.open('mod_spox.gemspec', 'r')
contents = spec.readlines
spec.close
contents.each do |line|
    if(line =~ /^\s+s\.files\s+=\s(.+)$/)
        line.gsub!($1, files.to_s)
    end
end
spec = File.open('mod_spox.gemspec', 'w')
spec.write(contents.join)
spec.close