{ pkgs, ... }:
{
  imports = [
    ./epson-maintenance.nix
    # ./eye-care-reminder.nix
    ./localllm.nix
    ./mihomo-updater.nix
    ./ollama-omni-ocr.nix
    # ./roc-sink.nix
    ./sh.nix
    ./syncthing.nix
  ];

  hostUserSpecific = {
    username = "wsdlly02";
    extraSessionPath = [
      "$HOME/.cargo/bin"
      "$HOME/.npm-global/bin"
      "$HOME/go/bin"
    ];
    extraPackages = with pkgs; [
      ffmpeg
      mihomo-updater-updater
      telegram-desktop
    ];
  };

  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [ pkgs.firefoxpwa ];
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
    };
  };

  home = {
    sessionVariables = {
      NODE_PATH = "$HOME/.npm-global/lib/node_modules";
    };
    stateVersion = "24.11";
  };

  services.mpris-proxy.enable = true;
}
