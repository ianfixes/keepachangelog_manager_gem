#!/bin/bash

# This script automates the gem release project for this repo.
# It can very likely be adapted to your own.

# test if we have an arguments on the command line
if [ $# -lt 1 ]
then
    echo "You must pass an argument for KeepAChangelogManager:"
    bundle exec keepachangelog_manager.rb
    exit 1
fi

# set up a cleanup function for any errors, so that we git stash pop
cleanup () {
  set +x +e
  echo -e "\n### Reverting uncommitted changes"
  git checkout README.md CHANGELOG.md lib/keepachangelog_manager/version.rb
  if [ $DID_STASH -eq 0 ]; then
    echo -e "\n### Unstashing changes"
    git stash pop
  fi
  exit $1
}

DIDNT_STASH="No local changes to save"
DID_STASH=1
echo -ne "\n### Stashing changes..."
STASH_OUTPUT=$(git stash save)
[ "$DIDNT_STASH" != "$STASH_OUTPUT" ]
DID_STASH=$?

trap "cleanup 1" INT TERM ERR
set -xe

# ensure latest master
git pull --rebase

# update version in changelog and save it
NEW_VERSION=$(bundle exec keepachangelog_manager.rb $@)

echo "Checking whether new version string is a semver"
echo $NEW_VERSION | grep -Eq ^[0-9]*\.[0-9]*\.[0-9]*$

# write version.rb with new version
cat << EOF > lib/keepachangelog_manager/version.rb
module KeepAChangelogManager
  VERSION = "$NEW_VERSION".freeze
end
EOF

# update README with new version
sed -e "s/\/gems\/keepachangelog_manager\/[0-9]*\.[0-9]*\.[0-9]*)/\/gems\/keepachangelog_manager\/$NEW_VERSION)/" -i "" README.md

# mutation!
git add README.md CHANGELOG.md lib/keepachangelog_manager/version.rb
git commit -m "v$NEW_VERSION bump"
git tag -a v$NEW_VERSION -m "Released version $NEW_VERSION"
gem build *.gemspec
gem push *-$NEW_VERSION.gem
git push upstream
git push upstream --tags

# do normal cleanup
cleanup 0
