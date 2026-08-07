{
  networking.networkmanager = {
    enable = true;
    dns = "none";
    ethernet.macAddress = "permanent"; # Wake-on-LAN requires a stable MAC address for the ethernet interface
    wifi = {
      macAddress = "stable-ssid";
      scanRandMacAddress = false;
      powersave = false;
    };
    unmanaged = [
      "except:interface-name:enp14s0"
      "except:interface-name:wlp15s0"
    ];
    # rc-manager has been set as unmanaged
  };
}
