{
  pkgs,
  ...
}:
{
  imports = [
    ../../profiles/home/base
    ../../profiles/home/base/user-wsdlly02.nix
    ../../profiles/home/workstation
    ./home-modules/epson-maintenance.nix
    ./home-modules/localllm.nix
    ./home-modules/mihomo-updater.nix
    ./home-modules/ollama-omni-ocr.nix
    ./home-modules/sh.nix
  ];
  home = {
    packages = with pkgs; [
      ffmpeg
      mihomo-updater-updater
      telegram-desktop
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
}
