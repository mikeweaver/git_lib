#!/usr/bin/env rake

require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'coveralls/rake/task'
require 'bundler/audit/task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
Coveralls::RakeTask.new
Bundler::Audit::Task.new

task test: :spec
task rspec: :spec
task default: :spec
