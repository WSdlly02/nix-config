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
    disko = {
      url = "github:nix-community/disko/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
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
      forExposedSystems = f: builtins.foldl' lib.recursiveUpdate { } (map f exposedSystems);
    in
    {
      homeConfigurations = {
        "wsdlly02@WSdlly02-PC" = inputs.home-manager.lib.homeManagerConfiguration {
          modules = [
            inputs.self.homeModules.default
            inputs.zen-browser.homeModules.beta
            ./hostSpecific/WSdlly02-PC/Home
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
            ./hostSpecific/WSdlly02-PC
            # TODO: libvirt
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
        devShells."${system}" = rec {
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
            rocmFHSEnv = callPackage ./pkgs/rocmFHSEnv.nix { };
          };
          libraryPackages = { };
          my-codes-exposedPackages = inputs.my-codes.legacyPackages."${system}".exposedPackages; # For convenience
          nixpkgs-unstable = pkgs' { inherit system; };
        };
      }
    );
}
