{ pkgs, ... }:
{
  imports = [
    ./gamescope.nix
  ];
  programs = {
    gamemode.enable = true;
    java = {
      enable = true;
      package = pkgs.zulu25;
    };
  };
  environment.systemPackages = with pkgs; [
    (mindustry.override { jdk17 = zulu17; })
    (prismlauncher.override {
      jdks = [
        zulu25
        # zulu21
        # zulu17
      ]; # Add JAVA_PATH for Prismlauncher
      textToSpeechSupport = false;
    })
    heroic
    mangohud
    mangojuice
    mcrcon
    protonplus
    # vkbasalt
    # vkbasalt-cli
  ];
}
