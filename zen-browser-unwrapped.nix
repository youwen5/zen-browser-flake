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
  version = "1.0.1-a.21";

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

  policies = {
    DisableAppUpdate = true;
    ManualAppUpdateOnly = true;
    AppAutoUpdate = false;
    DontCheckDefaultBrowser = true;
  } // config.firefox.policies or { };

  policiesJson = writeText "firefox-policies.json" (builtins.toJSON { inherit policies; });
in
stdenv.mkDerivation (finalAttrs: {
  inherit version;
  pname = "zen-browser";

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

    binaryName = finalAttrs.meta.mainProgram;
    gssSupport = true;
    ffmpegSupport = true;
  };
})
