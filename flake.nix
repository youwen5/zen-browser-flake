{
  description = "Zen Browser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      # currently the only version with aarch64 builds is twilight
      version = "twilight";

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
          zen-browser = pkgs.callPackage ./zen-browser.nix { inherit version; };
          zen-browser-generic = pkgs.callPackage ./zen-browser.nix {
            inherit version;
            variant = "generic";
          };
          default = zen-browser;
        };

      packages."aarch64-linux" =
        let
          pkgs = import nixpkgs { system = "aarch64-linux"; };
        in
        rec {
          zen-browser = pkgs.callPackage ./zen-browser.nix { inherit version; };
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
