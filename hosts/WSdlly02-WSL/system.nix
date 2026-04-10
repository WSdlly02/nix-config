{ config, ... }:
{
  imports = [
    ./system-modules/networking.nix
    ./system-modules/nixpkgs-x86_64.nix
  ];

  wsl = {
    enable = true;
    defaultUser = config.my.mainUser.name;
    startMenuLaunchers = true;
    interop.register = true;
    useWindowsDriver = true;
  };

  environment.etc."resolv.conf".source = ./.;
}
