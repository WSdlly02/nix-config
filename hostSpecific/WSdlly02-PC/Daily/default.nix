{
  pkgs,
  ...
}:
let
  enableWayland = {
    commandLineArgs = "--ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer --enable-wayland-ime=true";
  };
in
{
  imports = [
    ./fcitx5.nix
    ./lact.nix
    # ./paperless.nix
    ./plasma6.nix
    ./sunshine.nix
    ##./wine.nix
  ];
  # Fonts
  fonts = {
    packages = with pkgs; [
      sarasa-gothic
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
  # Programs
  programs = {
    # appimage.enable = true;
    kdeconnect.enable = true;
    noisetorch.enable = true;
    obs-studio = {
      enable = true;
      enableVirtualCamera = true;
      plugins = with pkgs.obs-studio-plugins; [
        #droidcam-obs
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
        # find more options here: https://mozilla.github.io/policy-templates/
      };
    };
  };
  services.power-profiles-daemon.enable = true;
  # services.flatpak.enable = true;
  environment = {
    systemPackages =
      with pkgs;
      [
        (bilibili.override enableWayland)
        (google-chrome.override enableWayland)
        (microsoft-edge.override enableWayland)
        (obsidian.override enableWayland)
        (qq.override enableWayland)
        (vscode.override enableWayland)
        ddcutil # Required to control the brightness
        fastfetch
        fsearch
        gapless
        helvum
        mihomo-party
        mpv
        ncdu
        pass-wayland
        qbittorrent-enhanced
        qcm
        scrcpy
        sourcegit
        vlc
        wechat-uos
        wemeet
        wpsoffice-cn
      ]
      ++ [
        kdePackages.sddm-kcm
        kdePackages.wallpaper-engine-plugin
        kdePackages.yakuake
        sddm-astronaut
      ];
  };
}
