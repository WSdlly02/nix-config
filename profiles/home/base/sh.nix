{ lib, ... }:
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
      shellAliases = {
        dl = lib.mkDefault "aria2c -x 16 -s 16 -k 1M -d ~/Downloads --allow-overwrite=true --file-allocation=none --continue=true";
      };
      shellInit = ''
        export GPG_TTY=$(tty)
      '';
    };
  };
}
