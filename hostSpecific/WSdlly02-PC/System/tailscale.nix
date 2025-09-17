{
  services.tailscale = rec {
    enable = true;
    useRoutingFeatures = "both";
    openFirewall = true;
    interfaceName = "tailscale0";
    #authKeyFile = "";
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
      "--accept-routes"
      "--accept-dns"
    ];
    extraSetFlags = extraUpFlags;
  };
}
