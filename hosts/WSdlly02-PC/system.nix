{ ... }:
{
  imports = [
    ./system-modules/cups.nix
    ./system-modules/networking.nix
    ./system-modules/nixpkgs-x86_64.nix
    ./system-modules/samba.nix
    ./system-modules/virtualisation.nix
    # ./system-modules/remotefsmount.nix
  ];
}
