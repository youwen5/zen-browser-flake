#!/usr/bin/env -S nix shell nixpkgs#nushell --command nu

use update.nu

def commit_update []: nothing -> nothing {
  let zen_latest = update generate_sources

  if not $zen_latest.changed {
    print $"Latest version is ($zen_latest.new_tag), no updates found"
    return
  }

  if $zen_latest.reason == "new-version" {
    print $"Performed update from ($zen_latest.prev_tag) -> ($zen_latest.new_tag)"
  } else {
    print $"Upstream assets for ($zen_latest.new_tag) changed since our last update, refreshing hashes"
  }

  let hash_note = if $zen_latest.reason == "hash-refresh" { " (hash refresh)" } else { "" }

  git add -A
  git commit -m $"auto-update: ($zen_latest.prev_tag) -> ($zen_latest.new_tag)($hash_note)"

  print "Updating Flake lockfile"
  nix flake update --commit-lock-file

  let build = nix build | complete
  if ($build.exit_code == 0) {
    git push
  } else {
    print $"Update was successful, but there was a build failure! ($build.stderr). Not pushing update."
  }
}

commit_update
