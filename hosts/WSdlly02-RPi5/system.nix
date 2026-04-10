{
  lib,
  ...
}:
{
  imports = [
    ./system-modules/nixpkgs-aarch64.nix
  ];

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

  hardware = {
    enableRedistributableFirmware = true;
    i2c.enable = true;
    firmwareCompression = "zstd";
  };
}
