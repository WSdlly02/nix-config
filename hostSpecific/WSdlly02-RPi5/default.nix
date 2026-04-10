{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ./Daily
    ./Gaming
    ../../profiles/nixos/infrastructure
    ../../profiles/nixos/infrastructure/bluetooth.nix
    ./System
  ];

  nix.settings.max-jobs = 32;

  hostSystemSpecific = {
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
  };
}
