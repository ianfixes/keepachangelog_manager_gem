#!/usr/bin/env ruby
require 'keepachangelog_manager'
require 'optparse'

$exit_code = 0

# Use some basic parsing to allow command-line overrides of config
class Parser
  def self.parse(options)
    parsed_config = {}

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename(__FILE__)} <ONLY ONE of the following options>"

      opts.on("--major=VERSION", "Upgrade major version to VERSION") do |p|
        parsed_config[:abs_major] = p
      end

      opts.on("--minor=VERSION", "Upgrade minor version to VERSION") do |p|
        parsed_config[:abs_minor] = p
      end

      opts.on("--patch=VERSION", "Upgrade patch version to VERSION") do |p|
        parsed_config[:abs_patch] = p
      end

      opts.on("--increment-major", "Increment major version") do |v|
        parsed_config[:inc_major] = v
      end

      opts.on("--increment-minor", "Increment minor version") do |v|
        parsed_config[:inc_minor] = v
      end

      opts.on("--increment-patch", "Increment patch version") do |v|
        parsed_config[:inc_patch] = v
      end

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit $exit_code
      end
    end

    opt_parser.parse!(options)
    parsed_config
  end
end

# Read in command line options and make them read-only
@cli_options = (Parser.parse ARGV).freeze
if @cli_options.empty?
  $exit_code = 1
  Parser.parse %w[--help]
end

repo = KeepAChangelogManager::Repo.new(`git rev-parse --show-toplevel`.strip)
new_version = repo.changelog.update(@cli_options)
puts new_version
