{
  description = "Flake that provides Zen Browser binaries wrapped and patched for NixOS.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
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
          sources = builtins.fromJSON (builtins.readFile ./sources.json);
        in
        rec {
          zen-browser-unwrapped = pkgs.callPackage ./zen-browser-unwrapped.nix {
            inherit (sources.${system}) hash url;
            inherit (sources) version;
          };
          zen-browser = pkgs.callPackage ./zen-browser.nix { inherit zen-browser-unwrapped; };
          zen-browser-generic = builtins.trace "WARNING: Zen upstream no longer differentiates between specific and generic builds, this package is kept for flake backwards-compatibility only. Please use the default `zen-browser` package instead." zen-browser;
          default = zen-browser;
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          update = {
            type = "app";
            program = "${pkgs.callPackage ./update-scripts { }}/bin/commit-update.nu";
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
