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

  environment.systemPackages =
    let
      enableWayland = {
        commandLineArgs = "--ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer --enable-wayland-ime=true";
      };
    in
    with pkgs;
    [
      (google-chrome.override enableWayland)
      (microsoft-edge.override enableWayland)
      (obsidian.override enableWayland)
      (qq.override enableWayland)
      (vscode.override enableWayland)
      crosspipe
      ddcutil
      fsearch
      gapless
      mpv
      pass-wayland
      qbittorrent-enhanced
      qtscrcpy
      scrcpy
      sourcegit
      vlc
      wechat
      wl-clipboard-rs
      wpsoffice-cn
      zed-editor
    ];
}
