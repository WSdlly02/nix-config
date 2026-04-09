{
  pkgs,
  ...
}:
{
  imports = [
    ./sh.nix
  ];
  home = {
    username = "wsdlly02";
    homeDirectory = "/home/wsdlly02";
    packages = with pkgs; [
      codex
      gemini-cli
      ncmdump
    ];
    stateVersion = "25.05";
  };
}
