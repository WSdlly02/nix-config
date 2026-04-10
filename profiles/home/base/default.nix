{ pkgs, ... }:
{
  imports = [
    ./direnv.nix
    ./sh.nix
  ];

  config = {
    programs = {
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
        "$HOME/.local/bin"
      ];
      sessionVariables = {
        MY_CODES_PATH = "$HOME/Documents/my-codes";
        NIX_CONFIG_PATH = "$HOME/Documents/nix-config";
      };
    };
  };
}
