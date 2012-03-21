# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.name        = 'splib'
  s.author      = 'spox'
  s.email       = 'spox@modspox.com'
  s.version       = '1.4.3'
  s.summary       = 'Spox Library'
  s.platform      = Gem::Platform::RUBY
  s.files       = %w(LICENSE README.rdoc CHANGELOG Rakefile) + Dir.glob("{bin,lib,spec,test}/**/*")
  s.rdoc_options    = %w(--title splib --main README.rdoc --line-numbers)
  s.extra_rdoc_files  = %w(README.rdoc CHANGELOG)
  s.require_paths   = %w(lib)
  s.required_ruby_version = '>= 1.8.6'
  s.homepage      = %q(http://github.com/spox/splib)
  s.description     = "The spox library contains various useful tools to help you in your day to day life. Like a trusty pocket knife, only more computery."
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "splib Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.libs << Dir["lib"]
end