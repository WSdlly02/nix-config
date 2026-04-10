{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base
    ../../profiles/nixos/base/smartd.nix
    ../../profiles/nixos/base/btrfs-scrub.nix
    ../../profiles/nixos/development
    ../../profiles/nixos/desktop
    ../../profiles/nixos/gaming
    ../../profiles/nixos/infrastructure
    ../../profiles/nixos/infrastructure/bluetooth.nix
    ./hardware.nix
    ./system.nix
  ];

  boot.kernel.sysctl."vm.swappiness" = 100;
  nix.settings.max-jobs = 64;

  hostSystemSpecific = {
    enablePythonRocmSupport = true;
    environment.extraSystemPackages = with pkgs; [
      amdgpu_top
      # distrobox
      lact # AMDGPU Fan Control
      libva-utils
      mesa-demos
      ntfs3g
      rar # ark required
      vdpauinfo
      vulkan-tools
    ];
    defaultUser = {
      name = "wsdlly02";
      linger = true;
      extraGroups = [
        "kvm"
        "libvirtd"
        "podman"
      ];
    };
    networking.firewall = {
      extraAllowedPorts = [ ];
      extraAllowedPortRanges = [ ];
      lanOnlyPorts = [ 5353 ];
      lanOnlyPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };
}
