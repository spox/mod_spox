spec = Gem::Specification.new do |s|
  s.name = 'mod_spox'
  s.version = '0.4.0'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE']
  s.summary = 'Ruby IRC bot'
  s.description = s.summary
  s.author = 'spox'
  s.email = 'spox@modspox.com'
  s.executables = ['mod_spox']
  s.files = %w(LICENSE README.rdoc Rakefile) + Dir.glob("{bin,lib,spec}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
  s.add_dependency 'actionpool', '~> 0.2.3'
  s.add_dependency 'actiontimer', '~> 0.2.1'
  s.add_dependency 'pipeliner' , '~> 1.1'
  s.add_dependency 'spockets', '~> 0.1.1'
  s.add_dependency 'splib', '~> 1.4.3'
  s.add_dependency 'messagefactory', '~> 0.0.5'
  s.add_dependency 'baseirc', '~> 1.0'
end
