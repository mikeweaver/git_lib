# frozen_string_literal: true

require 'coveralls'
Coveralls.wear! if ENV['CI'] == 'true'
require 'rake'
require 'pp'
require 'fakefs/spec_helpers'
