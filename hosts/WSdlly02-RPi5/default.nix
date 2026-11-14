{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base.nix
    ../../profiles/nixos/infrastructure.nix
    ./system.nix
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

  systemd.user.services = {
    pipewire = {
      preStart = "${pkgs.networkmanager}/bin/nm-online -q"; # Fix up
      wantedBy = [ "default.target" ];
    };
    pipewire-pulse.wantedBy = [ "default.target" ];
    wireplumber.wantedBy = [ "default.target" ];
  };
}
