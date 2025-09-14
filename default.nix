{
  pkgs,
  system ? pkgs.system,
  ...
}:
let
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
