{ pkgs, ... }:
{
  imports = [
    ./Daily
    ./Gaming
    ./System
  ];
  hostSystemSpecific = {
    enableBluetooth = true;
    enableDevEnv = true;
    enableInfrastructure = true;
    environment.extraSystemPackages = with pkgs; [
      libraspberrypi
      i2c-tools
      raspberrypi-eeprom
    ];
    defaultUser = {
      name = "wsdlly02";
      linger = true;
      extraGroups = [
        "i2c"
        "video"
      ];
    };
    networking.firewall = {
      extraAllowedPorts = [
        8080
      ];
      extraAllowedPortRanges = [ ];
      lanOnlyPorts = [ 5353 ];
      lanOnlyPortRanges = [ ];
    };
    nix.settings.max-jobs = 32;
    programs = {
      ccache.extraPackageNames = [ "linux_rpi5" ];
    };
    services.pipewire.socketActivation = false;
  };
}
