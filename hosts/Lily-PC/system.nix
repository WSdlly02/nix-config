{ pkgs, ... }:
{
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      gfxmodeEfi = "2560x1440";
      theme = pkgs.sleek-grub-theme;
      efiSupport = true;
      extraEntries = ''
        menuentry "Windows" {
        search --file --no-floppy --set=root /EFI/Microsoft/Boot/bootmgfw.efi
        chainloader (''${root})/EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
  };

  system.stateVersion = "24.05";
}
