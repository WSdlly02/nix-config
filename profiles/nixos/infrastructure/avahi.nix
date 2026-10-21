{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    # nssmdns6 = false;
    settings = {
      server = {
        allow-interfaces = [
          "enp14s0"
          "wlp15s0"
        ];
        disallow-other-stacks = true;
      };
      publish = {
        disable-publishing = false;
        disable-user-service-publishing = false;
        publish-addresses = true;
        publish-workstation = true;
      };
    };
  };
}
