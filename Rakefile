require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the has_many_booleans plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the has_many_booleans plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'has_many_booleans Rails plugin'
  rdoc.options << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# gem
PKG_FILES = FileList[ '[a-zA-Z]*', 'lib/**/*', 'rails/**/*', 'test/**/*' ]
spec = Gem::Specification.new do |s|
  s.name = "has_many_booleans"
  s.version = "0.9.1"
  s.author = "Jan Lelis"
  s.email = "mail@janlelis.de"
  s.homepage = "http://rbjl.net"
  s.platform = Gem::Platform::RUBY
  s.summary = "This Rails plugin/gem allows you to generate virtual boolean attributes, which get saved in the database as a single bitset integer"
  s.files = PKG_FILES.to_a
  s.require_path = "lib"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
end

desc 'Turn this plugin into a gem.'
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

