# frozen_string_literal: true

module Git
  class GitBranch
    attr_reader :repository_name, :name, :last_modified_date, :author_name, :author_email

    def initialize(repository_name, name, last_modified_date, author_name, author_email)
      @repository_name = repository_name
      @name = name
      @last_modified_date = last_modified_date
      @author_email = author_email
      @author_name = author_name
    end

    def to_s
      name
    end

    def =~(other)
      name =~ other
    end

    def ==(other)
      repository_name == other.repository_name \
        && name == other.name && \
        last_modified_date == other.last_modified_date \
        && author_email == other.author_email \
        && author_name == other.author_name
    end

    def self.name_from_ref(ref)
      ref.gsub(/^refs\/heads\//, '')
    end
  end
end
