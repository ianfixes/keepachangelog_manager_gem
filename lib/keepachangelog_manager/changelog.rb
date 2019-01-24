require 'semver'
require 'git/remote/parser'
require 'date'

UNRELEASED = "Unreleased".freeze
DEFAULT_VERSION = "0.0.0".freeze
SECTION_ORDER = [:added, :changed, :deprecated, :removed, :fixed, :security].freeze
SECTION_NAME = {
  added: "Added",
  changed: "Changed",
  deprecated: "Deprecated",
  removed: "Removed",
  fixed: "Fixed",
  security: "Security",
}.freeze

module KeepAChangelogManager

  # Handles all things related to a CHANGELOG.md
  class Changelog

    # Data Structure of a Changelog document:
    # * Header (array of lines -- just the text, the title is predefined)
    # * Release hash: key = semver (or :unreleased)
    #   * Date string (optional)
    #   * Section hash (order = )
    #     * array of lines
    class ChangeData
      # @return Array<String>
      attr_accessor :header

      # @return Hash
      attr_accessor :releases

      def initialize(header, releases)
        @header = header
        @releases = releases
      end

      # validate an attempted change to a version -- make sure no versions decrease
      #
      # @param version SemVer
      # @param dimension Symbol
      # @param newval Int
      def validate(version, dimension, newval)
        oldval = version.send(dimension)
        raise ArgumentError, "Tried to set #{dimension} to #{newval}, which isn't greater than #{oldval}" unless newval > oldval
      end

      # Default "unreleased" structure
      #
      # @return Hash
      def self.bare_unreleased_data
        {
          sections: Hash[SECTION_ORDER.map { |i| [i, []] }]
        }
      end

      # content of a fresh (empty) changelog
      #
      # @return String
      def self.bare
        header_lines = [
          "All notable changes to this project will be documented in this file.",
          "",
          "The format is based on [Keep a Changelog](http://keepachangelog.com/)",
          "and this project adheres to [Semantic Versioning](http://semver.org/).",
        ]
        ChangeData.new(header_lines, UNRELEASED => self.bare_unreleased_data)
      end

      # Update a changelog by transforming Unreleased into a release
      #
      # Only one argument at a time should be supplied, all others nil
      #
      # @param inc_patch boolean whether to increment the patch version
      # @param abs_patch int an absolute value for the patch version
      # @param inc_minor boolean whether to increment the minor version
      # @param abs_minor int an absolute value for the minor version
      # @param inc_major boolean whether to increment the major version
      # @param abs_major int an absolute value for the major version
      # @return String the new version
      def update(inc_patch: nil, abs_patch: nil,
                 inc_minor: nil, abs_minor: nil,
                 inc_major: nil, abs_major: nil)
        num_args_supplied = binding.local_variables.count { |p| !binding.local_variable_get(p).nil? }
        raise ArgumentError, "Only one update option should be specified" unless 1 == num_args_supplied

        version = @releases.keys.reject { |k| k == UNRELEASED }.map { |k| SemVer.parse(k) }.max
        version = SemVer.parse("0.0.0") if version.nil?

        if !inc_patch.nil?
          version.patch += 1
        elsif !abs_patch.nil?
          validate(version, :patch, abs_patch)
          version.patch = abs_patch
        elsif !inc_minor.nil?
          version.minor += 1
          version.patch = 0
        elsif !abs_minor.nil?
          validate(version, :minor, abs_minor)
          version.minor = abs_minor
          version.patch = 0
        elsif !inc_major.nil?
          version.major += 1
          version.minor = 0
          version.patch = 0
        elsif !abs_major.nil?
          validate(version, :major, abs_major)
          version.major = abs_major
          version.minor = 0
          version.patch = 0
        end

        new_version = version.format("%M.%m.%p")
        @releases[new_version] = @releases[UNRELEASED]
        @releases[new_version][:date] = Date.today.strftime("%Y-%m-%d")
        @releases[UNRELEASED] = self.class.bare_unreleased_data

        new_version
      end
    end

    # @return KeepAChangelog::Repo the repository
    attr_accessor :repo

    # @param path String path to CHANGELOG.md (or where it should be)
    def initialize(repo)
      @repo = repo
    end

    # Removes empty entries from the end of an array
    #
    # Works very much like string chomp
    #
    # @param lines Array<String>
    # @return Array<String>
    def array_chomp(lines)
      return [] if lines.empty?
      return [] if lines.all?(&:empty?)

      last_entry = lines.rindex { |l| !l.strip.empty? }
      lines[0..last_entry]
    end

    # whether the changelog exists in its supposed path
    #
    # @return boolean
    def exist?
      File.exist? @repo.changelog_path
    end

    # Create an empty CHANGELOG.md for this repo
    #
    # keepachangelog.com CHANGELOG.md syntax assumes git _and_ github.com
    # so use that to our advantage: assume git repo exists.
    #
    # @return String
    def create(force = false)
      return if File.exist(@repo.changelog_path) && !force

      File.open(@repo.changelog_path, 'w') { |file| file.write(bare_changelog) }
    end

    # Update a changelog in-place by transforming Unreleased into a release
    #
    # @see ChangeData.update
    # @return String the new version
    def update(**kwargs)
      content = File.open(@repo.changelog_path, "r").read
      data = parse(content)
      new_version = data.update(**kwargs)
      File.open(@repo.changelog_path, 'w') { |file| file.write(render(data)) }
      new_version
    end

    # content of a fresh (empty) changelog
    #
    # @return String
    def bare
      render(ChangeData.bare)
    end

    # Sort section versions into a reverse-chronological array, unreleased first
    #
    # @param sections Hash the input
    # @return Array<String> the sorted version strings
    def version_order(releases)
      # order sections in reverse chronological, unreleased on top
      releases.keys.sort do |a, b|
        next  0 if a == b
        next -1 if a == UNRELEASED
        next  1 if b == UNRELEASED

        SemVer.parse(b) <=> SemVer.parse(a)
      end
    end

    # Render the data structure to text
    #
    # @param data ChangeData
    # @return String
    def render(data)
      render_lines(data).join("\n") + "\n"
    end

    # Render the data structure to an array of strings
    #
    # Output Structure of a Changelog document:
    # * Header ("Change Log" and the text under it, up to the first '## ')
    # * Release versions, reverse chronological, starting with 'unreleased'
    #   * Version (or unreleased) as a link to the diff
    #   * Date (optional)
    #   * Sections
    #     * Added
    #     * Changed
    #     * Deprecated
    #     * Removed
    #     * Fixed
    #     * Security
    # * Diff URLs
    #
    # Assumes the "Unreleased" section is fleshed out, even if blank
    #
    # @param data ChangeData
    # @return Array<String>
    def render_lines(data)
      # header
      out_lines = ["# Change Log"] + data.header
      out_lines << ""
      out_lines << ""

      # releases
      versions = version_order(data.releases)
      versions.each do |v|
        release = data.releases[v]
        out_lines << "## [#{v}]" + (v == UNRELEASED || release[:date].nil? ? "" : " - #{release[:date]}")

        SECTION_ORDER.each do |s|
          next unless release[:sections].key? s
          next if release[:sections][s].empty? && v != UNRELEASED

          section = release[:sections][s]
          out_lines << "### #{SECTION_NAME[s]}"
          out_lines += section
          out_lines << ""
        end
        out_lines << ""
      end

      # links.  unreleased will come first and may be the only one
      versions.each_with_index do |v, i|
        next_index = i + 1
        this_version = v == UNRELEASED ? "HEAD" : "v#{v}"
        prev_version = next_index < versions.length ? versions[next_index] : DEFAULT_VERSION
        out_lines << "[#{v}]: https://github.com/#{@repo.owner}/#{@repo.name}/compare/v#{prev_version}...#{this_version}"
      end

      out_lines
    end

    # Parse an existing changelog (by path)
    #
    # @param changelog_text String path
    # @return ChangeData
    def parse_file(path)
      parse(File.open(path, "r").read)
    end

    # Parse an existing changelog (delivered as a string)
    #
    # @param changelog_text String input
    # @return ChangeData
    def parse(changelog_text)
      # allowable transitions
      next_states = {
        initial: [:header],
        header: [:header, :release],
        release: [:section],
        section: [:section, :section_body, :release, :links],
        section_body: [:section_body, :release, :links]
      }
      state = :initial

      # signals for transitions, plus capture groups for params
      transitions = {
        header: /^# Change/,
        release: /^## \[([^\]]+)\]( - (.*))?/,
        section: /^### ([A-Z][a-z]+)/,
        links: /^\[Unreleased\]: https:\/\/github\.com\//,
      }

      # parser state data
      header_lines = []
      releases = {}
      last_version = nil
      last_section = nil

      changelog_text.lines.each do |l|
        # find the regex that matches, no transition if no match
        want_state, regex = transitions.find(proc { [nil, nil] }) { |_s, re| re.match(l) }
        good_transition = want_state.nil? || next_states[state].include?(want_state)
        raise ChangelogParseFail, "Changing to #{want_state} from #{state}" unless good_transition

        want_param = regex.match(l) unless regex.nil?

        # do any pre-transition bookkeeping
        case want_state
        when :initial
          raise ChangelogParseFail, "Tried to transition back to initial state"
        when :header
          # nothing to do
        when :release
          version = want_param[1]
          date = want_param[3]
          releases[version] = { sections: {}, date: date }
          last_version = version
          last_section = nil
        when :section
          section_name = want_param[1]
          section = SECTION_NAME.key(section_name)
          raise ChangelogParseFail, "Unknown section name: '#{section_name}'" if section.nil?

          releases[last_version][:sections][section] = []
          last_section = section
        when :links
          break
        else
          # line is just a normal line.  decide where we are and start appending

          case state
          when :header
            header_lines << l.chomp
          when :section
            releases[last_version][:sections][last_section] << l.chomp
          end
        end
        state = want_state unless want_state.nil?
      end

      releases.each do |version, release|
        release[:sections].each do |section, lines|
          releases[version][:sections][section] = array_chomp(lines)
        end
      end

      ChangeData.new(array_chomp(header_lines), releases)
    end

  end # class

end # module
