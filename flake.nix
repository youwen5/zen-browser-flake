{
  description = "Zen Browser binary supporting wrapFirefox";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zen-browser-specific = {
      url = "https://github.com/zen-browser/desktop/releases/download/1.0.2-b.0/zen.linux-specific.tar.bz2";
      flake = false;
    };
    zen-browser-generic = {
      url = "https://github.com/zen-browser/desktop/releases/download/1.0.2-b.0/zen.linux-generic.tar.bz2";
      flake = false;
    };
    zen-browser-aarch64 = {
      url = "https://github.com/zen-browser/desktop/releases/download/1.0.2-b.0/zen.linux-aarch64.tar.bz2";
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
      packages."x86_64-linux" =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        rec {
          zen-browser-unwrapped = pkgs.callPackage ./zen-browser-unwrapped.nix {
            sources = inputs;
          };
          zen-browser = pkgs.callPackage ./zen-browser.nix { inherit zen-browser-unwrapped; };
          zen-browser-generic-unwrapped = pkgs.callPackage ./zen-browser-unwrapped.nix {
            sources = inputs;
            variant = "generic";
          };
          zen-browser-generic = pkgs.callPackage ./zen-browser.nix {
            zen-browser-unwrapped = zen-browser-generic-unwrapped;
          };
          default = zen-browser;
        };

      packages."aarch64-linux" =
        let
          pkgs = import nixpkgs { system = "aarch64-linux"; };
        in
        rec {
          zen-browser-unwrapped = pkgs.callPackage ./zen-browser-unwrapped.nix {
            sources = inputs;
          };
          zen-browser = pkgs.callPackage ./zen-browser.nix { inherit zen-browser-unwrapped; };
          default = zen-browser;
        };

      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.nixfmt-rfc-style
      );

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
              # super duper janky update script
              (pkgs.writeShellScriptBin "update" ''
                set -euo pipefail

                fetch_latest_release() {
                  local repo="$1"
                  curl -s "https://api.github.com/repos/''${repo}/releases" | jq -r '.[] | select(.prerelease == false) | .tag_name' | head -n 1
                }

                update() {
                  local file="flake.nix"

                  local latest_tag
                  latest_tag=$(fetch_latest_release "zen-browser/desktop")

                  if [[ -z "$latest_tag" ]]; then
                    echo "Error: Failed to fetch the latest release tag." >&2
                    exit 1
                  fi

                  sed -i "s@\(\https://github.com/zen-browser/desktop/releases/download/\)[^/]\+\(/zen\.linux-\(specific\|generic\|aarch64\)\.tar\.bz2\)@\1''${latest_tag}\2@g" flake.nix

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
