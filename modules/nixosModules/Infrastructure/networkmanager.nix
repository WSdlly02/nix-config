{
  config,
  lib,
  enableInfrastructure,
  ...
}:
lib.mkIf enableInfrastructure {
  networking.networkmanager = {
    enable = true;
    dns = "none";
    ethernet.macAddress = "stable";
    wifi = {
      macAddress = "stable-ssid";
      scanRandMacAddress = false;
      powersave = lib.mkIf (config.system.name != "WSdlly02-PC") false;
    };
    unmanaged = [
      "interface-name:tun-*"
    ];
    connectionConfig = {
      "ethernet.wake-on-lan" = "magic";
    };
    # rc-manager has been set as unmanaged
  };
}
