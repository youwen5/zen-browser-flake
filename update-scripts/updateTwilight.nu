# to invoke generate_sources directly, enter nushell and run
# `use update.nu`
# `update generate_sources`

def get_nix_hash [url: string]: nothing -> string  {
  nix store prefetch-file --hash-type sha256 --json $url | from json | get hash
}

export def generate_twilight_sources []: nothing -> record {
  let tag = "twilight"
  let prev_sources: record = open ./sources.json

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

  echo $sources | save --force "twilightSources.json"

  return {
    new_tag: $tag
    prev_tag: $prev_sources.version
  }
}
