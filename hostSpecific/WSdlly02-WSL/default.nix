{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ../../profiles/nixos/base/user-wsdlly02.nix
    ../../profiles/nixos/development
    ./Daily
    ./System
  ];

  nix.settings.max-jobs = 64;

  hostSystemSpecific = {
    environment.extraSystemPackages = with pkgs; [ wsl-open ];
  };
}
