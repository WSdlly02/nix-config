{
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
let
  pinentryAuto = pkgs.writeShellScriptBin "pinentry" ''
    # SSH 一律 TUI
    if [ -n "''${SSH_TTY-}" ] || [ -n "''${SSH_CONNECTION-}" ]; then
      exec ${pkgs.pinentry-curses}/bin/pinentry-curses "$@"
    fi

    # 本机图形会话: Wayland / X11 任一存在就走 Qt
    if [ -n "''${WAYLAND_DISPLAY-}" ] || [ -n "''${DISPLAY-}" ]; then
      exec ${pkgs.pinentry-qt}/bin/pinentry-qt "$@"
    fi

    # 兜底: 纯 TTY
    exec ${pkgs.pinentry-curses}/bin/pinentry-curses "$@"
  '';
in
lib.mkIf enableInfrastructure {
  programs.gnupg = {
    agent = {
      enable = true;
      enableSSHSupport = true;
      enableBrowserSocket = true;
      enableExtraSocket = true;
      pinentryPackage = pinentryAuto;
    };
  };
}
