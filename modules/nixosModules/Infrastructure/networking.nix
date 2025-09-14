{
  config,
  lib,
  enableInfrastructure,
  ...
}:
lib.mkIf enableInfrastructure {
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
      ++ config.hostSystemSpecific.networking.firewall.extraAllowedPorts;
      allowedTCPPortRanges = [ ] ++ config.hostSystemSpecific.networking.firewall.extraAllowedPortRanges;
      allowedUDPPorts = config.networking.firewall.allowedTCPPorts;
      allowedUDPPortRanges = config.networking.firewall.allowedTCPPortRanges;
    };
    nameservers = [ "127.0.0.1" ];
    timeServers = [
      "ntp.ntsc.ac.cn"
      "cn.ntp.org.cn"
    ];
  };
  services.timesyncd.servers = config.networking.timeServers;
}
