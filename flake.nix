{
  description = "Flake that provides Zen Browser binaries wrapped and patched for NixOS.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zen-browser-x86_64 = {
      url = "https://github.com/zen-browser/desktop/releases/download/1.0.2-b.5/zen.linux-x86_64.tar.bz2";
      flake = false;
    };
    zen-browser-aarch64 = {
      url = "https://github.com/zen-browser/desktop/releases/download/1.0.2-b.5/zen.linux-aarch64.tar.bz2";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        rec {
          zen-browser-unwrapped = pkgs.callPackage ./zen-browser-unwrapped.nix { sources = inputs; };
          zen-browser = pkgs.callPackage ./zen-browser.nix { inherit zen-browser-unwrapped; };
          zen-browser-generic = builtins.trace "WARNING: Zen upstream no longer differentiates between specific and generic builds, this package is kept for flake backwards-compatibility only. Please use the default `zen-browser` package instead." zen-browser;
          default = zen-browser;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          updater = pkgs.mkShell {
            packages = [
              pkgs.jq
              pkgs.gnused
              pkgs.curl
              pkgs.fh
              (pkgs.writeShellScriptBin "update" ''
                set -euo pipefail

                fetch_latest_release() {
                  local repo="$1"
                  curl -s "https://api.github.com/repos/''${repo}/releases" | jq -r '.[] | select(.prerelease == false) | .tag_name' | head -n 1
                }

                update() {
                  local latest_tag
                  latest_tag=$(fetch_latest_release "zen-browser/desktop")

                  if [[ -z "$latest_tag" ]]; then
                    echo "Error: Failed to fetch the latest release tag." >&2
                    exit 1
                  fi

                  fh add --input-name zen-browser-x86_64 "https://github.com/zen-browser/desktop/releases/download/$latest_tag/zen.linux-x86_64.tar.bz2"
                  fh add --input-name zen-browser-aarch64 "https://github.com/zen-browser/desktop/releases/download/$latest_tag/zen.linux-aarch64.tar.bz2"

                  echo "$latest_tag"
                }

                echo "$(update)"
              '')
            ];
          };
        }
      );
    };
}
