{
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
lib.mkIf enableInfrastructure {
  networking.firewall = {
    trustedInterfaces = [ "tun-tailscale" ];
    allowedUDPPorts = [ 41641 ];
    checkReversePath = "loose";
  };

  virtualisation.quadlet.containers.tailscale = {
    containerConfig = {
      image = "docker.io/tailscale/tailscale:latest";
      networks = [ "host" ];
      volumes = [ "/var/lib/tailscale:/var/lib/tailscale" ];
      devices = [
        "/dev/net/tun:/dev/net/tun"
      ];
      addCapabilities = [
        "NET_ADMIN"
        "NET_RAW"
      ];
      environments = {
        DNS_SERVER = "223.5.5.5";
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_USERSPACE = "false";
        TS_EXTRA_ARGS = "--ssh --advertise-exit-node --accept-routes --accept-dns";
        TS_TAILSCALED_EXTRA_ARGS = "--tun=tailscale0";
      };
      user = "0";
      autoUpdate = "registry";
    };
    serviceConfig = {
      Delegate = true;
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/lib/tailscale";
      Restart = "always";
    };
    unitConfig = {
      Description = "Tailscale node in Podman container";
      After = [ "network-online.target" ];
      Before = [ "mihomo.service" ];
      Wants = [ "network-online.target" ];
    };
  };
}
