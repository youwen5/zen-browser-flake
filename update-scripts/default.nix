{
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  name = "update-scripts";

  phases = [
    "unpackPhase"
    "installPhase"
  ];

  src = ./.;

  installPhase = ''
    install -Dm755 ./commit-update.nu $out/bin/commit-update.nu
    install -Dm755 ./update.nu $out/bin/update.nu
  '';
}
