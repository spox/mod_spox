spec = Gem::Specification.new do |s|
    s.name              = 'mod_spox'
    s.author            = %q(spox)
    s.email             = %q(spox@modspox.com)
    s.version           = '0.3.0'
    s.summary           = %q(Mail Migrator)
    s.platform          = Gem::Platform::RUBY
    s.has_rdoc          = true
    s.rdoc_options      = %w(--title mod_spox --main README.rdoc --line-numbers)
    s.extra_rdoc_files  = %w(README.rdoc)
    s.files             = Dir['**/*']
    s.executables       = %w(mod_spox)
    s.require_paths     = %w(lib)
    s.homepage          = %q(http://dev.modspox.com)
    s.rubyforge_project = 'modspox'
    s.add_dependency 'sequel'
    s.add_dependency 'ActionPool'
    s.add_dependency 'ActionTimer'
    s.add_dependency 'spockets'
    description         = []
    File.open("README.rdoc") do |file|
        file.each do |line|
            line.chomp!
            break if line.empty?
            description << "#{line.gsub(/\[\d\]/, '')}"
        end
    end
    s.description = description[1..-1].join(" ")
end