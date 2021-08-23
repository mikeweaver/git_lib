# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/git/git_commit.rb'

RSpec.describe Git::GitCommit do
  let(:sha) { 'aabb2345' }
  let(:message) { 'TECH-1234: update comments' }
  let(:commit_date) { '2021-08-23 10:03:00 -0700' }
  let(:author_name) { 'John Doe' }
  let(:author_email) { 'john@doe.com' }
  let(:repository_name) { 'repository_name' }

  it 'can be created' do
    commit = Git::GitCommit.new(sha, message, commit_date, author_name, author_email, repository_name: repository_name)

    expect(commit.sha).to eq(sha)
    expect(commit.message).to eq(message)
    expect(commit.commit_date).to eq(commit_date)
    expect(commit.author_name).to eq(author_name)
    expect(commit.author_email).to eq(author_email)
    expect(commit.repository_name).to eq(repository_name)
  end
end
