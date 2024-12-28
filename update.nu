#!/usr/bin/env -S nix shell nixpkgs#nushell --command nu

def get_latest_release [repo: string] {
  try {
	http get $"https://api.github.com/repos/($repo)/releases"
	  | where prerelease == false
	  | where tag_name != "twilight"
	  | get tag_name
	  | get 0
  } catch { |err| $"Failed to fetch latest release, aborting: ($err.msg)" }
}

def get_nix_hash [url: string] {
  nix store prefetch-file --hash-type sha256 --json $url | from json | get hash
}

def generate_sources [] {
  let tag = get_latest_release "zen-browser/desktop"
  let prev_sources = open ./sources.json

  if $tag == $prev_sources.version {
	# everything up to date
	return $tag
  }

  let x86_64_url = $"https://github.com/zen-browser/desktop/releases/download/($tag)/zen.linux-x86_64.tar.bz2"
  let aarch64_url = $"https://github.com/zen-browser/desktop/releases/download/($tag)/zen.linux-aarch64.tar.bz2"
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

  return $tag
}

generate_sources
