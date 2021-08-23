# frozen_string_literal: true

module Git
  class GitCommit
    attr_reader :repository_name, :sha, :message, :commit_date, :author_name, :author_email

    def initialize(sha, message, commit_date, author_name, author_email, repository_name:)
      @sha = sha
      @message = message
      @commit_date = commit_date
      @author_email = author_email
      @author_name = author_name
      @repository_name = repository_name
    end

    def to_s
      sha
    end

    def ==(other)
      sha == other.sha
    end
  end
end
