{ pkgs, ... }:
{
  imports = [
    ./Daily
    ./Gaming
    ./System
  ];
  hostSystemSpecific = {
    boot.kernel.sysctl."vm.swappiness" = 10;
    enableBtrfsScrub = true;
    enableBluetooth = true;
    enableDevEnv = true;
    enableInfrastructure = true;
    enableSmartd = true;
    environment.extraSystemPackages = with pkgs; [
      amdgpu_top
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
      linger = false;
      extraGroups = [
        "libvirtd" # archlinux vm
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
    nix.settings.max-jobs = 64;
  };
}
