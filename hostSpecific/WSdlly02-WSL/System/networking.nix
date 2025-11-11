{
  config,
  ...
}:
{
  networking = {
    hostName = config.system.name;
    firewall.enable = false;
    tempAddresses = "disabled";
  };
}
