{
  config,
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
{
  config = lib.mkIf enableInfrastructure {
    programs.proxychains = {
      enable = true;
      package = pkgs.proxychains-ng;
      quietMode = true;
      proxies."mihomo" = {
        enable = true;
        type = "http";
        host = config.hostSystemSpecific.programs.proxychains.proxies.host;
        port = 7890;
      };
    };
  };
}
