{
  stdenv,
  config,
  wrapGAppsHook3,
  autoPatchelfHook,
  patchelfUnstable,
  adwaita-icon-theme,
  dbus-glib,
  libXtst,
  curl,
  gtk3,
  alsa-lib,
  libva,
  pciutils,
  pipewire,
  writeText,
  variant ? "specific",
  ...
}:
let
  version = "1.0.2-b.0";

  downloadUrl = {
    "specific" = {
      url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-specific.tar.bz2";
      sha256 = "sha256:067m7g48nfa366ajn3flphnwkx8msc034r6px8ml66mbj7awjw4x";
    };
    "generic" = {
      url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-generic.tar.bz2";
      sha256 = "sha256:02x4w2fq80s1za05s0gg9r2drr845bln80h5hbwhvp1gxq9jf0g2";
    };
    "aarch64" = {
      url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-aarch64.tar.bz2";
      sha256 = "sha256:1gzxdrb3kfhqyj03a1hd975imx92jgc72rn67xm3xw3yxa3x6isj";
    };
  };

  downloadData = if stdenv.hostPlatform.isAarch then downloadUrl.aarch64 else downloadUrl.${variant};

  policies = {
    DisableAppUpdate = true;
  } // config.zen.policies or { };

  policiesJson = writeText "firefox-policies.json" (builtins.toJSON { inherit policies; });
in
stdenv.mkDerivation (finalAttrs: {
  inherit version;
  pname = "zen-browser-unwrapped";

  src = builtins.fetchTarball {
    url = downloadData.url;
    sha256 = downloadData.sha256;
  };

  desktopSrc = ./.;

  nativeBuildInputs = [
    wrapGAppsHook3
    autoPatchelfHook
    patchelfUnstable
  ];

  buildInputs = [
    gtk3
    alsa-lib
    adwaita-icon-theme
    dbus-glib
    libXtst
  ];

  runtimeDependencies = [
    curl
    libva.out
    pciutils
  ];

  appendRunpaths = [
    "${pipewire}/lib"
  ];

  installPhase = ''
    mkdir -p "$prefix/lib/zen-${version}"
    cp -r * "$prefix/lib/zen-${version}"

    mkdir -p $out/bin
    ln -s "$prefix/lib/zen-${version}/zen" $out/bin/zen

    mkdir -p "$out/lib/zen-${version}/distribution"
    ln -s ${policiesJson} "$out/lib/zen-${version}/distribution/policies.json"
  '';

  patchelfFlags = [ "--no-clobber-old-sections" ];

  meta = {
    mainProgram = "zen";
    description = ''
      Zen is a privacy-focused browser that blocks trackers, ads, and other unwanted content while offering the best browsing experience!
    '';
  };

  passthru = {
    inherit gtk3;

    libName = "zen-${version}";
    binaryName = finalAttrs.meta.mainProgram;
    gssSupport = true;
    ffmpegSupport = true;
  };
})
