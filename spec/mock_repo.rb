require 'keepachangelog_manager'

class MockRepo < KeepAChangelogManager::Repo
  attr_accessor :fake_origin_url
  def origin_url; @fake_origin_url; end
end
