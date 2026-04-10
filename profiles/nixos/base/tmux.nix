{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    historyLimit = 4000;
    clock24 = true;
    extraConfig = ''
      set-option -g mouse on
      set -g status-right '#{cpu_bg_color} CPU: #{cpu_icon} #{cpu_percentage} | %a %h-%d %H:%M '
    '';
    plugins = with pkgs.tmuxPlugins; [
      cpu
      net-speed
    ];
  };
}
