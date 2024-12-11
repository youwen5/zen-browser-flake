# taken from <https://github.com/mightyiam/catppuccin-nix/blob/6a3ae62fb3fb596223bb5ddc6b3dc1b11266155a/modules/lib/from-ini.nix>

lib: ini:
let
  lines = lib.strings.splitString "\n" ini;
  parsedLines = map parseLine lines;

  parseLine =
    line:
    if builtins.stringLength line == 0 then
      { type = "empty"; }
    else if lib.hasPrefix "#" line then
      { type = "comment"; }
    else if lib.hasPrefix "[" line then
      {
        type = "section";
        name = lib.pipe line [
          (lib.removePrefix "[")
          (lib.removeSuffix "]")
        ];
      }
    else
      let
        parts = lib.splitString "=" line;
        key = lib.removeSuffix " " (lib.elemAt parts 0);
        litVal = lib.removePrefix " " (lib.elemAt parts 1);
      in
      {
        type = "property";
        inherit key;
        val = lib.pipe litVal [
          (lib.removePrefix "'")
          (lib.removeSuffix "'")
        ];
      };

  endState = lib.foldl foldState {
    val = { };
    currentSection = null;
  } parsedLines;

  foldState =
    acc: line:
    if line.type == "empty" then
      acc
    else if line.type == "comment" then
      acc
    else if line.type == "section" then
      acc
      // {
        ${line.name} = { };
        currentSection = line.name;
      }
    else if line.type == "property" then
      lib.updateManyAttrsByPath [
        {
          path = lib.flatten [
            "val"
            (lib.optional (builtins.isString acc.currentSection) acc.currentSection)
            line.key
          ];
          update = _: line.val;
        }
      ] acc
    else
      throw "no such type ${line.type}";
in
endState.val
