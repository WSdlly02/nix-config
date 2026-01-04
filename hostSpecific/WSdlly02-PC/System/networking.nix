{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.networking.firewall;
  cfgHS = config.hostSystemSpecific.networking.firewall;
  expandRanges = ranges: lib.concatLists (map (r: lib.range r.from r.to) ranges);

  allowedPortsFull = lib.unique (cfg.allowedUDPPorts ++ expandRanges cfg.allowedUDPPortRanges);
  lanOnlyPortsFull = lib.unique (cfgHS.lanOnlyPorts ++ expandRanges cfgHS.lanOnlyPortRanges);
  finalAllowedPortsFull = builtins.filter (p: !(builtins.elem p lanOnlyPortsFull)) allowedPortsFull;
in
{
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
      # =========================
      # 配置区域
      # =========================
      IPTABLES="${pkgs.iptables}/bin/iptables --wait"
      IP6TABLES="${pkgs.iptables}/bin/ip6tables --wait"
      # 定义受限的物理接口，其他接口（虚拟网卡、lo等）默认放行
      RESTRICTED_INTERFACES="enp14s0 wlp15s0"

      # =========================
      # 1. 清理旧规则
      # =========================
      for TABLE in filter nat mangle raw; do
        $IPTABLES -t $TABLE -F
        $IPTABLES -t $TABLE -X
        $IP6TABLES -t $TABLE -F 2>/dev/null || true
        $IP6TABLES -t $TABLE -X 2>/dev/null || true
      done

      # =========================
      # 2. 设置默认策略 (ACCEPT)
      # =========================
      # 默认允许所有流量，仅对受限接口进行过滤
      $IPTABLES -P INPUT ACCEPT
      $IPTABLES -P FORWARD ACCEPT
      $IPTABLES -P OUTPUT ACCEPT
      $IP6TABLES -P INPUT ACCEPT
      $IP6TABLES -P FORWARD ACCEPT
      $IP6TABLES -P OUTPUT ACCEPT

      # =========================
      # 3. 创建自定义链
      # =========================
      # 用于处理受限接口的入站流量
      $IPTABLES -N RESTRICTED_IN
      $IP6TABLES -N RESTRICTED_IN
      # 用于处理受限接口的转发流量
      $IPTABLES -N RESTRICTED_FWD
      $IP6TABLES -N RESTRICTED_FWD
      # 日志记录链
      $IPTABLES -N LOG_DROP
      $IP6TABLES -N LOG_DROP

      # =========================
      # 4. 绑定接口到自定义链
      # =========================
      for IFACE in $RESTRICTED_INTERFACES; do
        $IPTABLES -A INPUT -i $IFACE -j RESTRICTED_IN
        $IPTABLES -A FORWARD -i $IFACE -j RESTRICTED_FWD
        $IP6TABLES -A INPUT -i $IFACE -j RESTRICTED_IN
        $IP6TABLES -A FORWARD -i $IFACE -j RESTRICTED_FWD
      done

      # =========================
      # 5. 配置日志链 (LOG_DROP)
      # =========================
      # SSH 防爆破日志
      $IPTABLES -A LOG_DROP -p tcp --dport 22 \
        -m hashlimit --hashlimit 3/min --hashlimit-burst 5 \
        --hashlimit-mode srcip --hashlimit-name ssh_log \
        -j LOG --log-prefix "SSH-DROP: " --log-level 4

      $IP6TABLES -A LOG_DROP -p tcp --dport 22 \
        -m hashlimit --hashlimit 3/min --hashlimit-burst 5 \
        --hashlimit-mode srcip --hashlimit-name ssh_log_v6 \
        -j LOG --log-prefix "SSH-DROP6: " --log-level 4

      # 通用丢弃日志
      $IPTABLES -A LOG_DROP -m limit --limit 2/min --limit-burst 5 -j LOG --log-prefix "DROP: " --log-level 4
      $IP6TABLES -A LOG_DROP -m limit --limit 2/min --limit-burst 5 -j LOG --log-prefix "DROP6: " --log-level 4

      # 最终丢弃
      $IPTABLES -A LOG_DROP -j DROP
      $IP6TABLES -A LOG_DROP -j DROP

      # =========================
      # 6. 配置受限入站规则 (RESTRICTED_IN)
      # =========================
      # 允许已建立的连接
      $IPTABLES -A RESTRICTED_IN -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      $IP6TABLES -A RESTRICTED_IN -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

      # 丢弃无效包
      $IPTABLES -A RESTRICTED_IN -m conntrack --ctstate INVALID -j DROP
      $IP6TABLES -A RESTRICTED_IN -m conntrack --ctstate INVALID -j DROP

      # 允许 ICMP / IGMP
      $IPTABLES -A RESTRICTED_IN -p icmp -j ACCEPT
      $IPTABLES -A RESTRICTED_IN -p igmp -j ACCEPT
      $IP6TABLES -A RESTRICTED_IN -p icmpv6 -j ACCEPT

      # 允许可信子网 (LAN/Hotspot/Link-Local)
      $IPTABLES -A RESTRICTED_IN -s 192.168.0.0/16 -j ACCEPT
      $IPTABLES -A RESTRICTED_IN -s 10.42.0.0/16 -j ACCEPT
      $IPTABLES -A RESTRICTED_IN -s 169.254.0.0/16 -j ACCEPT
      $IP6TABLES -A RESTRICTED_IN -s fe80::/10 -j ACCEPT

      # 允许组播/广播
      $IPTABLES -A RESTRICTED_IN -d 224.0.0.0/4 -j ACCEPT
      $IP6TABLES -A RESTRICTED_IN -d ff00::/8 -j ACCEPT

      # 允许 DHCP
      $IPTABLES -A RESTRICTED_IN -p udp --sport 67 --dport 68 -j ACCEPT
      $IPTABLES -A RESTRICTED_IN -p udp --sport 68 --dport 67 -j ACCEPT

      # 允许特定公网端口
      ${lib.concatStringsSep "\n" (
        map (p: ''
          $IPTABLES -A RESTRICTED_IN -p udp --dport ${toString p} -j ACCEPT
          $IPTABLES -A RESTRICTED_IN -p tcp --dport ${toString p} -j ACCEPT
          $IP6TABLES -A RESTRICTED_IN -p udp --dport ${toString p} -j ACCEPT
          $IP6TABLES -A RESTRICTED_IN -p tcp --dport ${toString p} -j ACCEPT
        '') finalAllowedPortsFull
      )}

      # 其余丢弃
      $IPTABLES -A RESTRICTED_IN -j LOG_DROP
      $IP6TABLES -A RESTRICTED_IN -j LOG_DROP

      # =========================
      # 7. 配置受限转发规则 (RESTRICTED_FWD)
      # =========================
      # 允许已建立的连接
      $IPTABLES -A RESTRICTED_FWD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      $IP6TABLES -A RESTRICTED_FWD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

      # 丢弃无效包
      $IPTABLES -A RESTRICTED_FWD -m conntrack --ctstate INVALID -j DROP
      $IP6TABLES -A RESTRICTED_FWD -m conntrack --ctstate INVALID -j DROP

      # 允许可信子网转发 (上网)
      $IPTABLES -A RESTRICTED_FWD -s 192.168.0.0/16 -j ACCEPT
      $IPTABLES -A RESTRICTED_FWD -s 10.42.0.0/16 -j ACCEPT

      # 其余丢弃
      $IPTABLES -A RESTRICTED_FWD -j LOG_DROP
      $IP6TABLES -A RESTRICTED_FWD -j LOG_DROP

      # =========================
      # 8. NAT 设置 (POSTROUTING)
      # =========================
      $IPTABLES -t nat -A POSTROUTING -s 192.168.0.0/16 -j MASQUERADE
      $IPTABLES -t nat -A POSTROUTING -s 10.42.0.0/16 -j MASQUERADE
    '';
    postStop = ''
      IPTABLES="${pkgs.iptables}/bin/iptables --wait"
      IP6TABLES="${pkgs.iptables}/bin/ip6tables --wait"

      # =========================
      # 1. 优先恢复默认策略为 ACCEPT (防止清空规则时断网)
      # =========================
      # 必须最先执行，确保接下来的 flush 操作不会因为默认 DROP 策略而切断连接
      $IPTABLES -P INPUT ACCEPT
      $IPTABLES -P FORWARD ACCEPT
      $IPTABLES -P OUTPUT ACCEPT

      $IP6TABLES -P INPUT ACCEPT
      $IP6TABLES -P FORWARD ACCEPT
      $IP6TABLES -P OUTPUT ACCEPT

      # =========================
      # 2. IPv4 清空规则与链
      # =========================
      # 只有在策略已经是 ACCEPT 的情况下，flush 才是安全的
      for TABLE in filter nat mangle raw; do
        $IPTABLES -t $TABLE -F
        $IPTABLES -t $TABLE -X
        $IP6TABLES -t $TABLE -F 2>/dev/null || true
        $IP6TABLES -t $TABLE -X 2>/dev/null || true
      done
    '';
  };
}
