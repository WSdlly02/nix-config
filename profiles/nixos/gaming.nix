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
      package = pkgs.zulu25;
    };
  };

  environment.systemPackages = with pkgs; [
    mindustry-wayland
    (prismlauncher.override {
      jdks = [
        zulu25
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
