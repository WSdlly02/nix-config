{
  config,
  lib,
  enableInfrastructure,
  ...
}:
{
  config = lib.mkIf enableInfrastructure {
    networking = {
      hostName = config.system.name;
      nftables.enable = lib.mkDefault false;
      tempAddresses = "disabled";
      firewall = rec {
        enable = config.hostSystemSpecific.networking.firewall.enable;
        allowedTCPPorts = [
          7890 # Mihomo
          12024 # Mincraft Server
          21027 # Syncthing
          22000 # Syncthing
        ] ++ config.hostSystemSpecific.networking.firewall.extraAllowedPorts;
        allowedTCPPortRanges = [ ] ++ config.hostSystemSpecific.networking.firewall.extraAllowedPortRanges;
        allowedUDPPorts = allowedTCPPorts;
        allowedUDPPortRanges = allowedTCPPortRanges;
      };
      timeServers = [
        "ntp.ntsc.ac.cn"
        "cn.ntp.org.cn"
      ];
      /*
        proxy = {
          default = "http://127.0.0.1:7890/";
          noProxy = "127.0.0.1,localhost,internal.domain";
        };
      */
    };
    services = {
      timesyncd.servers = config.networking.timeServers;
      resolved = {
        enable = true; # which will disable resolvconf
        domains = [ "~." ];
        fallbackDns = [
          "223.5.5.5"
          "119.29.29.29"
          "1.1.1.1"
          "9.9.9.9"
        ];
        extraConfig = ''
          Cache=yes
          CacheFromLocalhost=no
          ReadEtcHosts=yes
          MulticastDNS=false
        '';
      };
    };
  };
}
