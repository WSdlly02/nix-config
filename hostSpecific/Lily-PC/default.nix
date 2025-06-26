{ pkgs, ... }:
{
  imports = [
    ./Daily
    ./Gaming
    ./System
  ];
  hostSystemSpecific = {
    enableBluetooth = false;
    enableDevelopment = false;
    enableInfrastructure = true;
    enableSmartd = true;
    environment.extraSystemPackages = with pkgs; [
      ntfs3g
    ];
    defaultUser = {
      name = "lily";
      linger = true;
      extraGroups = [ ];
    };
    nix.settings.max-jobs = 32;
    programs = {
      proxychains.proxies.host = "192.168.71.64";
    };
    services.pipewire.socketActivation = false;
  };
}
