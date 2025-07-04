{
  config,
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
{
  config = lib.mkIf enableInfrastructure {
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
          # "50-alsa-config" = {
          #   "monitor.alsa.properties" = {
          #     # 使用 ALSA-Card-Profile 设备。他们使用UCM或配置文件
          #     # 配置配置设备和混音器设置。
          #     "alsa.use-acp" = true;
          #     # 使用 UCM 而不是配置文件(可用时 ) 。可禁用
          #     # 跳过尝试使用 UCM 配置文件。
          #     "alsa.use-ucm" = false;
          #   };
          # };
        };
      };
      socketActivation = config.hostSystemSpecific.services.pipewire.socketActivation;
      extraConfig = {
        pipewire."92-low-latency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 32;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 32;
          };
        };
        pipewire-pulse."92-low-latency" = {
          "context.properties" = [
            {
              name = "libpipewire-module-protocol-pulse";
              args = { };
            }
          ];
          "pulse.properties" = {
            "pulse.min.req" = "32/48000";
            "pulse.default.req" = "32/48000";
            "pulse.max.req" = "32/48000";
            "pulse.min.quantum" = "32/48000";
            "pulse.max.quantum" = "32/48000";
          };
          "stream.properties" = {
            "node.latency" = "32/48000";
            "resample.quality" = 1;
          };
        };
      };
    };
    systemd.user.services = lib.mkIf (config.system.name == "WSdlly02-RaspberryPi5") {
      pipewire = {
        preStart = "${pkgs.networkmanager}/bin/nm-online -q"; # Fix up
        wantedBy = [ "default.target" ];
      };
      pipewire-pulse.wantedBy = [ "default.target" ];
      wireplumber.wantedBy = [ "default.target" ];
    };
  };
}
