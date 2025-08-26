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
    services.pipewire.socketActivation = false;
  };
}
