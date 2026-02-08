{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hostUserSpecific;
in
{
  imports = [
    ./direnv.nix
    ./sh.nix
  ];
  options.hostUserSpecific = {
    username = lib.mkOption {
      default = "wsdlly02";
      type = lib.types.str;
      description = "user managed by home-manager";
    };
    extraPackages = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.package;
      description = ''
        The set of packages that appear in home
      '';
    };
  };
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
      username = cfg.username;
      homeDirectory = "/home/${cfg.username}";
      packages =
        with pkgs;
        [
          fastfetch
          currentNixConfig
          nixd
          nixfmt
          nix-diff
          nix-output-monitor
          nix-tree
          yazi
        ]
        ++ cfg.extraPackages;
      sessionPath = [ "$HOME/.local/bin" ];
      sessionVariables = {
        MY_CODES_PATH = "$HOME/Documents/my-codes";
        NIX_CONFIG_PATH = "$HOME/Documents/nix-config";
      };
    };
  };
}
