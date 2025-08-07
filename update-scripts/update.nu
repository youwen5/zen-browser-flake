# to invoke generate_sources directly, enter nushell and run
# `use update.nu`
# `update generate_sources`

def get_latest_release [repo: string]: nothing -> string {
  try {
	http get $"https://api.github.com/repos/($repo)/releases"
	  | where prerelease == false
	  | where tag_name != "twilight"
	  | get tag_name
	  | get 0
  } catch { |err| $"Failed to fetch latest release, aborting: ($err.msg)" }
}

def get_nix_hash [url: string]: nothing -> string  {
  nix store prefetch-file --hash-type sha256 --json $url | from json | get hash
}

export def generate_sources []: nothing -> record {
  let tag = get_latest_release "zen-browser/desktop"
  let prev_sources: record = open ./sources.json

  let x86_64_url_tw = $"https://github.com/zen-browser/desktop/releases/download/twilight/zen.linux-x86_64.tar.xz"
  let aarch64_url_tw = $"https://github.com/zen-browser/desktop/releases/download/twilight/zen.linux-aarch64.tar.xz"
  let sourcesTw = {
	version: "twilight"
	x86_64-linux: {
	  url:  $x86_64_url_tw
	  hash: (get_nix_hash $x86_64_url_tw)
	}
	aarch64-linux: {
	  url: $aarch64_url_tw
	  hash: (get_nix_hash $aarch64_url_tw)
	}
  }

  echo $sourcesTw | save --force "twilightSources.json"

  if $tag == $prev_sources.version {
	return {
	  prev_tag: $tag
	  new_tag: $tag
	}
  }

  let x86_64_url = $"https://github.com/zen-browser/desktop/releases/download/($tag)/zen.linux-x86_64.tar.xz"
  let aarch64_url = $"https://github.com/zen-browser/desktop/releases/download/($tag)/zen.linux-aarch64.tar.xz"
  let sources = {
	version: $tag
	x86_64-linux: {
	  url:  $x86_64_url
	  hash: (get_nix_hash $x86_64_url)
	}
	aarch64-linux: {
	  url: $aarch64_url
	  hash: (get_nix_hash $aarch64_url)
	}
  }

  echo $sources | save --force "sources.json"

  return {
    new_tag: $tag
    prev_tag: $prev_sources.version
  }
}
