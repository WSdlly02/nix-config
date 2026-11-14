{
  config,
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

    services.openssh = {
      enable = true;
      ports = [ 10022 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        GatewayPorts = "yes";
        PrintMotd = true;
      };
    };

    boot.kernel.sysctl = {
      # Network performance
      "net.core.netdev_max_backlog" = 16384;
      "net.core.rmem_default" = 1048576;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_default" = 1048576;
      "net.core.wmem_max" = 16777216;
      "net.core.optmem_max" = 65536;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_rmem" = "4096 1048576 2097152";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
      "net.ipv4.tcp_window_scaling" = 1;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.tcp_timestamps" = 0;
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.udp_rmem_min" = 8192;
      "net.ipv4.udp_wmem_min" = 8192;
      # Hardening
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.rp_filter" = 1; # 反向路径过滤
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.tcp_syncookies" = 1; # 防 SYN Flood
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # 忽略广播 ping
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1; # 忽略无效 ICMP
      "net.ipv4.conf.all.accept_source_route" = 0; # 禁止源路由
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv4.conf.all.accept_redirects" = 0; # 禁止接受 ICMP Redirect
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.bootp_relay" = 0; # 防止恶意 BOOTP / DHCP relay
      "net.ipv4.conf.default.bootp_relay" = 0;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.accept_redirects" = 0; # 禁止 IPv6 Redirect
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0; # 禁止 IPv6 源路由
      "net.ipv6.conf.default.accept_source_route" = 0;
      # Kernel Hardening
      "kernel.randomize_va_space" = 2;
      "kernel.unprivileged_bpf_disabled" = 1;
      "kernel.dmesg_restrict" = 1;
      # System
      "vm.max_map_count" = 2147483642;
      "vm.swappiness" = lib.mkDefault 20;
      "vm.watermark_boost_factor" = 15000;
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
