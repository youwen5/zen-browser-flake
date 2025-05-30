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

  # optional, but recommended if you closely follow NixOS unstable so it shares
  # system libraries, and improves startup time
  # NOTE: if you experience a build failure with Zen, the first thing to check is to remove this line!
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

The easiest way is to use the CLI imperatively:

`nix profile install github:youwen5/zen-browser-flake`

If you're on NixOS and/or home-manager, you should install it in your system or
home configuration.

For example, in `configuration.nix`, add something similar to:

```nix
environment.systemPackages = [
  inputs.zen-browser.packages.${pkgs.system}.default
];
```

If you don't want to use flakes, you can add it like:

```nix
environment.systemPackages = 
  let
    zen-browser = import (builtins.fetchTarball "https://github.com/youwen5/zen-browser-flake/archive/master.tar.gz") {
      inherit pkgs;
    };
  in
  [
    zen-browser    
  ];
```

A binary called `zen` is provided as well as a desktop file that should show up
in app launchers.


## FAQ

> How to run the update script locally?

There's a workflow configured that runs every day at 8PM Pacific Time to
automatically check for any new releases from `zen-browser/desktop` and update
the flake. If you want to run the script manually, just enter the repo's
directory and run

```sh
nix run .#update
```

> Is there a Cachix (binary cache)?

Since we're not building from source and just wrapping upstream binaries we
don't really need a binary cache as the patching process should take just a
few seconds.

If you're experiencing abnormally long build times you probably aren't
overriding the `nixpkgs` input and it's duplicating a lot of system libraries.
Just set `inputs.zen-browser.inputs.nixpkgs.follows = "nixpkgs"` or something
similar.

## Caveats

As with all GPU accelerated programs, Zen may not be able to use GPU
acceleration if not installed on NixOS (and if you didn't override its nixpkgs
input to your system nixpkgs, if using NixOS).

This can be solved with
[nix-community/nixGL](https://github.com/nix-community/nixGL).

## 1Password

Zen has to be manually added to the list of browsers that 1Password will
communicate with. See [this wiki article](https://nixos.wiki/wiki/1Password)
for more information. To enable 1Password integration, you need to add the line
`zen` to the file `/etc/1password/custom_allowed_browsers`.

## License

The derivation in `./zen-browser-unwrapped.nix` is mostly based on
[firefox-bin-unwrapped](https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/applications/networking/browsers/firefox-bin/default.nix#L119)
which is MIT licensed Copyright (c) 2003-2025 Eelco Dolstra and the
Nixpkgs/NixOS contributors.

The rest of the code is licensed under the Unlicense and is released
unencumbered into the public domain. Feel free to fork and use for whatever
purposes. 
