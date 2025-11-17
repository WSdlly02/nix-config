{ inputs, ... }:
{
  nixpkgs = {
    /*
      hostPlatform = lib.mkDefault "aarch64-linux"; # specific this option blocks nixpkgs.crossSystem
      # localSystem = null; # equals to nixpkgs.buildPlatform
      # buildPlatform = config.nixpkgs.hostPlatform;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
        enableParallelBuilding = true;
      };
    */
    overlays = [
      # Very important!!! Don't delete!!!
      # (final: prev: {
      #   makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
      #   linux_rpi5 = prev.linuxKernel.kernels.linux_rpi4.override {
      #     rpiVersion = 5;
      #     argsOverride.defconfig = "bcm2712_defconfig";
      #   };
      # })
      inputs.my-codes.overlays.exposedPackages
      inputs.self.overlays.default
      inputs.self.overlays.exposedPackages
      inputs.self.overlays.libraryPackages
    ];
  };
  /*
    nixpkgs.crossSystem = {
      # Target platform
      system = "aarch64-linux";
    };
    Specifies the platform for which NixOS should be built.
    Specify this only if it is different from nixpkgs.localSystem,
    the platform on which NixOS should be built.
    In other words, specify this to cross-compile NixOS.
  */
  system = {
    name = "WSdlly02-RaspberryPi5";
    # nixos.tag = [];
    stateVersion = "25.05";
  };
}
