{
  inputs,
}:
let
  hostModule =
    { lib, pkgs, ... }:
    {
      imports = [
        ../../profiles/nixos/base.nix
        ../../profiles/nixos/infrastructure.nix
      ];

      nix.settings.max-jobs = 32;
      environment.systemPackages = with pkgs; [
        # Raspberry Pi specific packages
        libraspberrypi
        i2c-tools
        raspberrypi-eeprom
      ];

      users.users.wsdlly02.extraGroups = [
        "i2c"
        "video"
      ];

      my.networking.firewall = {
        extraAllowedPorts = [
          8080
        ];
        extraAllowedPortRanges = [ ];
        lanOnlyPorts = [ 5353 ];
        lanOnlyPortRanges = [ ];
      };

      networking.networkmanager.unmanaged = lib.mkForce [
        "except:interface-name:eth0"
        "except:interface-name:wlan0"
      ];

      systemd.services.route-switch = {
        description = "Auto switch default route between eth0 and wlan0";
        path = with pkgs; [
          coreutils
          gawk
          gnugrep
          iproute2
          iputils
          util-linux
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash ${./route-switch.sh}";
        };
      };

      systemd.timers.route-switch = {
        description = "Periodically run route-switch to choose best interface";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5s";
          OnUnitActiveSec = "60s";
          Unit = "route-switch.service";
        };
      };

      systemd.user.services = {
        pipewire = {
          preStart = "${pkgs.networkmanager}/bin/nm-online -q"; # Fix up
          wantedBy = [ "default.target" ];
        };
        pipewire-pulse.wantedBy = [ "default.target" ];
        wireplumber.wantedBy = [ "default.target" ];
      };

      system = {
        name = "WSdlly02-RPi5";
        # nixos.tag = [];
        stateVersion = "25.05";
      };

      boot.loader.raspberryPi.bootloader = lib.mkForce "kernel";
      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
          options = [
            "noatime"
            "x-initrd.mount"
          ];
        };
        "/boot/firmware" = {
          device = "/dev/disk/by-label/FIRMWARE";
          fsType = "vfat";
          options = [
            "noauto"
            "noatime"
            "x-systemd.automount"
            "x-systemd.idle-timeout=1min"
          ];
        };
      };

      hardware = {
        enableRedistributableFirmware = true;
        i2c.enable = true;
        firmwareCompression = "zstd";
      };
    };
in
inputs.nixos-raspberrypi.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = [
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.bluetooth
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
    inputs.quadlet-nix.nixosModules.quadlet
    hostModule
  ];
}
