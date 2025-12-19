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
  systemd.services.mihomo = {
    serviceConfig = {
      # 给这个服务发出的所有数据包打上标记 10053 (随便选个没用的数)
      FirewallMark = 10053;
    };
  };
}
