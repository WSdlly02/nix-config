{ lib, pkgs, ... }:
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
    command-not-found = {
      enable = true;
      dbPath = "${pkgs.path}/programs.sqlite";
    };
    home-manager.enable = true;
    lazygit.enable = true;
    nh = {
      enable = true;
      flake = "$HOME/Documents/nix-config";
    };
  };

  home = {
    username = "wsdlly02";
    homeDirectory = "/home/wsdlly02";
    packages = with pkgs; [
      fastfetch
      # currentNixConfig !!!
      nixd
      nixfmt
      nix-diff
      nix-output-monitor
      nix-tree
      yazi
    ];
    sessionPath = [
      "$HOME/.cargo/bin"
      "$HOME/.npm-global/bin"
      "$HOME/go/bin"
      "$HOME/.local/bin"
    ];
    sessionVariables = {
      MY_CODES_PATH = "$HOME/Documents/my-codes";
      NODE_PATH = "$HOME/.npm-global/lib/node_modules";
      NIX_CONFIG_PATH = "$HOME/Documents/nix-config";
    };
  };
}
