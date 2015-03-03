$: << File.expand_path('../../lib', __FILE__)

if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'minitest/spec'
require 'turn/autorun'

Turn.config.format = :dot
