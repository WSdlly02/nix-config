{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    openFirewall = true;
    interfaceName = "tun-tailscale";
    authKeyFile = "/var/lib/tailscale/authkey";
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
      "--accept-routes"
      "--accept-dns"
    ];
  };
  systemd.services = rec {
    tailscaled = {
      environment.DNS_SERVER = "223.5.5.5";
      before = [ "mihomo.service" ];
    };
    tailscaled-autoconnect = tailscaled;
  };
}
