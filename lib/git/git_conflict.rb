module Git
  class GitConflict
    attr_reader :repository_name, :branch_a, :branch_b, :conflicting_files

    def initialize(repository_name, branch_a, branch_b, conflicting_files)
      unless conflicting_files.present?
        raise ArgumentError, 'Must specify conflicting file list'
      end

      @repository_name = repository_name
      @branch_a = branch_a
      @branch_b = branch_b
      @conflicting_files = conflicting_files
    end

    def ==(other)
      repository_name == other.repository_name \
        && branch_a == other.branch_a \
        && branch_b == other.branch_b \
        && conflicting_files == other.conflicting_files
    end

    def contains_branch(branch_name)
      branch_a == branch_name || branch_b == branch_name
    end
  end
end
