{
  /*
    nixpkgs = {
      hostPlatform = lib.mkDefault "x86_64-linux"; # specific this option blocks nixpkgs.crossSystem
      # localSystem = null; # equals to nixpkgs.buildPlatform
      # buildPlatform = config.nixpkgs.hostPlatform;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
        enableParallelBuilding = true;
      };
    };
    nixpkgs.crossSystem = {
      # Target platform
      system = "aarch64-linux";
    };
    Specifies the platform for which NixOS should be built.
    Specify this only if it is different from nixpkgs.localSystem,
    the platform on which NixOS should be built.
    In other words, specify this to cross-compile NixOS.
  */
  boot.binfmt.emulatedSystems = [
    # use QEMU to emulate systems for compiling pkgs of different archs.
    "aarch64-linux"
  ];
  system = {
    name = "WSdlly02-WSL";
    # nixos.tag = [];
    stateVersion = "25.05";
  };
}
