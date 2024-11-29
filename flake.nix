{
  description = "Zen Browser";

  inputs = {
    zen-browser-source.url = "github:youwen5/zen-browser-source-flake";
    nixpkgs.follows = "zen-browser-source/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      zen-browser-source,
    }:
    let
      system = "x86_64-linux";
      version = "1.0.1-a.22";
      downloadUrl = {
        "specific" = {
          url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-specific.tar.bz2";
          sha256 = "sha256:0anr79rdm62h5y37xa47rrrk32r9gnv04df4z7brc0hp4q83pxvi";
        };
        "generic" = {
          url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-generic.tar.bz2";
          sha256 = "sha256:065rl1fhg79bkj1qy960qcid7wr7vd7j3wsf7bbr69b4rgmqqv3z";
        };
      };

      pkgs = import nixpkgs {
        inherit system;
      };

      runtimeLibs =
        with pkgs;
        [
          libGL
          libGLU
          libevent
          libffi
          libjpeg
          libpng
          libstartup_notification
          libvpx
          libwebp
          stdenv.cc.cc
          fontconfig
          libxkbcommon
          zlib
          freetype
          gtk3
          libxml2
          dbus
          xcb-util-cursor
          alsa-lib
          libpulseaudio
          pango
          atk
          cairo
          gdk-pixbuf
          glib
          udev
          libva
          mesa
          libnotify
          cups
          pciutils
          ffmpeg
          libglvnd
          pipewire
        ]
        ++ (with pkgs.xorg; [
          libxcb
          libX11
          libXcursor
          libXrandr
          libXi
          libXext
          libXcomposite
          libXdamage
          libXfixes
          libXScrnSaver
        ]);

      mkZen =
        { variant }:
        let
          downloadData = downloadUrl."${variant}";
        in
        pkgs.stdenv.mkDerivation {
          inherit version;
          pname = "zen-browser";

          src = builtins.fetchTarball {
            url = downloadData.url;
            sha256 = downloadData.sha256;
          };

          desktopSrc = ./.;

          phases = [
            "installPhase"
            "fixupPhase"
          ];

          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.copyDesktopItems
            pkgs.wrapGAppsHook
          ];

          installPhase = ''
            mkdir -p $out/bin && cp -r $src/* $out/bin
            install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop
            install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
          '';

          fixupPhase = ''
            		  chmod 755 $out/bin/*
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen
            		  wrapProgram $out/bin/zen --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
                                --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen-bin
            		  wrapProgram $out/bin/zen-bin --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
                                --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/glxtest
            		  wrapProgram $out/bin/glxtest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/updater
            		  wrapProgram $out/bin/updater --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/vaapitest
            		  wrapProgram $out/bin/vaapitest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
            		'';

          meta.mainProgram = "zen";
        };
    in
    {
      packages."x86_64-linux" = {
        generic = mkZen { variant = "generic"; };
        specific = mkZen { variant = "specific"; };
        default = self.packages."${system}".specific;
      };
      packages."aarch64-linux" = rec {
        zen-browser-unwrapped =
          zen-browser-source.packages."aarch64-linux".zen-browser-unwrapped.overrideAttrs
            (
              final: prev: {
                inherit version;
              }
            );
        zen-browser = zen-browser-source.packages."aarch64-linux".zen-browser.overrideAttrs (
          final: prev: {
            inherit version;
          }
        );
        default = zen-browser;
      };

      formatter."aarch64-linux" = nixpkgs.legacyPackages."aarch64-linux".nixfmt-rfc-style;
      formatter."x86_64-linux" = nixpkgs.legacyPackages."x86_64-linux".nixfmt-rfc-style;
    };

  nixConfig = {
    extra-substituters = [
      "https://zen-browser.cachix.org"
    ];
    extra-trusted-public-keys = [
      "zen-browser.cachix.org-1:z/QLGrEkiBYF/7zoHX1Hpuv0B26QrmbVBSy9yDD2tSs="
    ];
  };
}
