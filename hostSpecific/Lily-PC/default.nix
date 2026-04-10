{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ../../profiles/nixos/base/smartd.nix
    ./Daily
    ./Gaming
    ../../profiles/nixos/infrastructure
    ./System
  ];

  nix.settings.max-jobs = 32;

  hostSystemSpecific = {
    environment.extraSystemPackages = with pkgs; [
      ntfs3g
    ];
    defaultUser = {
      name = "lily";
      linger = true;
      extraGroups = [ ];
    };
  };
}
