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
  fetchurl,
  version,
  url,
  hash,
  ...
}:
let
  policies = {
    DisableAppUpdate = true;
  } // config.zen.policies or { };

  policiesJson = writeText "firefox-policies.json" (builtins.toJSON { inherit policies; });
in
stdenv.mkDerivation (finalAttrs: {
  inherit version;
  pname = "zen-browser-unwrapped";
  applicationName = "Zen Browser";

  src = fetchurl {
    inherit url hash;
  };

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
