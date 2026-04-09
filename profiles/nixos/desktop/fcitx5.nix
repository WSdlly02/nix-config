{ pkgs, ... }:
{
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
}
