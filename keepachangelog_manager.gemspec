# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "keepachangelog_manager/version"

Gem::Specification.new do |spec|
  spec.name          = "keepachangelog_manager"
  spec.version       = KeepAChangelogManager::VERSION
  spec.licenses      = ['Apache-2.0']
  spec.authors       = ["Ian Katz"]
  spec.email         = ["ianfixes@gmail.com"]

  spec.summary       = "CHANGELOG.md (keepachangelog.com style) section updater for automated releasing"
  spec.description   = spec.description
  spec.homepage      = "http://github.com/ianfixes/keepachangelog_manager_gem"

  spec.bindir        = "bin"
  rejection_regex    = %r{^(test|spec|features)/}
  libfiles           = Dir['lib/**/*.*'].reject { |f| f.match(rejection_regex) }
  binfiles           = Dir[File.join(spec.bindir, '/**/*.*')].reject { |f| f.match(rejection_regex) }
  spec.files         = ['README.md', '.yardopts'] + libfiles + binfiles

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'git-remote-parser', '~> 1.0'
  spec.add_dependency "semver2", "~> 3.4"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency 'fakefs', '~>0.18.1'
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'rubocop', '=0.59.2'
  spec.add_development_dependency 'yard', '~>0.9.11'
end
