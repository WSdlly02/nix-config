{
  pkgs,
  ...
}:
{
  imports = [
    ../../profiles/home/base
    ../../profiles/home/base/user-wsdlly02.nix
    ../../profiles/home/workstation
    ./home-modules/sh.nix
  ];

  home = {
    packages = with pkgs; [ ];
    stateVersion = "25.05";
  };
}
