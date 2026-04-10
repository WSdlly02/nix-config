{
  services.static-web-server = {
    enable = true;
    listen = "[::]:18787";
    root = "/home/wsdlly02/Documents/static-web-server/";
    configuration = {
      general = {
        directory-listing = true;
        threads-multiplier = 2;
        log-remote-address = true;
        log-level = "error";
      };
    };
  };
}
