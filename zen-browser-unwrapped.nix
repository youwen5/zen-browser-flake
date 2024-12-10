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
  sources,
  variant ? "specific",
  ...
}:
let
  src =
    if stdenv.targetPlatform.isAarch then
      sources.zen-browser-aarch64
    else if variant == "generic" then
      sources.zen-browser-generic
    else
      sources.zen-browser-specific;

  # super duper ultra jank technology
  version = builtins.elemAt (builtins.match ".*/download/([^/]+)/.*" ((import ./flake.nix).inputs.zen-browser-specific.url)) 0;

  policies = {
    DisableAppUpdate = true;
  } // config.zen.policies or { };

  policiesJson = writeText "firefox-policies.json" (builtins.toJSON { inherit policies; });
in
stdenv.mkDerivation (finalAttrs: {
  inherit version src;
  pname = "zen-browser-unwrapped";

  # src = builtins.fetchTarball {
  #   url = downloadData.url;
  #   sha256 = downloadData.sha256;
  # };

  # src = {
  #   url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-aarch64.tar.bz2";
  #   sha256 = "sha256:067m7g48nfa366ajn3flphnwkx8msc034r6px8ml66mbj7awjw4x";
  # };

  # src =
  #   if stdenv.targetPlatform.isAarch then
  #
  #   else if variant == "generic" then
  #     {
  #       url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-generic.tar.bz2";
  #       sha256 = "sha256:02x4w2fq80s1za05s0gg9r2drr845bln80h5hbwhvp1gxq9jf0g2";
  #     }
  #   else
  #     {
  #       url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-specific.tar.bz2";
  #       sha256 = "sha256:067m7g48nfa366ajn3flphnwkx8msc034r6px8ml66mbj7awjw4x";
  #     };

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
