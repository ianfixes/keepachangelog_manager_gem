require "keepachangelog_manager/exceptions"
require 'keepachangelog_manager/changelog'

module KeepAChangelogManager

  # Handles all things related to a repository and its filesystem
  class Repo

    # @return String the repository root
    attr_accessor :root

    # Create a new Repo representing git repository, given its path
    #
    # @param root String path to root directory of repository
    def initialize(root)
      @root = root
    end

    # Get the repository name.  It is assumed to be the name of the repo root directory
    #
    # keepachangelog.com CHANGELOG.md syntax assumes git _and_ github.com
    # so use that to our advantage: assume git repo exists.
    #
    # @return String
    def name
      File.basename(@root)
    end

    # The git remote origin url
    #
    # @return String
    def origin_url
      `git remote get-url origin`
    end

    # Extract the owner from a git URL
    #
    # @param url String the URL (git:// or https://)
    # @return String
    def _owner_from_git_url(url)
      parsed = Git::Remote::Parser.new.parse(url)
      raise BadGitRepoUrl, "Could not parse '#{url}' as a git url" if parsed.nil?

      parsed.owner
    end

    # Get the repo owner
    #
    # Assumes an "origin" url!
    #
    # @return String
    def owner
      Dir.chdir(@root) do
        url = origin_url
        raise NoGitRepo, "Could not find a git repo in '#{@root}'" if url.empty?

        _owner_from_git_url(url)
      end
    end

    # the path to the CHANGELOG.md file
    #
    # @return String
    def changelog_path
      File.join(@root, "CHANGELOG.md")
    end

    # A changelog object
    #
    # @return KeepAChangelog::Changelog
    def changelog
      Changelog.new(self)
    end
  end
end
