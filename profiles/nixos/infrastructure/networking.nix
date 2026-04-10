{
  config,
  lib,
  ...
}:
let
  cfg = config.networking.firewall;
  cfgHS = config.my.networking.firewall;
in
{
  networking = {
    hostName = config.system.name;
    resolvconf = {
      enable = true;
      useLocalResolver = true;
    };
    nftables.enable = lib.mkDefault false;
    tempAddresses = "disabled";
    firewall = {
      enable = lib.mkForce false;
      allowedTCPPorts = [
        12024 # Mincraft Server
        21027 # Syncthing
        22000 # Syncthing
      ]
      ++ cfgHS.extraAllowedPorts;
      allowedTCPPortRanges = cfgHS.extraAllowedPortRanges;
      allowedUDPPorts = cfg.allowedTCPPorts;
      allowedUDPPortRanges = cfg.allowedTCPPortRanges;
    };
    nameservers = [ "127.0.0.1" ];
    timeServers = [
      "ntp.ntsc.ac.cn"
      "cn.ntp.org.cn"
    ];
  };
  services.timesyncd.servers = config.networking.timeServers;
}
