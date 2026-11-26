{
  inputs,
  pkgs',
}:
let
  hostModule =
    {
      modulesPath,
      pkgs,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
        ../../profiles/nixos/base.nix
        ../../profiles/nixos/server.nix
        ../../profiles/nixos/infrastructure.nix
      ];

      nix.settings.max-jobs = 32;
      environment.systemPackages = with pkgs; [
        # Raspberry Pi specific packages
        libraspberrypi
        i2c-tools
        raspberrypi-eeprom
      ];

      users.users.wsdlly02.extraGroups = [ "i2c" ];
      services.easytier.instances.default.settings.ipv4 = "10.144.144.32/24";
      my.networking.firewall = {
        extraAllowedPorts = [
          8080
        ];
        extraAllowedPortRanges = [ ];
        lanOnlyPorts = [ 5353 ];
        lanOnlyPortRanges = [ ];
      };

      system = {
        name = "WSdlly02-RPi5";
        # nixos.tag = [];
        stateVersion = "26.11";
      };

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
          options = [ "noatime" ];
        };
        "/boot/firmware" = {
          device = "/dev/disk/by-label/FIRMWARE";
          fsType = "vfat";
          options = [ "noatime" ];
        };
      };

      hardware = {
        enableRedistributableFirmware = true;
        i2c.enable = true;
        firmwareCompression = "zstd";
      };
    };
in
inputs.nixpkgs-unstable.lib.nixosSystem rec {
  specialArgs = { inherit inputs; };
  system = "aarch64-linux";
  pkgs = pkgs' system;
  modules = [
    inputs.agenix.nixosModules.default
    hostModule
  ];
}
