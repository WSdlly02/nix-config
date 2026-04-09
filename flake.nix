{
  description = "WSdlly02's NixOS flake";
  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
    connect-timeout = 5;
  };
  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    my-codes = {
      url = "github:WSdlly02/my-codes/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/develop";
      # inputs.nixpkgs.url = "github:nvmd/nixpkgs/modules-with-keys-unstable"; # Use custom nixpkgs with Raspberry Pi modules
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs-unstable) lib;
      inherit (inputs.self.lib) pkgs';
      exposedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # this function folds over all exposed systems and merges the results
      forExposedSystems = f: builtins.foldl' lib.recursiveUpdate { } (map f exposedSystems);
    in
    {
      homeConfigurations = {
        "wsdlly02@WSdlly02-PC" = inputs.home-manager.lib.homeManagerConfiguration {
          modules = [
            inputs.self.homeModules.default
            inputs.quadlet-nix.homeManagerModules.quadlet
            inputs.zen-browser.homeModules.beta
            ./hosts/WSdlly02-PC/home.nix
          ];
          pkgs = pkgs' { system = "x86_64-linux"; };
        };
        "wsdlly02@WSdlly02-WSL" = inputs.home-manager.lib.homeManagerConfiguration {
          modules = [
            inputs.self.homeModules.default
            ./hostSpecific/WSdlly02-WSL/Home
          ];
          pkgs = pkgs' { system = "x86_64-linux"; };
        };
        "wsdlly02@WSdlly02-RPi5" = inputs.home-manager.lib.homeManagerConfiguration {
          modules = [
            inputs.self.homeModules.default
            ./hostSpecific/WSdlly02-RPi5/Home
          ];
          pkgs = pkgs' { system = "aarch64-linux"; };
        };
      };
      homeModules.default = {
        _module.args = { inherit inputs; };
        imports = [ ./modules/homeModules ];
      };
      lib = import ./lib { inherit inputs; };
      nixosConfigurations = {
        "WSdlly02-PC" = lib.nixosSystem rec {
          system = "x86_64-linux";
          pkgs = pkgs' { inherit system; };
          modules = [
            inputs.self.nixosModules.default
            inputs.quadlet-nix.nixosModules.quadlet
            ./hosts/WSdlly02-PC
          ];
        };
        "WSdlly02-RPi5" = inputs.nixos-raspberrypi.lib.nixosSystem {
          specialArgs = inputs;
          modules = [
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.bluetooth
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
            inputs.self.nixosModules.default
            inputs.quadlet-nix.nixosModules.quadlet
            ./hostSpecific/WSdlly02-RPi5
          ];
        };
        "WSdlly02-WSL" = lib.nixosSystem rec {
          system = "x86_64-linux";
          pkgs = pkgs' { inherit system; };
          modules = [
            inputs.nixos-wsl.nixosModules.default
            inputs.self.nixosModules.default
            ./hostSpecific/WSdlly02-WSL
          ];
        };
        "WSdlly02-SRV" = lib.nixosSystem rec {
          system = "x86_64-linux";
          pkgs = pkgs' { inherit system; };
          modules = [
            { system.name = "WSdlly02-SRV"; }
            inputs.self.nixosModules.default
            ./hostSpecific/WSdlly02-SRV
          ];
        };
        "Lily-PC" = lib.nixosSystem rec {
          system = "x86_64-linux";
          pkgs = pkgs' { inherit system; };
          modules = [
            { system.name = "Lily-PC"; }
            inputs.self.nixosModules.default
            ./hostSpecific/Lily-PC
          ];
        };
      };
      nixosModules.default = {
        _module.args = { inherit inputs; };
        imports = [ ./modules/nixosModules ];
      };
      overlays = {
        default = final: prev: {
          /*
            NixOS 通过 lib.mkMerge 将所有模块的 environment.systemPackages 合并为一个有序列表。
            这个列表的顺序取决于模块的 import 顺序。你修改 flake.nix 入口定义时，即使功能等价，也可能改变了模块被求值和合并的顺序，从而导致包列表排列不同 。
            buildEnv（NixOS system-path 的构建器）把这个列表直接作为 derivation 输入，因此：
            包列表顺序变了 → buildEnv 的 inputDrvs 顺序变了 → drv 哈希变了
            ↓
            但实际链接进 /run/current-system 的文件完全一样
            这就是为什么哈希变了但内容没变的情况。
          */
          buildEnv =
            args:
            let
              name = args.name or "";
              # 精确匹配需要排序的三类 derivation
              # 确保它们在最终的 system-path 中按照字母序排列，避免不必要的哈希变动
              isSortTarget =
                name == "system-path" || name == "man-paths" || lib.hasSuffix "_fish-completions" name;
            in
            prev.buildEnv (
              if isSortTarget then
                args
                // {
                  paths = lib.sort (a: b: lib.getName a < lib.getName b) (args.paths or [ ]);
                }
              else
                args
            );
          # Overlays here will be applied to all packages
        };
        exposedPackages =
          # Packages here will be exposed and used as libraries in other parts of the flake
          final: prev:
          (inputs.self.legacyPackages.${prev.stdenv.hostPlatform.system} or { }).exposedPackages or { };
        libraryPackages =
          # Packages here will be used as library but won't be exposed
          final: prev:
          (inputs.self.legacyPackages.${prev.stdenv.hostPlatform.system} or { }).libraryPackages or { };
      };
    }
    // forExposedSystems (
      system: with (pkgs' { inherit system; }); {
        devShells."${system}" = inputs.my-codes.devShells."${system}" // rec {
          aitools = callPackage ./pkgs/devShells-aitools.nix { };
          default = aitools;
          nixfmt = callPackage ./pkgs/devShells-nixfmt.nix { };
        };
        formatter."${system}" = nixfmt-tree;
        legacyPackages."${system}" = {
          exposedPackages = {
            currentNixConfig = callPackage ./pkgs/currentNixConfig.nix { inherit inputs; };
            epson-inkjet-printer-201601w = callPackage ./pkgs/epson-inkjet-printer-201601w.nix { };
            fabric-survival = callPackage ./pkgs/fabric-survival.nix { };
          };
          libraryPackages = { };
          my-codes-exposedPackages = inputs.my-codes.legacyPackages."${system}".exposedPackages; # For convenience
          nixpkgs-unstable = pkgs' { inherit system; };
        };
      }
    );
}
