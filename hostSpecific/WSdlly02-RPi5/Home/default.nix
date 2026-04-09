{
  pkgs,
  ...
}:
{
  imports = [
    ./network-autoswitch.nix
    # ./roc-source.nix
    ./sh.nix
    ./syncthing.nix
    ./tailscale.nix
  ];
  home = {
    username = "wsdlly02";
    homeDirectory = "/home/wsdlly02";
    packages = with pkgs; [ ];
    stateVersion = "25.05";
  };
  programs = {
    java = {
      enable = true;
      package = pkgs.zulu21;
    };
  };
  services.mpris-proxy.enable = true;
  targets.genericLinux.enable = true;
}
