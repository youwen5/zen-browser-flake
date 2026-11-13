# to invoke generate_sources directly, enter nushell and run
# `use update.nu`
# `update generate_sources`

def get_latest_release [repo: string]: nothing -> record {
  try {
	http get $"https://api.github.com/repos/($repo)/releases"
	  | where prerelease == false
	  | where tag_name != "twilight"
	  | first
  } catch { |err|
    error make {msg: $"Failed to fetch latest release, aborting: ($err.msg)"}
  }
}

def get_firefox_version [tag: string]: nothing -> string {
  try {
    http get $"https://raw.githubusercontent.com/zen-browser/desktop/($tag)/surfer.json"
      | get version.version
  } catch { |err|
    error make {msg: $"Failed to fetch Firefox version for ($tag), aborting: ($err.msg)"}
  }
}

def get_nix_hash [url: string]: nothing -> string  {
  nix store prefetch-file --hash-type sha256 --json $url | from json | get hash
}

# GitHub publishes a sha256 digest for every release asset. When upstream
# re-uploads an asset while keeping the same tag, the digest changes even
# though the version does not - exactly the case that silently leaves the
# hashes in sources.json stale and breaks every build.
def get_asset_digest [release: record, asset: string]: nothing -> any {
  let match = $release.assets | where name == $asset
  if ($match | is-empty) {
    error make {msg: $"Asset ($asset) not found in release ($release.tag_name), aborting"}
  }
  # The digest may be unavailable (e.g. on some GitHub Enterprise servers);
  # return null so the caller falls back to re-checking by downloading.
  $match | get 0 | get -o digest
}

export def generate_sources []: nothing -> record {
  let release = get_latest_release "zen-browser/desktop"
  let tag = $release.tag_name
  let prev_sources: record = open ./sources.json

  let x86_64_url = $"https://github.com/zen-browser/desktop/releases/download/($tag)/zen.linux-x86_64.tar.xz"
  let aarch64_url = $"https://github.com/zen-browser/desktop/releases/download/($tag)/zen.linux-aarch64.tar.xz"

  let version_changed = $tag != $prev_sources.version

  # Cheap fast path: if the tag is unchanged and GitHub's digests for the
  # assets still match the ones we recorded, nothing was re-uploaded.
  let x86_64_digest = get_asset_digest $release "zen.linux-x86_64.tar.xz"
  let aarch64_digest = get_asset_digest $release "zen.linux-aarch64.tar.xz"
  let prev_x86_64_digest = $prev_sources.x86_64-linux.digest?
  let prev_aarch64_digest = $prev_sources.aarch64-linux.digest?

  if (not $version_changed) and ($x86_64_digest != null) and ($aarch64_digest != null) and ($x86_64_digest == $prev_x86_64_digest) and ($aarch64_digest == $prev_aarch64_digest) {
	# everything up to date
	return {
	  changed: false
	  reason: "up-to-date"
	  prev_tag: $tag
	  new_tag: $tag
	}
  }

  # The version changed, or the assets were re-uploaded (or we could not
  # tell): fetch the current hashes from upstream so sources.json matches
  # reality again.
  let firefox_version = if $version_changed {
    get_firefox_version $tag
  } else {
    $prev_sources.firefoxVersion
  }

  let sources = {
	version: $tag
	firefoxVersion: $firefox_version
	x86_64-linux: {
	  url:  $x86_64_url
	  hash: (get_nix_hash $x86_64_url)
	  digest: $x86_64_digest
	}
	aarch64-linux: {
	  url: $aarch64_url
	  hash: (get_nix_hash $aarch64_url)
	  digest: $aarch64_digest
	}
  }

  if $sources == $prev_sources {
	# digests were missing or stale, but the real hashes still match:
	# nothing to update
	return {
	  changed: false
	  reason: "up-to-date"
	  prev_tag: $tag
	  new_tag: $tag
	}
  }

  echo $sources | save --force "sources.json"

  let reason = if $version_changed {
	"new-version"
  } else {
	"hash-refresh"
  }

  return {
    changed: true
    reason: $reason
    prev_tag: $prev_sources.version
    new_tag: $tag
  }
}
