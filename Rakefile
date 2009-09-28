###############################
# Basic rakefile for building #
# the gem and documentation.  #
###############################

require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'

NAME = 'mod_spox'
RUBYFORGENAME = 'modspox'
BOTVERSION = '0.3.3'

spec = Gem::Specification.new do |s|
    s.name = NAME
    s.version = BOTVERSION
    s.platform = Gem::Platform::RUBY
    s.summary = 'The mod_spox IRC robot'
    s.description = 'mod_spox is a Ruby IRC bot that is easily modifiable and extensible'
    s.requirements << 'sequel, espace-neverblock'
    s.files = FileList['README.rdoc', 'INSTALL', 'CHANGELOG', 'lib/**/*.rb', 'bin/*', 'data/**/*.rb'].to_a.delete_if {|item| item == ".svn"}
    s.executables << 'mod_spox'
    s.require_path = 'lib'
    s.bindir = 'bin'
    s.author = 'spox'
    s.email = 'spox@rubyforge.org'
    s.homepage = 'http://dev.modspox.com'
    s.rubyforge_project = 'modspox'
    s.has_rdoc = false
    s.add_dependency 'sequel'
end

Rake::GemPackageTask.new(spec) do |package|
    package.gem_spec = spec
    package.need_tar = true
    package.need_zip = true
end

Rake::RDocTask.new(:rdoc) do |rdoc|
    files = ['README.rdoc', 'CHANGELOG', 'LICENSE', 'INSTALL', 'lib/**/*.rb', 'data/**/*.rb']
    rdoc.rdoc_files.add(files)
    rdoc.main = 'README'
    rdoc.title = 'mod_spox Documentation'
    rdoc.rdoc_dir = 'doc'
    rdoc.options << '--line-numbers' << '--inline-source'
end

desc 'Build packages'
task :default => :package

desc 'Generate the API documentation'
task :api => :rdoc

desc 'Generate the API documentation'
task :doc => :rdoc

#desc 'Publish the release files to RubyForge'
task :release => [:package] do
    require 'rake/contrib/rubyforgepublisher'
    require 'rubyforge'
    packages = %w( gem tgz zip ).collect{ |ext| "pkg/#{NAME}-#{BOTVERSION}.#{ext}" }
    rubyforge = RubyForge.new
    rubyforge.configure
    rubyforge.login
    rubyforge.add_release(RUBYFORGENAME, RUBYFORGENAME, "REL #{BOTVERSION}", *packages)
end

#desc 'Publish the API documentation'
task :papi => [:rdoc] do
    require 'rake/contrib/sshpublisher'
    Rake::SshDirPublisher.new("spox@rubyforge.org", "/var/www/gforge-projects/modspox/docs", "doc").upload
end
