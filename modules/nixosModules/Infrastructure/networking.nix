{
  config,
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
let
  expandRanges =
    ranges:
    lib.concatLists (
      map (
        r:
        let
          start = r.from;
          end = r.to;
        in
        lib.range start end
      ) ranges
    );

  allowedPortsFull =
    config.networking.firewall.allowedTCPPorts
    ++ expandRanges config.networking.firewall.allowedTCPPortRanges;
  lanOnlyPortsFull = [
    5353
  ]
  ++ expandRanges [
    {
      from = 1714;
      to = 1764;
    }
  ];
in
{
  config = lib.mkIf enableInfrastructure {
    networking = {
      hostName = config.system.name;
      resolvconf = {
        enable = true;
        useLocalResolver = true;
      };
      nftables.enable = lib.mkDefault false;
      tempAddresses = "disabled";
      firewall = rec {
        enable = lib.mkForce false;
        allowedTCPPorts = [
          12024 # Mincraft Server
          21027 # Syncthing
          22000 # Syncthing
        ]
        ++ config.hostSystemSpecific.networking.firewall.extraAllowedPorts;
        allowedTCPPortRanges = [ ] ++ config.hostSystemSpecific.networking.firewall.extraAllowedPortRanges;
        allowedUDPPorts = allowedTCPPorts;
        allowedUDPPortRanges = allowedTCPPortRanges;
      };
      nameservers = [ "127.0.0.1" ];
      timeServers = [
        "ntp.ntsc.ac.cn"
        "cn.ntp.org.cn"
      ];
    };
    services.timesyncd.servers = config.networking.timeServers;

    systemd.services."iptables-router" = {
      description = "iptables-based router & firewall";
      wantedBy = [ "multi-user.target" ];
      before = [ "mihomo.service" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        IPTABLES=${pkgs.iptables}/bin/iptables
        IP6TABLES=${pkgs.iptables}/bin/ip6tables

        # =========================
        # 1. 清空旧规则
        # =========================
        $IPTABLES -F
        $IPTABLES -X
        $IPTABLES -t nat -F
        $IPTABLES -t nat -X
        $IP6TABLES -F
        $IP6TABLES -X

        # =========================
        # 2. 默认策略
        # =========================
        $IPTABLES -P INPUT DROP
        $IPTABLES -P FORWARD DROP
        $IPTABLES -P OUTPUT ACCEPT

        $IP6TABLES -P INPUT DROP
        $IP6TABLES -P FORWARD DROP
        $IP6TABLES -P OUTPUT ACCEPT

        # =========================
        # 3. 基础放行（本地 & 已建立连接）
        # =========================
        $IPTABLES -A INPUT -i lo -j ACCEPT # 允许本地回环
        $IP6TABLES -A INPUT -i lo -j ACCEPT

        $IPTABLES -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT # 已建立/相关连接
        $IPTABLES -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        $IP6TABLES -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        $IP6TABLES -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        # =========================
        # 4. 允许局域网流量
        # =========================
        $IPTABLES -A INPUT -s 192.168.1.0/24 -j ACCEPT             # 家庭局域网
        $IPTABLES -A INPUT -s 10.42.0.0/24 -j ACCEPT               # 热点子网
        $IPTABLES -A INPUT -p icmp --icmp-type echo-request -j ACCEPT # 允许 ping
        $IPTABLES -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT # 路由/端口不可达
        $IPTABLES -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT # TTL 超时

        $IP6TABLES -A INPUT -s fe80::/10 -j ACCEPT                 # IPv6 链路本地地址
        $IP6TABLES -A INPUT -d ff02::/16 -j ACCEPT                 # IPv6 多播地址
        $IP6TABLES -A INPUT -p icmpv6 -j ACCEPT                    # IPv6 必需的 ICMPv6 (邻居发现/PMTU)

        # =========================
        # 5. 放行DHCP广播
        # =========================
        $IPTABLES -A INPUT  -p udp --sport 68 --dport 67 -j ACCEPT
        $IPTABLES -A INPUT -p udp --sport 67 --dport 68 -j ACCEPT
        $IPTABLES -A OUTPUT -p udp --sport 67 --dport 68 -j ACCEPT
        $IPTABLES -A OUTPUT  -p udp --sport 68 --dport 67 -j ACCEPT

        # =========================
        # 6. 热点转发与 NAT
        # =========================
        $IPTABLES -A FORWARD -s 10.42.0.0/24 -j ACCEPT # 允许热点设备新建连接
        $IPTABLES -t nat -A POSTROUTING -s 10.42.0.0/24 -j MASQUERADE

        # =========================
        # 7. DNS 劫持到 mihomo:10053
        # =========================
        # 热点设备 DNS
        $IPTABLES -t nat -A PREROUTING -s 10.42.0.0/24 -p udp --dport 53 -j REDIRECT --to-port 10053
        $IPTABLES -t nat -A PREROUTING -s 10.42.0.0/24 -p tcp --dport 53 -j REDIRECT --to-port 10053

        # 本机 DNS
        $IPTABLES -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-port 10053
        $IPTABLES -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-port 10053

        $IP6TABLES -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-port 10053 2>/dev/null || true
        $IP6TABLES -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-port 10053 2>/dev/null || true

        # =========================
        # 8. 公网允许的端口 (经过过滤)
        # =========================
        ${lib.concatStringsSep "\n" (
          map (p: ''
            $IPTABLES -A INPUT -p tcp --dport ${toString p} -j ACCEPT
            $IPTABLES -A INPUT -p udp --dport ${toString p} -j ACCEPT
            $IP6TABLES -A INPUT -p tcp --dport ${toString p} -j ACCEPT
            $IP6TABLES -A INPUT -p udp --dport ${toString p} -j ACCEPT
          '') (builtins.filter (p: !(builtins.elem p lanOnlyPortsFull)) allowedPortsFull)
        )}
      '';
      postStop = ''
        IPTABLES=${pkgs.iptables}/bin/iptables
        IP6TABLES=${pkgs.iptables}/bin/ip6tables

        # =========================
        # IPv4 清空
        # =========================
        $IPTABLES -F
        $IPTABLES -t nat -F
        $IPTABLES -t mangle -F
        $IPTABLES -t raw -F
        $IPTABLES -X
        $IPTABLES -t nat -X
        $IPTABLES -t mangle -X
        $IPTABLES -t raw -X
        $IPTABLES -P INPUT ACCEPT
        $IPTABLES -P FORWARD ACCEPT
        $IPTABLES -P OUTPUT ACCEPT

        # =========================
        # IPv6 清空
        # =========================
        $IP6TABLES -F
        $IP6TABLES -t nat -F 2>/dev/null || true
        $IP6TABLES -t mangle -F 2>/dev/null || true
        $IP6TABLES -t raw -F 2>/dev/null || true
        $IP6TABLES -X
        $IP6TABLES -t nat -X 2>/dev/null || true
        $IP6TABLES -t mangle -X 2>/dev/null || true
        $IP6TABLES -t raw -X 2>/dev/null || true
        $IP6TABLES -P INPUT ACCEPT
        $IP6TABLES -P FORWARD ACCEPT
        $IP6TABLES -P OUTPUT ACCEPT
      '';
    };
  };
}
