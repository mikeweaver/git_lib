require 'spec_helper'
require_relative '../../../lib/git/git_conflict.rb'

describe 'Git::GitConflict' do
  it 'can be created' do
    conflict = Git::GitConflict.new('repository_name', 'branch_a', 'branch_b', ['file1', 'file2'])

    expect(conflict.repository_name).to eq('repository_name')
    expect(conflict.branch_a).to eq('branch_a')
    expect(conflict.branch_b).to eq('branch_b')
    expect(conflict.conflicting_files).to eq(['file1', 'file2'])
  end

  it 'cannot be created without conflicting files' do
    expect { Git::GitConflict.new('repository_name', 'branch_a', 'branch_b', nil) }.to \
      raise_exception(ArgumentError, 'Must specify conflicting file list')
    expect { Git::GitConflict.new('repository_name', 'branch_a', 'branch_b', []) }.to \
      raise_exception(ArgumentError, 'Must specify conflicting file list')
  end

  it 'implements equality operator' do
    conflict_a = Git::GitConflict.new('repository_name', 'branch_a', 'branch_b', ['file1', 'file2'])

    conflict_b = Git::GitConflict.new('repository_name', 'branch_a', 'branch_b', ['file1', 'file2'])
    expect(conflict_a).to eq(conflict_b)

    conflict_c = Git::GitConflict.new('different', 'branch_a', 'branch_b', ['file1', 'file2'])
    expect(conflict_a).not_to eq(conflict_c)

    conflict_d = Git::GitConflict.new('repository_name', 'different', 'branch_b', ['file1', 'file2'])
    expect(conflict_a).not_to eq(conflict_d)

    conflict_e = Git::GitConflict.new('repository_name', 'branch_a', 'different', ['file1', 'file2'])
    expect(conflict_a).not_to eq(conflict_e)

    conflict_f = Git::GitConflict.new('repository_name', 'branch_a', 'branch_b', ['different', 'file2'])
    expect(conflict_a).not_to eq(conflict_f)
  end

  it 'can determine if it contains the specified branch' do
    conflict = Git::GitConflict.new('repository_name', 'branch_a', 'branch_b', ['file1', 'file2'])

    expect(conflict.contains_branch('branch_a')).to be_truthy
    expect(conflict.contains_branch('branch_b')).to be_truthy

    expect(conflict.contains_branch('branch_c')).to be_falsey
  end
end
