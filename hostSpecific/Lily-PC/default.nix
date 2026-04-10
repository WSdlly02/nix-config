{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ./Daily
    ./Gaming
    ../../profiles/nixos/infrastructure
    ./System
  ];
  hostSystemSpecific = {
    enableBluetooth = false;
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
    services.pipewire.socketActivation = false;
  };
}
