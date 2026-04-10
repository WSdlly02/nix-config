{
  pkgs,
  ...
}:
{
  imports = [
    ../../profiles/home/base
    ../../profiles/home/base/user-wsdlly02.nix
    ./home-modules/network-autoswitch.nix
    ./home-modules/sh.nix
  ];

  home = {
    packages = with pkgs; [ mcrcon ];
    stateVersion = "25.05";
  };

  programs.java = {
    enable = true;
    package = pkgs.zulu25;
  };

  services.syncthing.guiAddress = "0.0.0.0:8384";
}
