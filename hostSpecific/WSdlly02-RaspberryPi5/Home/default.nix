{
  pkgs,
  ...
}:
{
  imports = [
    # ./roc-source.nix
    ./sh.nix
    ./syncthing.nix
    ./zerotierone.nix
  ];
  hostUserSpecific = {
    username = "wsdlly02";
    extraPackages = with pkgs; [ zerotierone ];
  };
  programs = {
    java = {
      enable = true;
      package = pkgs.zulu21;
    };
  };
  services.mpris-proxy.enable = true;
  home.stateVersion = "25.05";
  targets.genericLinux.enable = true;
}
