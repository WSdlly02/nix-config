{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ../../profiles/nixos/base/user-lily.nix
    ../../profiles/nixos/base/smartd.nix
    ../../profiles/nixos/infrastructure
    ./hardware.nix
    ./system.nix
  ];

  nix.settings.max-jobs = 32;
  environment.systemPackages = with pkgs; [
    fastfetch
    mcrcon
    ntfs3g
  ];

  users.users.lily.extraGroups = [ "adbusers" ];
}
