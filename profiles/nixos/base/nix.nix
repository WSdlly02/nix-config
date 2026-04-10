{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  nix = {
    channel.enable = false;
    nixPath = [
      "home-manager=${inputs.home-manager}"
      "nixpkgs=${config.nixpkgs.flake.source}"
      "my-codes=/home/${config.my.mainUser.name}/Documents/my-codes"
      "nix-config=/home/${config.my.mainUser.name}/Documents/nix-config"
    ];
    registry = {
      "home-manager" = {
        from = {
          id = "home-manager";
          type = "indirect";
        };
        to = {
          path = "${inputs.home-manager}";
          type = "path";
        };
      };
      "nixpkgs".to = {
        path = "${config.nixpkgs.flake.source}";
        type = "path";
      };
      "my-codes" = {
        from = {
          id = "my-codes";
          type = "indirect";
        };
        to = {
          path = "/home/${config.my.mainUser.name}/Documents/my-codes";
          type = "path";
        };
      };
      "nix-config" = {
        from = {
          id = "nix-config";
          type = "indirect";
        };
        to = {
          path = "/home/${config.my.mainUser.name}/Documents/nix-config";
          type = "path";
        };
      };
    };
    settings = {
      accept-flake-config = true; # Experimental
      auto-optimise-store = true;
      experimental-features = [
        "flakes"
        "nix-command"
      ];
      /*
        extra-sandbox-paths = lib.optionals config.programs.ccache.enable [
          config.programs.ccache.cacheDir
        ];
      */
      fsync-metadata = false;
      http-connections = 0;
      max-jobs = lib.mkDefault 32;
      substituters = [
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      ];
      trusted-users = [ config.my.mainUser.name ];
    };
    package = pkgs.lixPackageSets.git.lix;
  };
}
