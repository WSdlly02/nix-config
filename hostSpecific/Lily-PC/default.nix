{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ../../profiles/nixos/base/user-lily.nix
    ../../profiles/nixos/base/smartd.nix
    ./Daily
    ./Gaming
    ../../profiles/nixos/infrastructure
    ./System
  ];

  nix.settings.max-jobs = 32;
  environment.systemPackages = with pkgs; [
    ntfs3g
  ];
}
