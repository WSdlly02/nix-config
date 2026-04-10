{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ../../profiles/nixos/base/user-wsdlly02.nix
    ../../profiles/nixos/development
    ./system.nix
  ];

  nix.settings.max-jobs = 64;
  environment.systemPackages = with pkgs; [
    fastfetch
    ncdu
    wsl-open
  ];
}
