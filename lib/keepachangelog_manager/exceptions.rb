module KeepAChangelogManager
  # If the code in question is not actually a git repository
  class NoGitRepo < RuntimeError; end

  # If the remote doesn't seem sane
  class BadGitRepoUrl < RuntimeError; end

  # If an existing changelog doesn't seem sane
  class ChangelogParseFail < RuntimeError; end
end
