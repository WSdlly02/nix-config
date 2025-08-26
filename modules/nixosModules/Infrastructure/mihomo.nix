{
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
{
  config = lib.mkIf enableInfrastructure {
    services.mihomo = {
      enable = true;
      tunMode = true;
      webui = pkgs.metacubexd;
    };
  };
}
