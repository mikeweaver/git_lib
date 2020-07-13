# frozen_string_literal: true

require 'coveralls'
Coveralls.wear! if ENV['CI'] == 'true'
require 'rake'
require 'pp'
require 'fakefs/spec_helpers'
require 'rspec_junit_formatter'
require 'climate_control'

RSpec.configure do |config|
  config.add_formatter RspecJunitFormatter, ENV['JUNIT_OUTPUT'] || 'spec/reports/rspec.xml'

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = "spec/reports/.rspec_status"

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end

