{
  lib,
  ...
}:
{
  imports = [
    ./nixpkgs-aarch64.nix
  ];

  # boot = {
  #   initrd = {
  #     supportedFilesystems = [
  #       "vfat"
  #       "btrfs"
  #     ];
  #     availableKernelModules = [ ];
  #     # verbose = false;
  #     kernelModules = [ "bcm2835-v4l2" ];
  #     systemd.enable = true; # Hibernate Required
  #   };
  #   loader = {
  #     efi.canTouchEfiVariables = lib.mkForce false;
  #     timeout = 3;
  #     systemd-boot = {
  #       enable = true;
  #       consoleMode = "auto";
  #     };
  #   };
  #   # consoleLogLevel = 3;
  #   kernelPackages = pkgs.linuxKernel.packagesFor pkgs.linux_rpi5;
  #   /*
  #     kernelPackages = pkgs.linuxKernel.packagesFor (pkgs.linuxKernel.kernels.linux_rpi4.override {
  #       rpiVersion = 5;
  #       argsOverride.defconfig = "bcm2712_defconfig";
  #     });
  #     # Already defined in the nixos-hardware.nixosModules.raspberry-pi-5
  #   */
  #   kernelParams = [
  #     # "quiet"
  #     "nowatchdog"
  #     # "udev.log_level=3"
  #     "8250.nr_uarts=11"
  #     "console=ttyAMA10,9600"
  #     "console=tty0"
  #   ];
  #   # tmp.useTmpfs = true; # out of memory when compiling big derivations
  # };
  boot.loader.raspberryPi.bootloader = lib.mkForce "kernel";
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [
        "noatime"
        "x-initrd.mount"
      ];
    };
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [
        "noauto"
        "noatime"
        "x-systemd.automount"
        "x-systemd.idle-timeout=1min"
      ];
    };
  };

  # swapDevices = [
  #   {
  #     device = "/dev/disk/by-uuid/e991f2a1-fd30-48f1-a99b-527220618083";
  #     discardPolicy = "pages";
  #   }
  # ];
  hardware = {
    enableRedistributableFirmware = true;
    i2c.enable = true;
    # enableAllHardware = true;
    # enableAllFirmware = true;
    firmwareCompression = "zstd";
  };
}
