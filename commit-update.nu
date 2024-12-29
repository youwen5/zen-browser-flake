#!/usr/bin/env -S nix shell nixpkgs#nushell --command nu

use update.nu

def commit_update []: nothing -> nothing {
  let zen_latest = update generate_sources

  git add -A
  let commit = git commit -m $"auto-update: ($zen_latest.prev_tag) -> ($zen_latest.new_tag)" | complete

  if ($commit.exit_code == 1) {
    print $"Latest version is ($zen_latest.prev_tag), no updates found"
  } else {
    print $"Performed update from ($zen_latest.prev_tag) -> ($zen_latest.new_tag)"
  }
}

commit_update
