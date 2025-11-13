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
      codex
      gemini-cli
      ncmdump
    ];
  };
  home.stateVersion = "25.05";
}
