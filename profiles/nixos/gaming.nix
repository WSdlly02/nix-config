{ pkgs, ... }:
{
  programs = {
    steam = {
      enable = true;
      localNetworkGameTransfers.openFirewall = true;
      protontricks.enable = true;
    };
    gamemode.enable = true;
    java = {
      enable = true;
      package = pkgs.zulu27;
    };
  };

  environment.systemPackages = with pkgs; [
    mindustry-wayland
    (prismlauncher.override {
      jdks = [
        zulu27
      ];
      textToSpeechSupport = false;
    })
    heroic
    mangohud
    mangojuice
    mcrcon
    protonplus
  ];
}
