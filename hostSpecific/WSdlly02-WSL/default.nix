{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ../../profiles/nixos/development
    ./Daily
    ./System
  ];
  hostSystemSpecific = {
    environment.extraSystemPackages = with pkgs; [ wsl-open ];
    defaultUser = {
      name = "wsdlly02";
      linger = false;
      extraGroups = [ ];
    };
    nix.settings.max-jobs = 64;
  };
}
