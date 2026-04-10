{
  services.avahi = {
    enable = true;
    allowInterfaces = [
      "enp14s0"
      "wlp15s0"
    ];
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
    # nssmdns6 = true;
    nssmdns4 = true;
    ipv6 = true;
    ipv4 = true;
    extraConfig = ''
      [server]
      disallow-other-stacks=yes
    '';
  };
}
