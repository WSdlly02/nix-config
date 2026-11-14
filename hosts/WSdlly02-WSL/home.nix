{
  pkgs,
  ...
}:
{
  imports = [
    ../../profiles/home/base.nix
    ./home-modules/sh.nix
  ];

  home = {
    packages = with pkgs; [ ];
    stateVersion = "25.05";
  };
}
