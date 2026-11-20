{ inputs, pkgs' }:
let
  hostModule =
    { modulesPath, pkgs, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ../../profiles/nixos/base.nix
        ../../profiles/nixos/server.nix
      ];
      system.stateVersion = "26.11";
      networking.hostName = "WSdlly02-SRV-JP";
      time.timeZone = "Asia/Tokyo";

      boot.loader.grub.device = "/dev/vda";
      boot.kernelParams = [
        "console=tty0"
        "console=ttyS0,115200"
        "consoleblank=0"
      ];
      fileSystems."/" = {
        device = "/dev/disk/by-uuid/a4ec458e-3d15-4427-9f56-e2730cd5b672";
        fsType = "ext4";
        options = [ "errors=remount-ro" ];
      };
      swapDevices = [
        {
          device = "/swapfile";
          size = 2048;
        }
      ];
      services.qemuGuest.enable = true;
      services.cloud-init.enable = false;

      # NoCloud seed v1, eth0. The IPv6 gateway is outside the assigned /64.
      networking.useDHCP = false;
      networking.useNetworkd = true;
      # Rootless Podman waits for the system instance to reach this target.
      systemd.targets.network-online.wantedBy = [ "multi-user.target" ];
      networking.usePredictableInterfaceNames = false;
      networking.tempAddresses = "disabled";
      networking.firewall.enable = false; # Current host has ACCEPT policies and no nftables rules.
      networking.nameservers = [
        "8.8.8.8"
        "1.1.1.1"
      ];
      services.resolved.enable = false;
      networking.hosts."127.0.1.1" = [ "yviy85pxhv.bytevirt.com" ];
      systemd.network.networks."10-uplink" = {
        matchConfig.MACAddress = "18:97:07:2f:1a:fd";
        address = [
          "31.57.172.176/24"
          "2a12:bec0:689:1301::/64"
        ];
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = false;
          LinkLocalAddressing = "ipv6";
        };
        routes = [
          {
            Gateway = "31.57.172.1";
            GatewayOnLink = true;
          }
          {
            Gateway = "2a12:bec0:689::1";
            GatewayOnLink = true;
          }
        ];
      };

      boot.kernel.sysctl = {
        "net.ipv6.conf.eth0.autoconf" = 0;
        # Rootless Hysteria and Xray bind port 443.
        "net.ipv4.ip_unprivileged_port_start" = 80;
      };

      services.logind.settings.Login = {
        NAutoVTs = 1;
        ReserveVT = 1;
      };
      services.journald.settings.Journal = {
        Compress = true;
        SystemMaxUse = "128M";
        SystemKeepFree = "1G";
        SystemMaxFileSize = "20M";
        RuntimeMaxUse = "24M";
        ForwardToSyslog = false;
      };
      virtualisation.podman.enable = true;
      nix.settings.max-jobs = 1;
      environment.systemPackages = with pkgs; [
        python3
        sqlite
        unzip
      ];
    };
in
inputs.nixpkgs-unstable.lib.nixosSystem rec {
  specialArgs = { inherit inputs; };
  system = "x86_64-linux";
  pkgs = pkgs' { inherit system; };
  modules = [ hostModule ];
}
