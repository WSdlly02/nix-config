{
  config,
  lib,
  pkgs,
  ...
}:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber = {
      enable = true;
      extraConfig = {
        "10-allow-headless" = {
          "wireplumber.profiles" = {
            main = {
              "monitor.bluez.seat-monitoring" = "disabled";
            };
          };
        };
        "20-bluetooth-policy" = {
          "wireplumber.settings" = {
            "bluetooth.autoswitch-to-headset-profile" = false;
          };
        };
      };
    };
  };
  systemd.user.services = lib.mkMerge [
    (lib.mkIf (config.system.name == "WSdlly02-PC") {
      gigabyte-usb-audio-profile = {
        description = "Enable Gigabyte USB audio profile";
        after = [ "wireplumber.service" ];
        wantedBy = [ "wireplumber.service" ];
        script = ''
          # WirePlumber's Type=simple starts before its profile policy settles.
          ${pkgs.coreutils}/bin/sleep 1
          for _ in {1..50}; do
            if ${pkgs.pulseaudio}/bin/pactl set-card-profile alsa_card.usb-Generic_USB_Audio-00 HiFi; then
              exit 0
            fi
            ${pkgs.coreutils}/bin/sleep 0.1
          done
          exit 1
        '';
      };
    })
    (lib.mkIf (config.system.name == "WSdlly02-RPi5") {
      pipewire = {
        preStart = "${pkgs.networkmanager}/bin/nm-online -q"; # Fix up
        wantedBy = [ "default.target" ];
      };
      pipewire-pulse.wantedBy = [ "default.target" ];
      wireplumber.wantedBy = [ "default.target" ];
    })
  ];
}
