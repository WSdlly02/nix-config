{
  pkgs,
  ...
}:
{
  imports = [
    ../../profiles/home/base.nix
    ./home-modules/atrust.nix
    ./home-modules/epson-maintenance.nix
    ./home-modules/localllm.nix
    ./home-modules/mihomo-updater.nix
    ./home-modules/ollama-omni-ocr.nix
    ./home-modules/prismagentd.nix
    ./home-modules/sh.nix
  ];
  home = {
    packages = with pkgs; [
      # pkgs from my-codes.exposedPackages overlay
      # !! Already installed in $HOME/.local/bin
      # duplicate-file-finder
      # mihomo-updater

      ffmpeg
      telegram-desktop

      (texliveMedium.withPackages (
        f: with f; [
          ctex
          latexmk
          biblatex
          biber
        ]
      ))
      texlab

      yt-dlp
    ];
    stateVersion = "24.11";
  };
  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [ pkgs.firefoxpwa ];
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
    };
  };
  services.mpris-proxy.enable = true;

  services.syncthing = {
    enable = true;
    guiAddress = "127.0.0.1:8384";
    overrideDevices = false;
    overrideFolders = false;
  };
}
