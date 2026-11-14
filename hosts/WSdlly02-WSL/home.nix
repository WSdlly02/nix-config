{ inputs, pkgs' }:
let
  homeModule = {
    imports = [
      ../../profiles/home/base.nix
    ];

    home.stateVersion = "25.05";
    programs.fish.shellAliases.dl = "aria2c -x 16 -s 16 -k 1M -d /mnt/c/Users/WSdlly02/Downloads --allow-overwrite=true --file-allocation=none --continue=true";
  };
in
inputs.home-manager.lib.homeManagerConfiguration {
  extraSpecialArgs = { inherit inputs; };
  modules = [
    homeModule
  ];
  pkgs = pkgs' { system = "x86_64-linux"; };
}
