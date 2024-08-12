{ lib ? (import <nixpkgs> {}).lib
, asJSON ? false
}:

let
  baseDir = ./..;

  ensureUuid = str:
    if (builtins.match "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$" str) == null then
      throw "String is not a valid UUID: ${str}"
    else
      str;

  combined = {
    supervisors =
      lib.mapAttrs' (fileName: fileType:
        if fileType != "regular" then
          throw "Supervisor definition ${fileName} is not a regular file"
        else
          lib.nameValuePair
            (ensureUuid (lib.removeSuffix ".nix" fileName))
            (import "${baseDir}/supervisors/${fileName}")
      ) (
        builtins.readDir "${baseDir}/supervisors/"
      );

    sites =
      lib.mapAttrs' (fileName: fileType:
        if fileType != "regular" then
          throw "Site definition ${fileName} is not a regular file"
        else
          lib.nameValuePair
            (lib.removeSuffix ".nix" fileName)
            (import "${baseDir}/sites/${fileName}")
      ) (
        builtins.readDir "${baseDir}/sites/"
      );
  };

in
  if asJSON then
    builtins.toJSON combined
  else
    combined
