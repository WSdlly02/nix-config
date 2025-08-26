{ pkgs, ... }:
{
  imports = [
    ./Daily
    ./Gaming
    ./System
  ];
  hostSystemSpecific = {
    enableBluetooth = true;
    enableDevelopment = true;
    enableInfrastructure = true;
    environment.extraSystemPackages = with pkgs; [
      libraspberrypi
      i2c-tools
      raspberrypi-eeprom
    ];
    defaultUser = {
      name = "wsdlly02";
      linger = true;
      extraGroups = [
        "i2c"
        "video"
      ];
    };
    networking.firewall = {
      extraAllowedPorts = [
        8080
        8384
      ];
      extraAllowedPortRanges = [
        {
          from = 10001;
          to = 10003;
          # ROC Source & Repair & Control ports
        }
      ];
    };
    nix.settings.max-jobs = 32;
    programs = {
      ccache.extraPackageNames = [ "linux_rpi5" ];
    };
    services.pipewire.socketActivation = false;
  };
}
