{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation.quadlet = {
    enable = true;
    autoUpdate.enable = true;
    autoEscape = true;
    pods.mihomo-updater-resolver-pod = {
      podConfig.publishPorts = [ "127.0.0.1:8087:8088" ];
      unitConfig = {
        Description = "Pod for Mihomo Updater and Subconverter";
        StopWhenUnneeded = true;
      };
    };
    containers = {
      mihomo-updater-resolver = {
        containerConfig = {
          image = "ghcr.io/wsdlly02/my-codes/mihomo-updater-resolver:latest";
          pod = config.virtualisation.quadlet.pods.mihomo-updater-resolver-pod.ref;
          volumes = [
            "%h/.config/mihomo/config.yaml:/app/config.yaml:ro"
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
      subconverter = {
        containerConfig = {
          image = "docker.io/tindy2013/subconverter:latest";
          pod = config.virtualisation.quadlet.pods.mihomo-updater-resolver-pod.ref;
          autoUpdate = "registry";
        };
        serviceConfig = {
          Delegate = true;
          Restart = "on-failure";
          ExecStartPre = pkgs.writeShellScript "wait-for-mihomo-up" ''
            until ${pkgs.iproute2}/bin/ip link show mihomo0; do
              ${pkgs.coreutils}/bin/sleep 1
            done
            echo "Mihomo is ready, network is accessible."
          '';
        };
        unitConfig = {
          Description = "Subconverter in Podman container";
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
      Requires = [ "mihomo-updater-resolver-proxy.socket" ];
      After = [ "mihomo-updater-resolver-proxy.socket" ];
    };
    Service = {
      Environment = [
        "SERVICES_START_ORDER=\"mihomo-updater-resolver-pod-pod.service subconverter.service mihomo-updater-resolver.service\""
        "SERVICES_STOP_ORDER=\"mihomo-updater-resolver.service subconverter.service mihomo-updater-resolver-pod-pod.service\""
      ];
      TimeoutStartSec = 300;
      ExecStartPre = pkgs.utils-self.systemd-user-serializedStarter "mihomo-updater-resolver-proxy";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=600 127.0.0.1:8087";
      ExecStopPost = pkgs.utils-self.systemd-user-serializedStopper "mihomo-updater-resolver-proxy";
    };
  };
  systemd.user.services = {
    mihomo-updater-resolver.Install.WantedBy = lib.mkForce [ ];
    subconverter.Install.WantedBy = lib.mkForce [ ];
    mihomo-updater-resolver-pod-pod.Install.WantedBy = lib.mkForce [ ];
  };
}
