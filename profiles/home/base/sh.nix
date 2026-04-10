{
  programs = {
    bash = {
      enable = true;
      initExtra = ''
        export GPG_TTY=$(tty)
      '';
    };
    fish = {
      enable = true;
      interactiveShellInit = ''
        fastfetch
      '';
      shellInit = ''
        export GPG_TTY=$(tty)
      '';
    };
  };
}
