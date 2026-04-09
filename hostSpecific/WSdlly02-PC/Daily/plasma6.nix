{ pkgs, ... }:
{
  services = {
    # displayManager.sddm = {
    #   enable = true;
    #   autoNumlock = true;
    #   wayland = {
    #     enable = true;
    #     compositor = "kwin";
    #   };
    #   settings.Theme = {
    #     Current = "breeze";
    #     CursorTheme = "breeze_cursors";
    #     Font = "Sarasa Gothic SC,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
    #   };
    # };
    displayManager.plasma-login-manager = {
      enable = true;
      # settings = { };
    };
    desktopManager.plasma6.enable = true;
  };
  environment.plasma6.excludePackages = with pkgs.kdePackages; [ khelpcenter ];
  environment.systemPackages = with pkgs.kdePackages; [
    sddm-kcm
    wallpaper-engine-plugin
    yakuake
  ];
  programs.kde-pim = {
    enable = true;
    merkuro = true;
  };
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config.common.default = [
      "kde"
    ];
  };
  # environment.systemPackages = [
  #   (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
  #     [General]
  #     background=${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/MilkyWay/contents/images/5120x2880.png
  #   '')
  # ];
}
