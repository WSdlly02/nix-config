{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base.nix
    ../../profiles/nixos/development.nix
    ./system.nix
  ];

  nix.settings.max-jobs = 64;
  environment.systemPackages = with pkgs; [
    wsl-open
  ];
}
