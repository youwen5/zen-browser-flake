{
  wrapFirefox,
  zen-browser-unwrapped,
  ...
}:
let
  # wrapFirefox selects the FFmpeg ABI from browser.version. Zen's package
  # version is independent from the underlying Firefox version, so present the
  # Firefox base version to the wrapper while retaining Zen's version on the
  # resulting package.
  browserForWrapper = zen-browser-unwrapped // {
    version = zen-browser-unwrapped.firefoxVersion;
  };
in
wrapFirefox browserForWrapper {
  pname = "zen-browser";
  version = zen-browser-unwrapped.version;
}
