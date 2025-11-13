{
  description = "WSdlly02's NixOS flake";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    my-codes = {
      url = "github:WSdlly02/my-codes/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
        "wsdlly02@WSdlly02-RaspberryPi5" = inputs.home-manager.lib.homeManagerConfiguration {
          modules = [
            inputs.self.homeModules.default
            ./hostSpecific/WSdlly02-RaspberryPi5/Home
          ];
          pkgs = pkgs' { system = "aarch64-linux"; };
        };
      };
      homeModules.default = {
        _module.args = { inherit inputs; };
        imports = [ ./modules/homeModules ];
      };
      lib.pkgs' =
        {
          nixpkgsInstance ? inputs.nixpkgs-unstable,
          config ? { },
          overlays ? [ ],
          system,
        }:
        import nixpkgsInstance {
          inherit system;
          config = {
            allowAliases = false;
            allowUnfree = true;
            rocmSupport = true;
          }
          // config;
          overlays = [
            inputs.my-codes.overlays.exposedPackages
            inputs.self.overlays.default
            inputs.self.overlays.exposedPackages
            inputs.self.overlays.libraryPackages
          ]
          ++ overlays;
        };
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
        "WSdlly02-RaspberryPi5" = lib.nixosSystem rec {
          system = "aarch64-linux";
          pkgs = pkgs' {
            config.rocmSupport = false;
            inherit system;
          };
          modules = [
            inputs.nixos-hardware.nixosModules.raspberry-pi-5
            inputs.self.nixosModules.default
            ./hostSpecific/WSdlly02-RaspberryPi5
          ];
        };
        "WSdlly02-WSL" = lib.nixosSystem rec {
          system = "x86_64-linux";
          pkgs = pkgs' {
            config.rocmSupport = false;
            inherit system;
          };
          modules = [
            inputs.nixos-wsl.nixosModules.default
            inputs.self.nixosModules.default
            ./hostSpecific/WSdlly02-WSL
          ];
        };
        "Lily-PC" = lib.nixosSystem rec {
          system = "x86_64-linux";
          pkgs = pkgs' {
            config.rocmSupport = false;
            inherit system;
          };
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
          final: prev: inputs.self.legacyPackages."${prev.stdenv.hostPlatform.system}".exposedPackages;
        libraryPackages =
          # Packages here will be used as library but won't be exposed
          final: prev: inputs.self.legacyPackages."${prev.stdenv.hostPlatform.system}".libraryPackages;
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
