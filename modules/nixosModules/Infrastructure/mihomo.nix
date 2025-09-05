{
  config,
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
lib.mkIf enableInfrastructure {
  services.mihomo = {
    enable = true;
    tunMode = true;
    webui = pkgs.metacubexd;
    configFile = "/home/${config.hostSystemSpecific.defaultUser.name}/.config/mihomo/config.yaml";
  };
}
