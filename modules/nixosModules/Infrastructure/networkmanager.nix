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
      "interface-name:mihomo-tun"
      "interface-name:tailscale0"
    ];
    # rc-manager has been set as unmanaged
  };
}
