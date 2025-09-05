{
  config,
  lib,
  enableInfrastructure,
  ...
}:
let
  systemTags = lib.concatMapStringsSep " " (x: x) config.system.nixos.tags;
in
lib.mkIf enableInfrastructure {
  services.getty = {
    greetingLine = ''
      ${config.system.name} (\m)
      ${config.system.nixos.distroName} ${systemTags} \r
      Date: \d \t
      Terminal: \l
    '';
    helpLine = lib.mkForce "";
  };
}
