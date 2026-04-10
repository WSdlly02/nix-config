{ pkgs, ... }:
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
        rocmSupport = true;
      };
    };
    nixpkgs.crossSystem = {
      # Target platform
      system = "aarch64-linux";
    };
    # Specifies the platform for which NixOS should be built.
    # Specify this only if it is different from nixpkgs.localSystem,
    # the platform on which NixOS should be built.
    # In other words, specify this to cross-compile NixOS.
  */
  boot.binfmt = {
    emulatedSystems = [
      # use QEMU to emulate systems for compiling pkgs of different archs.
      "x86_64-windows"
      "aarch64-linux"
    ];
    registrations."x86_64-windows".interpreter = "${pkgs.wineWow64Packages.waylandFull}/bin/wine";
    # Change the default emulator
  };
  system = {
    name = "WSdlly02-PC";
    # nixos.tag = [ ];
    stateVersion = "24.11";
  };
}
