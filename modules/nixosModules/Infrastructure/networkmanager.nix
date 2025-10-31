{
  config,
  lib,
  pkgs,
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
    plugins = with pkgs; [ networkmanager-openvpn ];
    unmanaged = [
      "interface-name:bridge-*"
      "interface-name:tun-*"
    ];
    # rc-manager has been set as unmanaged
  };
}
