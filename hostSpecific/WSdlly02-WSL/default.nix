{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ../../profiles/nixos/development
    ./Daily
    ./System
  ];

  nix.settings.max-jobs = 64;

  hostSystemSpecific = {
    environment.extraSystemPackages = with pkgs; [ wsl-open ];
    defaultUser = {
      name = "wsdlly02";
      linger = false;
      extraGroups = [ ];
    };
  };
}
