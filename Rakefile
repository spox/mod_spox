# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rspec/core/rake_task'
require './lib/mod_spox'

spec = Gem::Specification.new do |s|
  s.name = 'mod_spox'
  s.version = ModSpox::VERSION
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

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README.rdoc', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.rdoc" # page to start on
  rdoc.title = "mod_spox Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end

RSpec::Core::RakeTask.new do |t|
  t.rspec_path = 'spec'
end
