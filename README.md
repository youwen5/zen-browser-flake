# Zen Browser

This is a flake for the Zen browser. Originally forked from
[MarceColl/zen-browser-flake](https://github.com/MarceColl/zen-browser-flake),
but heavily modified to suit my needs. Also actively maintained, unlike the
upstream.

I have disabled the annoying update checks by default, as well as Zen trying
to set itself as the default browser, through `policies.json`.

Similar to the `firefox` package in `nixpkgs`, you can set additional policies
by using `overrideAttrs` on the `extraPolicies` property. You can also set
`disableUpdateChecks` using `overrideAttrs` if you want to re-enable update
checks for some reason. See [the derivation](./zen-browser.nix) for more
technical details.

To use, add it to the relevant NixOS configuration flake inputs:

```nix
inputs = {
  ...
  zen-browser.url = "github:youwen5/zen-browser-flake";

  # optional, but recommended so it shares system libraries, and improves startup time
  zen-browser.inputs.nixpkgs.follows = "nixpkgs";
  ...
}
```

> [!NOTE]
> This flake provides a Zen version currently out of date on purpose
> (`1.0.1-a.21`). This is because the latest `1.0.1-a.22` release actually
> reverts to a previous version that is using an outdated Firefox ESR with
> known security vulnerabilities (CVEs).
>
> In the interest of not exposing users to any known security issues, I have
> decided to keep this flake on `1.0.1-a.21` until Zen releases a new version
> that is using the latest Firefox ESR. Also, `1.0.1-a.22` does not have an
> aarch64-linux binary release.

## Packages

This flake provides the `zen-browser` package, which is also its default
package. On x86_64 systems, this corresponds to the "specific" build of Zen
Browser. On aarch64 systems, this is simply the default and only aarch64 build.

For "x86_64-linux" systems only, the flake also provides `zen-browser-generic`, which
corresponds to the "generic" build of Zen Browser. On aarch64 based systems
there is no distinction between generic or specific.

> [!NOTE]
> Essentially, the "specific" build enables `avx2` processor
> optimizations at compile time for some marginal performance increases. If you
> have a relatively recent CPU, you should be able to run it with no issues. If
> you have an older CPU, you may want to use the "generic" build.
>
> If the above technical jargon does not mean anything to you, just install the
> default package for your system, and install `zen-browser-generic` if things
> don't work.

A tree of the provided packages is displayed below for your convenience.

```
packages
├───aarch64-linux
│   ├───default
│   └───zen-browser
└───x86_64-linux
    ├───default
    ├───zen-browser
    └───zen-browser-generic
```

## Installation

In `environment.systemPackages`, add one of:

```nix
# for most modern systems
inputs.zen-browser.packages.${pkgs.system}.default

# for older CPUs without AVX2 extension set
inputs.zen-browser.packages."x86_64-linux".zen-browser-generic
```

A binary called `zen` is provided.

You can also install it using the CLI imperatively:

`nix profile install github:youwen5/zen-browser`

For the generic version (x86_64-linux only):

`nix profile install github:youwen5/zen-browser#zen-browser-generic`

## 1Password

Zen has to be manually added to the list of browsers that 1Password will
communicate with. See [this wiki article](https://nixos.wiki/wiki/1Password)
for more information. To enable 1Password integration, you need to add the line
`.zen-wrapped` to the file `/etc/1password/custom_allowed_browsers`.
