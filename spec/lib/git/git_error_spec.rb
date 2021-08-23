# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/git/git_error.rb'

RSpec.describe 'Git::GitError' do
  it 'can be raised' do
    expect { raise Git::GitError.new('command', 200, 'error_message') }.to \
      raise_exception(Git::GitError, "Git command command failed with exit code 200. Message:\nerror_message")
  end

  it 'can be printed' do
    begin
      raise Git::GitError.new('command', 200, 'error_message')
    rescue Git::GitError => e
      expect(e.message).to eq("Git command command failed with exit code 200. Message:\nerror_message")
    end
  end
end
