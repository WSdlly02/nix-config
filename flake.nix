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
    atrust-rs = {
      url = "git+ssh://git@github.com/WSdlly02/atrust-rs.git";
      flake = false;
    };
    prismagent = {
      url = "git+ssh://git@github.com/WSdlly02/PrismAgent.git";
      flake = false;
    };

    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    my-codes = {
      url = "github:WSdlly02/my-codes/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/develop";
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
      forExposedSystems = f: lib.foldl' lib.recursiveUpdate { } (map f exposedSystems);
    in
    {
      lib = import ./lib { inherit lib inputs; };

      homeConfigurations = {
        "wsdlly02@WSdlly02-PC" = import ./hosts/WSdlly02-PC/home.nix { inherit inputs pkgs'; };
        "wsdlly02@WSdlly02-WSL" = import ./hosts/WSdlly02-WSL/home.nix { inherit inputs pkgs'; };
        "wsdlly02@WSdlly02-RPi5" = import ./hosts/WSdlly02-RPi5/home.nix { inherit inputs pkgs'; };
      };
      nixosConfigurations = {
        "WSdlly02-PC" = import ./hosts/WSdlly02-PC/nixos.nix { inherit inputs pkgs'; };
        "WSdlly02-RPi5" = import ./hosts/WSdlly02-RPi5/nixos.nix { inherit inputs; };
        "WSdlly02-WSL" = import ./hosts/WSdlly02-WSL/nixos.nix { inherit inputs pkgs'; };
      };
      overlays.default =
        final: _prev:
        import ./pkgs {
          pkgs = final;
          inherit inputs;
        };
    }
    // forExposedSystems (
      system:
      let
        pkgs = pkgs' { inherit system; };
        exposedPackages = import ./pkgs { inherit inputs pkgs; };
      in
      {
        devShells."${system}" = { };
        formatter."${system}" = pkgs.nixfmt-tree;
        legacyPackages."${system}" =
          exposedPackages
          // inputs.my-codes.legacyPackages."${system}"
          // {
            nixpkgs-unstable = pkgs;
          };
        packages."${system}" = {
          pkg-in-env = pkgs.callPackage ./lib/pkg-in-env.nix { inherit inputs; };
        };
      }
    );
}
