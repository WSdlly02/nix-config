{ lib, enableInfrastructure, ... }:
{
  config = lib.mkIf enableInfrastructure {
    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        userServices = true;
      };
      nssmdns6 = true;
      nssmdns4 = true;
      ipv6 = true;
      ipv4 = true;
      wideArea = false;
      extraConfig = ''
        [server]
        disallow-other-stacks=yes

        [publish]
        publish-aaaa-on-ipv4=yes
        publish-a-on-ipv6=yes
      '';
    };
  };
}
