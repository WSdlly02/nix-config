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
    enableDevelopment = true;
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
      extraGroups = [ ];
    };
    networking.firewall = {
      enable = false;
      extraAllowedPorts = [ ];
    };
    nix.settings.max-jobs = 64;
    programs.proxychains.proxies.host = "127.0.0.1";
  };
}
