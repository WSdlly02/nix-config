{ pkgs, ... }:
{
  imports = [
    ./gamescope.nix
    ./openrazer.nix
    ./openrgb.nix
  ];
  programs = {
    gamemode.enable = true;
    java = {
      enable = true;
      package = pkgs.zulu21;
    };
  };
  environment.systemPackages = with pkgs; [
    (mindustry.override { jdk17 = zulu17; })
    (prismlauncher.override rec {
      jdk21 = zulu21; # Actually, it's useless, because Prismlauncher doesn't really need java.
      jdk17 = zulu17;
      jdks = [
        jdk21
        jdk17
      ]; # Add JAVA_PATH for Prismlauncher
      textToSpeechSupport = false;
    })
    heroic
    mangohud
    mangojuice
    mcrcon
    protonup-qt
    # vkbasalt
    # vkbasalt-cli
  ];
}
