{
  stdenv,
  makeWrapper,
  copyDesktopItems,
  wrapGAppsHook3,
  libGL,
  libGLU,
  libevent,
  libffi,
  libjpeg,
  libpng,
  libstartup_notification,
  libvpx,
  libwebp,
  fontconfig,
  libxkbcommon,
  zlib,
  freetype,
  gtk3,
  libxml2,
  dbus,
  xcb-util-cursor,
  alsa-lib,
  libpulseaudio,
  pango,
  atk,
  cairo,
  gdk-pixbuf,
  glib,
  udev,
  libva,
  mesa,
  libnotify,
  cups,
  pciutils,
  ffmpeg,
  libglvnd,
  pipewire,
  upower,
  xorg,
  lib,
  variant ? "specific",
  disableUpdateChecks ? true,
  extraPolicies ? { },
  ...
}:
let
  version = "1.0.1-a.21";
  runtimeLibs =
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
      upower
    ]
    ++ (with xorg; [
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

  downloadUrl = {
    "specific" = {
      url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-specific.tar.bz2";
      sha256 = "sha256:0ljwz9ssy461xkcpnmcyf80pycd94qmw9bzbp9cphqls9qd56may";
    };
    "generic" = {
      url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-generic.tar.bz2";
      sha256 = "sha256:0h3hk8n6n16fml6lj025g12nhl9plixwjxfl599z1s47dfs09p7c";
    };
    "aarch64" = {
      url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-aarch64.tar.bz2";
      sha256 = "sha256:1949ni6j6ajbwbq1w5bdmhcglc1g5006l3ahb4x4cah4khaxnk94";
    };
  };

  downloadData = if stdenv.hostPlatform.isAarch then downloadUrl.aarch64 else downloadUrl.${variant};

  policiesJson = builtins.toFile "policies.json" (
    lib.strings.toJSON {
      policies = {
        DisableAppUpdate = disableUpdateChecks;
        DontCheckDefaultBrowser = true;
      } // extraPolicies;
    }
  );

in
stdenv.mkDerivation {
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
    makeWrapper
    copyDesktopItems
    wrapGAppsHook3
  ];

  installPhase = ''
    mkdir -p $out/bin && cp -r $src/* $out/bin
    install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop
    install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
  '';

  fixupPhase = ''
    chmod 755 $out/bin/*
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen
    wrapProgram $out/bin/zen --set LD_LIBRARY_PATH "${lib.makeLibraryPath runtimeLibs}" \
          --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen-bin
    wrapProgram $out/bin/zen-bin --set LD_LIBRARY_PATH "${lib.makeLibraryPath runtimeLibs}" \
          --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/glxtest
    wrapProgram $out/bin/glxtest --set LD_LIBRARY_PATH "${lib.makeLibraryPath runtimeLibs}"
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/updater
    wrapProgram $out/bin/updater --set LD_LIBRARY_PATH "${lib.makeLibraryPath runtimeLibs}"
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/vaapitest
    wrapProgram $out/bin/vaapitest --set LD_LIBRARY_PATH "${lib.makeLibraryPath runtimeLibs}"

    mkdir $out/bin/distribution
    touch $out/bin/distribution/policies.json
    cp ${policiesJson} $out/bin/distribution/policies.json
  '';

  meta.mainProgram = "zen";
}
