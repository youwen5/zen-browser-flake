{
  description = "Zen Browser binary supporting wrapFirefox";

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
      packages."x86_64-linux" =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        rec {
          zen-browser-unwrapped = pkgs.callPackage ./zen-browser-unwrapped.nix { };
          zen-browser = pkgs.callPackage ./zen-browser.nix { inherit zen-browser-unwrapped; };
          zen-browser-generic-unwrapped = pkgs.callPackage ./zen-browser-unwrapped.nix {
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
          zen-browser-unwrapped = pkgs.callPackage ./zen-browser-unwrapped.nix { };
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
    };
}
