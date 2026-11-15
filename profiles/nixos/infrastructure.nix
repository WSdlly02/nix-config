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
      resolvconf = {
        enable = true;
        useLocalResolver = true;
      };
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
      nameservers = [ "127.0.0.1" ];
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
        "except:interface-name:enp14s0"
        "except:interface-name:wlp15s0"
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

    virtualisation.quadlet.containers.dnsmasq =
      let
        dnsmasq-conf = pkgs.writeText "dnsmasq.conf" ''
          # 只监听本地 loopback 接口的 53 端口（避免与其他接口冲突）
          listen-address=127.0.0.1
          listen-address=::1

          # 强烈推荐：只绑定指定的地址（额外保险）
          bind-interfaces

          # 不使用系统的 /etc/resolv.conf（防止循环或污染）
          no-resolv
          no-poll

          dns-forward-max=150

          # 上游 DNS：优先转发到你的本地服务（10053端口）
          # 如果 10053 不可用（超时/拒绝/无响应），自动回退到后面的
          server=127.0.0.1#10053
          server=223.5.5.5#53
          server=8.8.8.8#53
          server=8.8.4.4#53
          server=1.1.1.1#53

          # 严格按顺序尝试上游（先全力尝试 10053，失败再用公共 DNS）
          strict-order

          # 禁用缓存（确保每次查询都是最新的）
          cache-size=0
          no-negcache

          # 可选：日志查询，便于调试（生产可注释掉）
          #log-queries
          #log-facility=/var/log/dnsmasq.log

          # 可选：不提供 DHCP 服务（我们只做 DNS 转发）
          port=53                     # 明确指定端口（默认就是53）
          no-dhcp-interface=*
        '';
      in
      {
        containerConfig = {
          image = "docker.io/dockurr/dnsmasq:latest";
          networks = [ "host" ];
          addCapabilities = [
            "NET_ADMIN"
            "NET_BIND_SERVICE"
          ];
          user = "0";
          autoUpdate = "registry";
          volumes = [ "${dnsmasq-conf}:/etc/dnsmasq.conf:ro" ];
        };

        serviceConfig = {
          Delegate = true;
          Restart = "always";
        };

        unitConfig = {
          Description = "Dnsmasq in Podman container";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
      };

    virtualisation.quadlet.containers.mihomo = {
      containerConfig = {
        image = "docker.io/metacubex/mihomo:latest";
        networks = [ "host" ];
        volumes = [ "/home/wsdlly02/.config/mihomo:/etc/mihomo" ];
        addCapabilities = [ "NET_ADMIN" ];
        devices = [ "/dev/net/tun" ];
        exec = [
          "-d"
          "/etc/mihomo"
        ];
        autoUpdate = "registry";
      };

      serviceConfig = {
        Delegate = true;
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /home/wsdlly02/.config/mihomo"
          (pkgs.writeShellScript "wait-for-tailscale-up" ''
            if ${pkgs.systemd}/bin/systemctl is-active --quiet tailscale.service; then
              echo "tailscale is running, waiting for IP 100.64.16.64..."
              until ${pkgs.iproute2}/bin/ip addr show tailscale0 | ${pkgs.gnugrep}/bin/grep -q "100.64.16.64"; do
                ${pkgs.coreutils}/bin/sleep 1
              done
              echo "IP 100.64.16.64 is ready."
            else
              echo "tailscale is not running, skipping wait."
            fi
          '')
        ];
        Restart = "always";
      };

      unitConfig = {
        Description = "Mihomo in Podman container";
        After = [
          "network-online.target"
          "tailscale.service"
        ];
        Wants = [ "network-online.target" ];
      };
    };

    virtualisation.quadlet.containers.easytier = {
      containerConfig = {
        image = "docker.io/easytier/easytier:latest";
        networks = [ "host" ];
        volumes = [
          "/home/wsdlly02/.config/easytier:/etc/easytier"
          "/etc/machine-id:/etc/machine-id:ro"
        ];
        addCapabilities = [
          "NET_ADMIN"
          "NET_RAW"
        ];
        devices = [ "/dev/net/tun" ];
        exec = [
          "--config-dir"
          "/etc/easytier"
        ];
        autoUpdate = "registry";
      };

      serviceConfig = {
        Delegate = true;
        Restart = "always";
      };

      unitConfig = {
        Description = "EasyTier in Podman container";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
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
