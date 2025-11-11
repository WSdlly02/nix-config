{
  pkgs,
  ...
}:
{
  imports = [
    ./sh.nix
  ];
  hostUserSpecific = {
    username = "wsdlly02";
    extraPackages = with pkgs; [
      ncmdump
    ];
  };
  home.stateVersion = "25.05";
}
