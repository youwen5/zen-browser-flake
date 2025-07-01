{ wrapFirefox, zen-browser-unwrapped, pname ? "zen-browser", ... }:
wrapFirefox zen-browser-unwrapped { inherit pname; }
