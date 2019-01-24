require 'keepachangelog_manager'
require_relative 'mock_repo'

RSpec.describe KeepAChangelogManager::Repo do
  describe "Repo file structure" do

    context "when in an arbitrary directory" do
      it "knows where things are" do
        fake_base = File.join("/", "foo", "bar")
        fake_name = "myrepo"
        fake_repo = File.join(fake_base, fake_name)
        fake_cl   = File.join(fake_repo, "CHANGELOG.md")

        repo = KeepAChangelogManager::Repo.new(fake_repo)
        expect(repo.root).to eq(fake_repo)
        expect(repo.name).to eq(fake_name)
        expect(repo.changelog_path).to eq(fake_cl)
      end

      it "creates changelog objects" do
        repo = KeepAChangelogManager::Repo.new("/")
        expect(repo.changelog.class).to eq(KeepAChangelogManager::Changelog)
      end

      it "parses git URLs" do
        repo = KeepAChangelogManager::Repo.new("/")
        expect(repo._owner_from_git_url("git@github.com:torvalds/linux.git")).to eq("torvalds")
        expect(repo._owner_from_git_url("https://github.com/torvalds/linux.git")).to eq("torvalds")
      end

      it "doesn't parse bad URLs" do
        repo = KeepAChangelogManager::Repo.new("/")
        bads = ["", "aw3ta46"]

        bads.each do |url|
          expect {repo._owner_from_git_url(url)}.to raise_error(KeepAChangelogManager::BadGitRepoUrl, "Could not parse '#{url}' as a git url")
        end
      end

      it "Knows the repo owner" do
        repo = MockRepo.new("/")
        repo.fake_origin_url = "https://github.com/foo/bar.git"
        expect(repo.owner).to eq("foo")
      end

    end

  end
end
