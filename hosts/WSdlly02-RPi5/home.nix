{
  inputs,
  pkgs',
}:
let
  homeModule =
    {
      pkgs,
      ...
    }:
    {
      imports = [
        ../../profiles/home/base.nix
      ];

      home = {
        packages = with pkgs; [ mcrcon ];
        stateVersion = "25.05";
      };

      programs.java = {
        enable = true;
        package = pkgs.zulu25;
      };

      programs.fish = {
        interactiveShellInit = ''
          set -g WSdlly02_PC_MAC_ADDR 10:ff:e0:35:6a:95
        '';
        shellAliases.wake-pc = "${pkgs.wakeonlan}/bin/wakeonlan -i 192.168.1.255 $WSdlly02_PC_MAC_ADDR";
      };
    };

in
inputs.home-manager.lib.homeManagerConfiguration {
  extraSpecialArgs = { inherit inputs; };
  modules = [
    homeModule
  ];
  pkgs = pkgs' { system = "aarch64-linux"; };
}
