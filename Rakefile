require 'rake/testtask'
begin
  require 'rdoc/task'
rescue LoadError
  require 'rake/rdoctask'
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the queryable_array gem.'
Rake::TestTask.new(:test) do |t|
  t.libs.push 'lib'
  t.pattern = 'test/**/*_test.rb'
end

desc 'Generate documentation for the queryable_array gem.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'queryable_array'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end