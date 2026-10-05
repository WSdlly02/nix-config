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
      includeUserConf = false;
      subpixel.rgba = "rgb";
      defaultFonts = {
        serif = [ "Sarasa UI SC" ];
        sansSerif = [ "Sarasa UI SC" ];
        monospace = [ "Sarasa Mono SC" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
  nixpkgs.overlays = [
    (final: prev: {
      # Keep following nixpkgs' default font package set, but avoid the
      # variable CJK TTCs that Chromium currently maps to the wrong weight.
      noto-fonts-cjk-sans = prev.noto-fonts-cjk-sans-static;
      noto-fonts-cjk-serif = prev.noto-fonts-cjk-serif-static;
    })
  ];

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

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    anki
    bilibili
    crosspipe
    ddcutil
    fsearch
    gapless
    google-chrome
    microsoft-edge
    mpv
    obsidian
    pass-wayland
    qbittorrent-enhanced
    qq
    qtscrcpy
    scrcpy
    sourcegit
    vlc
    vscode
    wechat
    wl-clipboard-rs
    wpsoffice-cn
    zed-editor
  ];
}
