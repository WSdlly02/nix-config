{ pkgs, ... }:
{
  imports = [
    ./fcitx5.nix
    ./lact.nix
    # ./paperless.nix
    ./plasma6.nix
    ./sunshine.nix
    # ./wine.nix
  ];

  fonts = {
    packages = with pkgs; [
      sarasa-gothic
      maple-mono.NF-CN-unhinted
    ];
    fontDir.enable = true;
    fontconfig = {
      allowBitmaps = false;
      useEmbeddedBitmaps = true; # Display emoji required
      subpixel.rgba = "rgb";
      defaultFonts = {
        serif = [ "Sarasa UI SC" ];
        sansSerif = [ "Sarasa UI SC" ];
        monospace = [ "Sarasa Mono SC" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  programs = {
    kdeconnect.enable = true;
    localsend = {
      enable = true;
      openFirewall = true;
    };
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-vkcapture
        input-overlay
      ];
    };
    partition-manager.enable = true;
    thunderbird = {
      enable = true;
      policies = {
        DisableAppUpdate = true;
        DisableTelemetry = true;
      };
    };
  };

  services.power-profiles-daemon.enable = true;

  environment.systemPackages =
    let
      enableWayland = {
        commandLineArgs = "--ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer --enable-wayland-ime=true";
      };
    in
    with pkgs;
    [
      (antigravity.override enableWayland)
      (google-chrome.override enableWayland)
      (microsoft-edge.override enableWayland)
      (obsidian.override enableWayland)
      (qq.override enableWayland)
      (vscode.override enableWayland)
      crosspipe
      ddcutil
      fastfetch
      fsearch
      gapless
      mpv
      ncdu
      pass-wayland
      qbittorrent-enhanced
      qtscrcpy
      scrcpy
      sourcegit
      vlc
      wechat
      wl-clipboard-rs
      wpsoffice-cn
    ];
}
