require 'digest/sha1'
require 'securerandom'
require_relative './git_branch.rb'
require_relative './git_conflict.rb'
require_relative './git_commit.rb'

module Git
  def create_test_git_branch(repository_name: 'repository_name',
                             name: 'path/branch',
                             last_modified_date: Time.current,
                             author_name: 'Author Name',
                             author_email: 'author@email.com')
    Git::GitBranch.new(repository_name, name, last_modified_date, author_name, author_email)
  end

  def create_test_git_conflict(repository_name: 'repository_name',
                               branch_a_name: 'branch_a',
                               branch_b_name: 'branch_b',
                               file_list: ['file1', 'file2'])
    Git::GitConflict.new(repository_name, branch_a_name, branch_b_name, file_list)
  end

  def create_test_git_commit(sha: '1234567890123456789012345678901234567890',
                             message: 'Commit message',
                             author_name: 'Author Name',
                             author_email: 'author@email.com',
                             commit_date: Time.current)
    Git::GitCommit.new(sha, message, commit_date, author_name, author_email)
  end

  def create_test_sha
    Digest::SHA1.hexdigest(SecureRandom.hex)
  end
end
