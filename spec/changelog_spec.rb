require 'keepachangelog_manager'
require 'fileutils'
require 'fakefs/safe'
require 'date'

# get the text of one of the files in samples/
def sample_text(name)
  File.read(File.expand_path("samples/#{name}", __dir__))
end

def vegetable_releases
  {
    "0.1.2" => {
      date: "2018-12-23",
      sections: {
        added: ["* apples", "* bananas"],
        removed: ["* potatoes", "* onions"],
      }
    },
    "Unreleased" => {
      date: "ignored!",
      sections: {
        added: ["* oranges", "* pineapples"],
        removed: ["* pickles", "* tomatoes"],
      }
    },
    "0.2.1" => {
      sections: {
        added: ["* strawberries", "* blueberries"],
        removed: ["* rhubarb", "* butterfly"],
      }
    },
  }
end

RSpec.describe KeepAChangelogManager::Changelog do
  describe "Changelog operations" do

    context "standalone functions" do
      # we'll use the same repo and changelog objects for all of this
      before(:each) do
        fake_base = File.join("/", "baz", "bar")
        fake_name = "myrepo"
        @repo_path = File.join(fake_base, fake_name)
        @repo = MockRepo.new(@repo_path)
        @repo.fake_origin_url = "https://github.com/foo/myrepo.git"
        @changelog = @repo.changelog
      end

      it "generates base text" do
        FakeFS do
          FakeFS::FileSystem.clone(File.expand_path('../', __dir__))
          FileUtils.mkdir_p(@repo_path)

          expect(@changelog.bare).to eq(sample_text("fresh_foobar.md"))
        end
      end

      it "sorts versions" do
        versions = ["0.1.2", "0.11.2", "0.11.1", "0.2.1", "Unreleased"]
        releases = Hash[versions.map { |i| [i, nil] } ]
        expect(@changelog.version_order(releases)).to eq(["Unreleased", "0.11.2", "0.11.1", "0.2.1", "0.1.2"])
      end

      it "renders text" do
        # * Header (array of lines -- just the text, the title is predefined)
        # * Release hash: key = semver (or :unreleased)
        #   * Date string (optional)
        #   * Section hash (order = )
        #     * array of lines
        header = ["hello", "a", "b"]
        data = KeepAChangelogManager::Changelog::ChangeData.new(header, vegetable_releases)

        FakeFS do
          FakeFS::FileSystem.clone(File.expand_path('../', __dir__))
          FileUtils.mkdir_p(@repo_path)
          expect(@changelog.render(data)).to eq(sample_text("vegetables.md"))
          expect(@changelog.render_lines(data)).to eq(sample_text("vegetables.md").lines.map(&:chomp))
        end
      end

      it "parses text" do
        # * Header (array of lines -- just the text, the title is predefined)
        # * Release hash: key = semver (or :unreleased)
        #   * Date string (optional)
        #   * Section hash (order = )
        #     * array of lines
        expected_releases = vegetable_releases
        expected_releases["Unreleased"][:date] = nil

        data = @changelog.parse(sample_text("vegetables.md"))
        expect(data.header).to eq(["hello", "a", "b"])
        expect(data.releases.keys).to match_array expected_releases.keys
        expected_releases.each do |version, expected_release|
          release = data.releases[version]
          expect(release[:date]).to eq(expected_release[:date])
          expect(release[:sections].keys).to eq(expected_release[:sections].keys)
          expected_release[:sections].each do |section, lines|
            expect(release[:sections][section]).to eq(lines)
          end
        end
      end

      it "recreates losslessly" do
        data = @changelog.parse(sample_text("vegetables.md"))
        FakeFS do
          FakeFS::FileSystem.clone(File.expand_path('../', __dir__))
          FileUtils.mkdir_p(@repo_path)
          expect(@changelog.render(data)).to eq(sample_text("vegetables.md"))
          expect(@changelog.render_lines(data)).to eq(sample_text("vegetables.md").lines.map(&:chomp))
        end
      end

    end # context

    context "file updating" do
      before(:each) do
        allow(Date).to receive(:today).and_return Date.new(2019, 1, 23)

        FakeFS do
          fake_base = File.join("/", "baz", "bar")
          fake_name = "myrepo"
          @repo_path = File.join(fake_base, fake_name)
          @repo = MockRepo.new(@repo_path)
          @repo.fake_origin_url = "https://github.com/foo/myrepo.git"
          @changelog = @repo.changelog

          FakeFS::FileSystem.clone(File.expand_path('../', __dir__))
          FileUtils.mkdir_p(@repo_path)

          File.open(@repo.changelog_path, 'w') { |file| file.write(sample_text("vegetables.md")) }
        end
      end

      it "increments patch version" do
        FakeFS do
          new_version = @changelog.update(inc_patch: true)
          expect(new_version).to eq("0.2.2")
          full_text = File.open(@repo.changelog_path, "r").read
          expect(full_text).to eq(sample_text("vegetables-inc-patch.md"))
        end
      end

      it "absolute patch version" do
        FakeFS do
          new_version = @changelog.update(abs_patch: 3)
          expect(new_version).to eq("0.2.3")
          full_text = File.open(@repo.changelog_path, "r").read
          expect(full_text).to eq(sample_text("vegetables-abs-patch.md"))
        end
      end

      it "increments minor version" do
        FakeFS do
          new_version = @changelog.update(inc_minor: true)
          expect(new_version).to eq("0.3.0")
          full_text = File.open(@repo.changelog_path, "r").read
          expect(full_text).to eq(sample_text("vegetables-inc-minor.md"))
        end
      end

      it "absolute minor version" do
        FakeFS do
          new_version = @changelog.update(abs_minor: 4)
          expect(new_version).to eq("0.4.0")
          full_text = File.open(@repo.changelog_path, "r").read
          expect(full_text).to eq(sample_text("vegetables-abs-minor.md"))
        end
      end

      it "increments major version" do
        FakeFS do
          new_version = @changelog.update(inc_major: true)
          expect(new_version).to eq("1.0.0")
          full_text = File.open(@repo.changelog_path, "r").read
          expect(full_text).to eq(sample_text("vegetables-inc-major.md"))
        end
      end

      it "absolute major version" do
        FakeFS do
          new_version = @changelog.update(abs_major: 3)
          expect(new_version).to eq("3.0.0")
          full_text = File.open(@repo.changelog_path, "r").read
          expect(full_text).to eq(sample_text("vegetables-abs-major.md"))
        end
      end

    end # context

  end # describe
end
