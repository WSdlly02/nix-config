{ inputs, pkgs' }:
let
  hostModule =
    {
      config,
      modulesPath,
      pkgs,
      ...
    }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        inputs.agenix.nixosModules.default
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

      boot.kernel.sysctl."net.ipv6.conf.eth0.autoconf" = 0;

      services.easytier = {
        enable = true;
        instances.default = {
          settings.listeners = [
            "tcp://0.0.0.0:11010"
            "udp://0.0.0.0:11010"
            "wg://0.0.0.0:11011"
            "ws://0.0.0.0:11011/"
            "quic://0.0.0.0:11012"
            "wss://0.0.0.0:11012/"
            "faketcp://0.0.0.0:11013"
          ];
          extraArgs = [
            "--relay-network-whitelist=wsdlly02-easytier"
          ];
        };
      };

      age.secrets = {
        hysteria.file = ./secrets/hysteria.yaml.age;
        xray.file = ./secrets/xray.json.age;
        cloudflared-token.file = ./secrets/cloudflared-token.age;
      };

      systemd.services.hysteria = {
        description = "Hysteria 2 server";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        restartTriggers = [ config.age.secrets.hysteria.file ];
        environment.HYSTERIA_LOG_LEVEL = "warn";
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = "hysteria";
          StateDirectoryMode = "0700";
          LoadCredential = "config.yaml:${config.age.secrets.hysteria.path}";
          ExecStart = "${pkgs.hysteria}/bin/hysteria server -c %d/config.yaml";
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
          Restart = "always";
          RestartSec = 3;
        };
      };

      services.xray = {
        enable = true;
        settingsFile = config.age.secrets.xray.path;
      };
      systemd.services.xray.restartTriggers = [ config.age.secrets.xray.file ];

      # Ingress is managed in Cloudflare. This connector only needs its tunnel token.
      systemd.services.yunzhizuo-cloudflared = {
        description = "Cloudflare Tunnel for Yunzhizuo";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        restartTriggers = [ config.age.secrets.cloudflared-token.file ];
        serviceConfig = {
          DynamicUser = true;
          LoadCredential = "token:${config.age.secrets.cloudflared-token.path}";
          ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file %d/token";
          Restart = "always";
          RestartSec = 5;
        };
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
        sqlite
        unzip
      ];
    };
in
inputs.nixpkgs-unstable.lib.nixosSystem rec {
  specialArgs = { inherit inputs; };
  system = "x86_64-linux";
  pkgs = pkgs' system;
  modules = [ hostModule ];
}
