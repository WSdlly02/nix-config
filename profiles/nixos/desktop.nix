{ pkgs, ... }:
{
  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [ khelpcenter ];
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config.common.default = [ "kde" ];
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        kdePackages.fcitx5-chinese-addons
        fcitx5-pinyin-zhwiki
        fcitx5-pinyin-minecraft
        fcitx5-gtk
      ];
      settings.addons = {
        pinyin.globalSection.EmojiEnabled = "True";
      };
    };
  };

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

  programs = {
    kdeconnect.enable = true;
    localsend = {
      enable = true;
      openFirewall = true;
    };
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture # Capture audio from PipeWire
        obs-vkcapture # Capture Vulkan applications
        input-overlay # Display keystrokes and mouse clicks on screen
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

  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };

  services.power-profiles-daemon.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages =
    with pkgs;
    [
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
    ]
    ++ [
      kdePackages.sddm-kcm
      kdePackages.yakuake
    ];
}
