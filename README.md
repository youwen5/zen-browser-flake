# Zen Browser for Nix

This is a flake for the Zen browser. Originally forked from the unmaintained
[MarceColl/zen-browser-flake](https://github.com/MarceColl/zen-browser-flake),
but heavily modified. GitHub Actions is configured to automatically check for updates daily.

The primary difference between this flake and most of the other forks
available is it has more correct packaging that closely mirrors how Firefox is packaged in nixpkgs,
using `wrapFirefox`. For instance Zen's desktop file is extracted directly from the binary
instead of being provided manually.

The annoying update checks have been disabled by default through a Firefox policy. The browser cannot
update itself when installed with Nix anyways, so these are entirely useless.

Similar to the `firefox` package in `nixpkgs`, you can set additional policies
by using `override` on the `extraPolicies` property. See [the
derivation](./zen-browser.nix) for more technical details.

To use, add it to the relevant NixOS configuration flake inputs:

```nix
inputs = {
  # ...
  zen-browser.url = "github:youwen5/zen-browser-flake";

  # optional, but recommended so it shares system libraries, and improves startup time
  zen-browser.inputs.nixpkgs.follows = "nixpkgs";
  # ...
}
```

## Packages

This flake provides the `zen-browser` package, which is also its default
package, for both `x86_64-linux` and `aarch64-linux` systems.

Additionally, `zen-browser-unwrapped` is provided (similar to
`firefox-bin-unwrapped`). A tree of the provided packages is displayed below
for your convenience.

```
packages
├───aarch64-linux
│   ├───default: package
│   ├───zen-browser: package
│   └───zen-browser-unwrapped: package
└───x86_64-linux
    ├───default: package
    ├───zen-browser: package
    └───zen-browser-unwrapped: package
```

## Installation

In `environment.systemPackages`, add something similar to:

```nix
inputs.zen-browser.packages.${pkgs.system}.default
```

A binary called `zen` is provided.

You can also install it using the CLI imperatively:

`nix profile install github:youwen5/zen-browser`

## Caveats

As with all GPU accelerated programs, Zen may not be able to use GPU
acceleration if not installed on NixOS (and if you didn't override its nixpkgs
input to your system nixpkgs, if using NixOS).

This can be solved with
[nix-community/nixGL](https://github.com/nix-community/nixGL).

For Asahi Linux Fedora Remix users, you will need to apply the overlay from
[this repo](https://github.com/tpwrules/nixos-apple-silicon/) to your
nixpkgs, and then override this flake's nixpkgs input, and then use nixGL to
get everything working properly. If that sounds too involved for you, I don't
recommend using Nix to install Zen.

## 1Password

Zen has to be manually added to the list of browsers that 1Password will
communicate with. See [this wiki article](https://nixos.wiki/wiki/1Password)
for more information. To enable 1Password integration, you need to add the line
`.zen-wrapped` to the file `/etc/1password/custom_allowed_browsers`.

## License

GitHub says this repo is forked from
[MarceColl/zen-browser-flake](https://github.com/MarceColl/zen-browser-flake),
but this is a historical artifact. It shares effectively zero code or logic
with the original after a complete rewrite to use `autoPatchelfHook` and
`wrapFirefox` instead of manually patching in `fixupPhase`. The Nix code is
licensed under the Unlicense and is released unencumbered into the public
domain. Feel free to fork and use for whatever purposes.
