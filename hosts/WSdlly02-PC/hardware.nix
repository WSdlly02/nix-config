{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware/gpu.nix
    ./hardware/fs.nix
  ];

  boot.loader = {
    timeout = 6;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
    limine = {
      enable = true;
      extraEntries = ''
        /Windows 11
          protocol: efi
          path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
      '';
      maxGenerations = 4;
      secureBoot.enable = true;
      style = {
        interface = {
          branding = "WSdlly02-PC Bootloader";
          resolution = "2560x1440";
        };
        wallpapers = [
          "${pkgs.nixos-artwork.wallpapers.catppuccin-latte.gnomeFilePath}"
        ];
      };
    };
  };
  boot.plymouth = {
    enable = true;
    theme = "hexagon_dots";
    themePackages = with pkgs; [
      (adi1090x-plymouth-themes.override { selected_themes = [ "hexagon_dots" ]; })
    ];
  };

  boot = {
    initrd = {
      systemd.tpm2.enable = true;
      supportedFilesystems = [
        "btrfs"
        "ext4"
      ];
      availableKernelModules = [
        "nvme"
        "xhci_pci_prom21"
        "xhci_pci"
        "ahci"
        "usbhid"
      ];
      kernelModules = [ ];
    };
    consoleLogLevel = 3;
    kernelPackages = pkgs.linuxPackages_latest; # Use the latest stable kernel packages
    # kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest; # pkgs.linuxPackages_xanmod_latest is the equivalent
    # Notice: pkgs.linuxKernel.packages."..." is an attribute set, pkgs.linuxKernel.kernels."..." is the real kernel package
    kernelModules = [
      "kvm-amd"
      # "snd-hda-intel"
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
      zenergy
    ];
    extraModprobeConfig = ''
      options mt7921e disable_aspm=1
    '';
    kernelParams = [
      # General
      "quiet"
      "udev.log_level=3"
      # AMD P-State
      "amd_pstate=active"
      # IOMMU
      "iommu=pt"
    ];
    # blacklistedKernelModules = ["k10temp"];
    tmp = {
      useTmpfs = true;
      tmpfsSize = "50%";
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100; # 全部可用内存
    priority = 100; # 优先级设为 100，确保先用它
  };

  swapDevices = [
    {
      device = "/nix/swapfile";
      discardPolicy = "pages";
      priority = 0;
    }
  ];

  hardware = {
    enableRedistributableFirmware = true;
    # enableAllHardware = true;
    # enableAllFirmware = true;
    firmwareCompression = "zstd";
    cpu.amd.updateMicrocode = true;
    i2c.enable = true;
    # uinput.enable = true; # Enable /dev/uinput
    xone.enable = true;
  };

  systemd.tpm2.enable = true;
  security.tpm2.enable = true;

  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "atk-f1-mouse-webhid-udev-rules";
      destination = "/lib/udev/rules.d/70-atk-f1-mouse-webhid.rules";
      text = ''
        # Allow the active local desktop session to use the mouse configuration website.
        # Display Name: Compx Wireless mouse 8k NANO dongle-L
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="11fe", TAG+="uaccess"
      '';
    })
  ];
  systemd.user.services.gigabyte-usb-audio-profile = {
    description = "Enable Gigabyte USB audio profile";
    after = [ "wireplumber.service" ];
    wantedBy = [ "wireplumber.service" ];
    script = ''
      # WirePlumber's Type=simple starts before its profile policy settles.
      ${pkgs.coreutils}/bin/sleep 1
      for _ in {1..50}; do
        if ${pkgs.pulseaudio}/bin/pactl set-card-profile alsa_card.usb-Generic_USB_Audio-00 HiFi; then
          exit 0
        fi
        ${pkgs.coreutils}/bin/sleep 0.1
      done
      exit 1
    '';
  };
}
