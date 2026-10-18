{
  lib,
  pkgs,
  ...
}:
{
  virtualisation.quadlet = {
    enable = true;
    autoUpdate.enable = true;
    autoEscape = true;
    containers = {
      mihomo-updater-resolver = {
        containerConfig = {
          image = "ghcr.io/wsdlly02/my-codes/mihomo-updater-resolver:latest";
          publishPorts = [
            "127.0.0.1:8087:8088"
          ];
          volumes = [
            "%h/.config/mihomo/config.yaml:/app/config.yaml:ro"
            "%h/Documents/my-codes/SOPs/mihomo-updater/ACL4SSR_Online_Full.ini:/app/ACL4SSR_Online_Full.ini:ro"
            "%h/Documents/my-codes/SOPs/mihomo-updater/cache:/app/cache" # directory
            "%h/Documents/my-codes/SOPs/mihomo-updater/vps-configs:/app/vps-configs" # directory
          ];
          autoUpdate = "registry";
          environmentFiles = [
            "%h/Documents/my-codes/SOPs/mihomo-updater/.env"
          ];
        };
        serviceConfig = {
          Delegate = true;
          Restart = "on-failure";
        };
        unitConfig = {
          Description = "Mihomo Updater in Podman container";
          StopWhenUnneeded = true;
        };
      };
    };
  };
  systemd.user.sockets.mihomo-updater-resolver-proxy = {
    Unit.Description = "Socket for Mihomo Updater Proxy";
    Socket = {
      ListenStream = "[::]:8088";
      IPAddressAllow = [
        "127.0.0.1"
        "::1"
        "192.168.0.0/16"
        "fd00::/8"
        "fe80::/10"
        "10.144.144.0/24"
        "100.64.16.0/24"
        "fd7a:115c:a1e0::/48"
      ];
      IPAddressDeny = "any";
    };
    Install.WantedBy = [ "sockets.target" ];
  };
  systemd.user.services.mihomo-updater-resolver-proxy = {
    Unit = {
      Description = "Proxy for Mihomo Updater with Idle Timeout";
      Requires = [
        "mihomo-updater-resolver-proxy.socket"
        "mihomo-updater-resolver.service"
      ];
      After = [
        "mihomo-updater-resolver-proxy.socket"
        "mihomo-updater-resolver.service"
      ];
    };
    Service = {
      TimeoutStartSec = 300;
      ExecStartPre = pkgs.utils-self.systemd-user-waitHTTP {
        name = "mihomo-resolver";
        url = "http://127.0.0.1:8087/health";
      };
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=600 127.0.0.1:8087";
    };
  };
  systemd.user.services.mihomo-updater-resolver.Install.WantedBy = lib.mkForce [ ];
}
