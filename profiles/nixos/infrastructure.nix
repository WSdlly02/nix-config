{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  options.my.networking.firewall = {
    extraAllowedPorts = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.port;
      apply = ports: lib.unique (builtins.sort builtins.lessThan ports);
      description = ''
        List of ports on which incoming connections are
        accepted.
      '';
    };
    extraAllowedPortRanges = lib.mkOption {
      default = [ ];
      type = lib.types.listOf (lib.types.attrsOf lib.types.port);
      description = ''
        A range of ports on which incoming connections are
        accepted.
      '';
    };
    lanOnlyPorts = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.port;
      apply = ports: lib.unique (builtins.sort builtins.lessThan ports);
      description = ''
        List of ports will be excluded from allowedPorts
      '';
    };
    lanOnlyPortRanges = lib.mkOption {
      default = [ ];
      type = lib.types.listOf (lib.types.attrsOf lib.types.port);
      description = ''
        A range of ports will be excluded from allowedPortRanges
      '';
    };
  };

  config = {
    users.users.wsdlly02.extraGroups = [
      "audio"
      "networkmanager"
      "render"
      "video"
    ];

    environment.systemPackages = with pkgs; [
      android-tools
      compsize
      cryptsetup
      lm_sensors
      pciutils
      psmisc
      usbutils
    ];

    time.timeZone = "Asia/Singapore";
    i18n.extraLocales = [ "zh_CN.UTF-8/UTF-8" ];

    services.atd.enable = true;
    services.journald.settings.Journal = {
      Compress = true;
      Storage = "auto";
      SystemMaxUse = if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then "512M" else "256M";
    };

    nix.registry = {
      home-manager.to = {
        type = "path";
        path = "${inputs.home-manager}";
      };
      nixpkgs.to = {
        type = "path";
        path = "${config.nixpkgs.flake.source}";
      };
      my-codes.to = {
        type = "git";
        url = "file:///home/wsdlly02/Documents/my-codes";
      };
      nix-config.to = {
        type = "git";
        url = "file:///home/wsdlly02/Documents/nix-config";
      };
    };
    nix.settings = {
      accept-flake-config = true;
      nix-path = [
        "home-manager=${inputs.home-manager}"
        "nixpkgs=${config.nixpkgs.flake.source}"
        "my-codes=git+file:///home/wsdlly02/Documents/my-codes"
        "nix-config=git+file:///home/wsdlly02/Documents/nix-config"
      ];
      substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
    };

    networking = {
      hostName = config.system.name;
      nftables.enable = lib.mkDefault false;
      tempAddresses = "disabled";
      firewall = {
        enable = lib.mkForce false;
        allowedTCPPorts = [
          53 # dnsmasq
          12024 # Minecraft Server
          21027 # Syncthing
          22000 # Syncthing
        ]
        ++ config.my.networking.firewall.extraAllowedPorts;
        allowedTCPPortRanges = config.my.networking.firewall.extraAllowedPortRanges;
        allowedUDPPorts = config.networking.firewall.allowedTCPPorts;
        allowedUDPPortRanges = config.networking.firewall.allowedTCPPortRanges;
      };
      timeServers = [
        "ntp.ntsc.ac.cn"
        "cn.ntp.org.cn"
      ];
    };
    services.timesyncd.servers = config.networking.timeServers;

    networking.networkmanager = {
      enable = true;
      dns = "none";
      ethernet.macAddress = "permanent"; # Wake-on-LAN requires a stable MAC address for the ethernet interface
      wifi = {
        macAddress = "stable-ssid";
        scanRandMacAddress = false;
        powersave = false;
      };
      unmanaged = [
        "except:type:ethernet"
        "except:type:wifi"
      ];
      # rc-manager has been set as unmanaged
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      # nssmdns6 = false;
      settings = {
        server = {
          allow-interfaces = [
            "enp14s0"
            "wlp15s0"
          ];
          disallow-other-stacks = true;
        };
        publish = {
          disable-publishing = false;
          disable-user-service-publishing = false;
          publish-addresses = true;
          publish-workstation = true;
        };
      };
    };

    services.dnsmasq = {
      enable = true;
      alwaysKeepRunning = true;
      settings = {
        listen-address = [
          "127.0.0.1"
          "::1"
        ];
        bind-interfaces = true;
        # Keep resolvconf's interface-specific upstreams out of the forwarding list.
        conf-file = [ ];
        resolv-file = [ ];
        no-resolv = true;
        no-poll = true;
        server = [
          "127.0.0.1#10053"
          "223.5.5.5"
          "1.1.1.1"
          "8.8.8.8"
          "8.8.4.4"
        ];
        strict-order = true;
        cache-size = 0;
        no-negcache = true;
        no-dhcp-interface = "*";
      };
    };

    services.mihomo = {
      enable = true;
      tunMode = true;
      configFile = "/home/wsdlly02/.config/mihomo/config.yaml";
      webui = pkgs.metacubexd;
    };

    services.easytier = {
      enable = true;
      instances.default.configFile = "/home/wsdlly02/.config/easytier/config.toml";
    };

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.rp_filter" = 1; # 反向路径过滤
      "net.ipv4.conf.default.rp_filter" = 1;
      "vm.max_map_count" = 2147483642;
    };

    hardware.bluetooth = {
      enable = true;
      settings = {
        General = {
          JustWorksRepairing = "always";
          FastConnectable = true;
          KernelExperimental = true;
          Experimental = true;
        };
      };
    };

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      audio.enable = true;
      alsa.enable = true;
      pulse.enable = true;
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

    programs.gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
        enableBrowserSocket = true;
        enableExtraSocket = true;
        pinentryPackage = pkgs.writeShellScriptBin "pinentry" ''
          # SSH 一律 TUI
          if [ -n "''${SSH_TTY-}" ] || [ -n "''${SSH_CONNECTION-}" ]; then
            exec ${pkgs.pinentry-curses}/bin/pinentry-curses "$@"
          fi

          # 本机图形会话: Wayland / X11 任一存在就走 Qt
          if [ -n "''${WAYLAND_DISPLAY-}" ] || [ -n "''${DISPLAY-}" ]; then
            exec ${pkgs.pinentry-qt}/bin/pinentry-qt "$@"
          fi

          # 兜底: 纯 TTY
          exec ${pkgs.pinentry-curses}/bin/pinentry-curses "$@"
        '';
      };
    };

    services.getty = {
      greetingLine = ''
        ${config.system.name} (\m)
        ${config.system.nixos.distroName} ${lib.concatStringsSep " " config.system.nixos.tags} \r
        Date: \d \t
        Terminal: \l
      '';
      helpLine = lib.mkForce "";
    };

    programs = {
      fuse.userAllowOther = true;
      bandwhich.enable = true;
      usbtop.enable = true;
    };
  };
}
