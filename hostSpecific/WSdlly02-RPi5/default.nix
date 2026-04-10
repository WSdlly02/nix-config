{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ../../profiles/nixos/base/user-wsdlly02.nix
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
  };

  users.users.wsdlly02.extraGroups = [
    "i2c"
    "video"
  ];

  my.networking.firewall = {
    extraAllowedPorts = [
      8080
    ];
    extraAllowedPortRanges = [ ];
    lanOnlyPorts = [ 5353 ];
    lanOnlyPortRanges = [ ];
  };
}
