{
  config,
  lib,
  enableInfrastructure,
  ...
}:
{
  config = lib.mkIf enableInfrastructure {
    services.mihomo = {
      enable = true;
      tunMode = true;
      configFile = "/home/${config.hostSystemSpecific.defaultUser.name}/.config/mihomo/config.yaml";
    };
  };
}
