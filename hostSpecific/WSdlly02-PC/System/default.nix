{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./bootloader.nix
    ./cups.nix
    ./gpu.nix
    ./localdisksmount.nix
    ./networking.nix
    ./nixpkgs-x86_64.nix
    ./plymouth.nix
    ##./remotefsmount.nix
    ./tailscale.nix
    ./tpm.nix
  ];

  boot = {
    initrd = {
      supportedFilesystems = [ "btrfs" ];
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
      ];
      verbose = false;
      kernelModules = [ ];
      systemd.enable = true; # Hibernate Required
    };
    consoleLogLevel = 3;
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest; # pkgs.linuxPackages_xanmod_latest is the equivalent
    # Notice: pkgs.linuxKernel.packages."..." is an attribute set, pkgs.linuxKernel.kernels."..." is the real kernel package
    kernelModules = [
      "kvm-amd"
      # "snd-hda-intel"
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      zenergy
    ];
    # extraModprobeConfig = "options snd-hda-intel dmic_detect=0 model=auto position_fix=1";
    kernelParams = [
      "quiet"
      "nowatchdog"
      "udev.log_level=3"
      "amd_pstate=active"
      "amd_iommu=pt"
      "amdgpu.ppfeaturemask=0xffffffff"
    ];
    # blacklistedKernelModules = ["k10temp"];
    tmp = {
      useTmpfs = true;
      tmpfsSize = "100%";
      cleanOnBoot = true;
    };
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/9c058d11-63b8-4a19-8884-28519aaa8b16";
      fsType = "btrfs";
      options = [
        "rw"
        "relatime"
        "ssd"
        "discard=async"
        "space_cache=v2"
        "subvol=@"
      ];
    };
    "/nix" = {
      device = "/dev/disk/by-uuid/a7715c2f-c6e1-48a9-b891-4fe319c6c727";
      fsType = "ext4";
      options = [
        "rw"
        "noatime"
      ];
    };
    "/home" = {
      device = "/dev/disk/by-uuid/9c058d11-63b8-4a19-8884-28519aaa8b16";
      fsType = "btrfs";
      options = [
        "rw"
        "relatime"
        "ssd"
        "discard=async"
        "space_cache=v2"
        "subvol=@home"
      ];
    };
    "/var/cache" = {
      device = "/dev/disk/by-uuid/9c058d11-63b8-4a19-8884-28519aaa8b16";
      fsType = "btrfs";
      options = [
        "rw"
        "relatime"
        "ssd"
        "discard=async"
        "space_cache=v2"
        "subvol=@var-cache"
      ];
    };
    "/var/log" = {
      device = "/dev/disk/by-uuid/9c058d11-63b8-4a19-8884-28519aaa8b16";
      fsType = "btrfs";
      options = [
        "rw"
        "relatime"
        "ssd"
        "discard=async"
        "space_cache=v2"
        "subvol=@var-log"
      ];
    };
    "/var/tmp" = {
      device = "/dev/disk/by-uuid/9c058d11-63b8-4a19-8884-28519aaa8b16";
      fsType = "btrfs";
      options = [
        "rw"
        "relatime"
        "ssd"
        "discard=async"
        "space_cache=v2"
        "subvol=@var-tmp"
      ];
    };
    "/efi" = {
      device = "/dev/disk/by-uuid/18B2-C53C";
      fsType = "vfat";
      options = [
        "rw"
        "relatime"
        "fmask=0022"
        "dmask=0022"
        "codepage=437"
        "iocharset=ascii"
        "shortname=mixed"
        "errors=remount-ro"
      ];
    };
  };
  swapDevices = [
    {
      device = "/nix/swapfile";
      discardPolicy = "pages";
    }
  ];
  hardware = {
    enableRedistributableFirmware = true;
    # enableAllHardware = true;
    # enableAllFirmware = true;
    firmwareCompression = "zstd";
    cpu.amd = {
      ryzen-smu.enable = true;
      updateMicrocode = true;
    };
    i2c.enable = true;
    # uinput.enable = true; # Enable /dev/uinput
    xone.enable = true;
  };
}
