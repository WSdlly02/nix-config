{
  pkgs,
  ...
}:
{
  boot.loader = {
    timeout = 6;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
    # grub = {
    #   enable = true;
    #   device = "nodev";
    #   gfxmodeEfi = "2560x1440";
    #   theme = pkgs.sleek-grub-theme.override {
    #     withStyle = "light";
    #     withBanner = "WSdlly02-PC Boot";
    #   };
    #   efiSupport = true;
    #   extraEntries = ''
    #     menuentry "Windows" --class windows {
    #       search --file --no-floppy --set=root /EFI/Microsoft/Boot/bootmgfw.efi
    #       chainloader (''${root})/EFI/Microsoft/Boot/bootmgfw.efi
    #     }
    #     menuentry "System restart" --class restart {
    #       echo "System rebooting..."
    #       reboot
    #     }
    #     menuentry "System shutdown" --class shutdown {
    #       echo "System shutting down..."
    #       halt
    #     }
    #     if [ ''${grub_platform} == "efi" ]; then
    #       menuentry 'UEFI Firmware Settings' --id 'uefi-firmware' --class driver {
    #         fwsetup
    #       }
    #     fi
    #   '';
    # };
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
}
