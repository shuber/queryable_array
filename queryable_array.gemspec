# -*- encoding: utf-8 -*-

require File.expand_path('../lib/queryable_array/version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name     = 'queryable_array'
  s.version  = QueryableArray::Version
  s.date     = Date.today
  s.platform = Gem::Platform::RUBY

  s.summary     = 'Provides a simplified DSL allowing arrays of objects to be searched by their attributes'
  s.description = 'QueryableArray is intended to store a group of objects which share the same attributes allowing them to be searched with a simplified DSL'

  s.author   = 'Sean Huber'
  s.email    = 'github@shuber.io'
  s.homepage = 'http://github.com/shuber/queryable_array'

  s.require_paths = ['lib']

  s.files      = Dir['{bin,lib}/**/*'] + %w(Gemfile MIT-LICENSE Rakefile README.rdoc)
  s.test_files = Dir['test/**/*']

  s.add_dependency 'respond_to_missing'
  s.add_development_dependency 'codeclimate-test-reporter'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'turn'
end
