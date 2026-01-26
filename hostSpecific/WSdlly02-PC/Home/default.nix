{
  pkgs,
  ...
}:
{
  imports = [
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
    extraPackages = with pkgs; [
      # audio-relay
      codex
      # discord
      gemini-cli
      mihomo-updater-updater
      # ncmdump
      # ocs-desktop
      # qoder
      telegram-desktop
    ];
  };
  programs = {
    zen-browser = {
      enable = true;
      nativeMessagingHosts = [ pkgs.firefoxpwa ];
      policies = {
        DisableAppUpdate = true;
        DisableTelemetry = true;
        # find more options here: https://mozilla.github.io/policy-templates/
      };
    };
  };
  home.stateVersion = "24.11";
  services.mpris-proxy.enable = true;
}
