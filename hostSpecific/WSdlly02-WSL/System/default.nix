{ config, ... }:
{
  imports = [
    #./i18n.nix
    #./neovim.nix
    ./networking.nix
    #./nix.nix
    ./nixpkgs-x86_64.nix
    #./sudo.nix
    #./tmux.nix
  ];
  wsl = {
    enable = true;
    defaultUser = config.hostSystemSpecific.defaultUser.name;
    startMenuLaunchers = true;
    interop.register = true;
    useWindowsDriver = true;
  };
  environment.etc."resolv.conf".source = ./.;
}
