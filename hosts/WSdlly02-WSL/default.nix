{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ../../profiles/nixos/development
    ./system.nix
  ];

  nix.settings.max-jobs = 64;
  environment.systemPackages = with pkgs; [
    wsl-open
  ];
}
