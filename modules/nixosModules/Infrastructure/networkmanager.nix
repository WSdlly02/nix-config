{
  config,
  lib,
  enableInfrastructure,
  ...
}:
{
  config = lib.mkIf enableInfrastructure {
    networking.networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      ethernet.macAddress = "stable";
      wifi = {
        macAddress = "stable-ssid";
        scanRandMacAddress = false;
        powersave = lib.mkIf (config.system.name != "WSdlly02-PC") false;
      };
      # rc-manager has been set as unmanaged
    };
  };
}
