{
  services.openssh = {
    enable = true;
    ports = [ 10022 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      GatewayPorts = "yes";
      PrintMotd = true;
    };
  };
}
