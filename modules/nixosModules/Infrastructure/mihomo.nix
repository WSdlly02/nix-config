{
  config,
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
let
  user = config.hostSystemSpecific.defaultUser.name;
in
lib.mkIf enableInfrastructure {
  virtualisation.quadlet.containers.mihomo = {
    containerConfig = {
      image = "docker.io/metacubex/mihomo:latest";
      networks = [ "host" ];
      volumes = [ "/home/${user}/.config/mihomo:/etc/mihomo" ];
      addCapabilities = [ "NET_ADMIN" ];
      devices = [ "/dev/net/tun" ];
      exec = [
        "-d"
        "/etc/mihomo"
      ];
      autoUpdate = "registry";
    };

    serviceConfig = {
      Delegate = true;
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p /home/${user}/.config/mihomo"
        (pkgs.writeShellScript "wait-for-tailscale-up" ''
          if ${pkgs.iproute2}/bin/ip link show tailscale0 >/dev/null 2>&1; then
            echo "tailscale0 exists, waiting for IP 100.64.16.64..."
            until ${pkgs.iproute2}/bin/ip addr show tailscale0 | ${pkgs.gnugrep}/bin/grep -q "100.64.16.64"; do
              ${pkgs.coreutils}/bin/sleep 1
            done
            echo "IP 100.64.16.64 is ready."
          else
            echo "tailscale0 does not exist, skipping wait."
          fi
        '')
      ];
      Restart = "always";
    };

    unitConfig = {
      Description = "Mihomo in Podman container";
      After = [
        "network-online.target"
        "tailscale.service"
      ];
      Wants = [ "network-online.target" ];
    };
  };
}
