{
  description =
    "Flake that provides Zen Browser binaries wrapped and patched for NixOS.";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          sources = builtins.fromJSON (builtins.readFile ./sources.json);
          twilightSources =
            builtins.fromJSON (builtins.readFile ./twilightSources.json);
        in rec {
          zen-browser-unwrapped = pkgs.callPackage ./zen-browser-unwrapped.nix {
            inherit (sources.${system}) hash url;
            inherit (sources) version;
          };

          zen-browser = pkgs.callPackage ./zen-browser.nix {
            inherit zen-browser-unwrapped;
          };

          zen-browser-twilight-unwrapped =
            pkgs.callPackage ./zen-browser-unwrapped.nix {
              inherit (twilightSources.${system}) hash url;
              inherit (twilightSources) version;
            };

          zen-browser-twilight = pkgs.callPackage ./zen-browser.nix {
            zen-browser-unwrapped = zen-browser-twilight-unwrapped;
            pname = "zen-browser-twilight";
          };

          default = zen-browser;
        });

      apps = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          update = {
            type = "app";
            program =
              "${pkgs.callPackage ./update-scripts { }}/bin/commit-update.nu";
          };
        });

      formatter = forAllSystems
        (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
