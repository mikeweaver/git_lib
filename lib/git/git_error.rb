module Git
  class GitError < StandardError
    attr_reader :command, :exit_code, :error_message

    def initialize(command, exit_code, error_message)
      @command = command
      @exit_code = exit_code
      @error_message = error_message
      super("Git command #{@command} failed with exit code #{@exit_code}. Message:\n#{@error_message}")
    end
  end
end
