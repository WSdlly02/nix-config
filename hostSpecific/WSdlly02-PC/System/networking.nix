{
  config,
  lib,
  pkgs,
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
    config.networking.firewall.allowedUDPPorts
    ++ expandRanges config.networking.firewall.allowedUDPPortRanges;
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
      IPTABLES="${pkgs.iptables}/bin/iptables --wait"
      IP6TABLES="${pkgs.iptables}/bin/ip6tables --wait"

      # =========================
      # 1. 清空旧规则
      # =========================
      $IPTABLES --table filter --flush
      $IPTABLES --table nat --flush
      $IPTABLES --table mangle --flush
      $IPTABLES --table raw --flush
      $IPTABLES --table filter --delete-chain
      $IPTABLES --table nat --delete-chain
      $IPTABLES --table mangle --delete-chain
      $IPTABLES --table raw --delete-chain

      $IP6TABLES --table filter --flush
      $IP6TABLES --table nat --flush 2>/dev/null || true
      $IP6TABLES --table mangle --flush 2>/dev/null || true
      $IP6TABLES --table raw --flush 2>/dev/null || true
      $IP6TABLES --table filter --delete-chain
      $IP6TABLES --table nat --delete-chain 2>/dev/null || true
      $IP6TABLES --table mangle --delete-chain 2>/dev/null || true
      $IP6TABLES --table raw --delete-chain 2>/dev/null || true

      # =========================
      # 2. 默认策略
      # =========================
      $IPTABLES --table filter --policy INPUT DROP
      $IPTABLES --table filter --policy FORWARD DROP
      $IPTABLES --table filter --policy OUTPUT ACCEPT

      $IP6TABLES --table filter --policy INPUT DROP
      $IP6TABLES --table filter --policy FORWARD DROP
      $IP6TABLES --table filter --policy OUTPUT ACCEPT

      # =========================
      # 3. 基础放行（本地 & 已建立连接）
      # =========================
      $IPTABLES --table filter --append INPUT --in-interface lo --jump ACCEPT # 允许本地回环
      $IPTABLES --table filter --append INPUT --in-interface tun-mihomo --jump ACCEPT # mihomo
      $IPTABLES --table filter --append INPUT --in-interface tun-tailscale --jump ACCEPT # tailscale
      $IPTABLES --table filter --append INPUT --in-interface bridge-vm --jump ACCEPT # VMs
      $IPTABLES --table filter --append INPUT --protocol icmp --jump ACCEPT # 允许 ping

      $IP6TABLES --table filter --append INPUT --in-interface lo --jump ACCEPT
      $IP6TABLES --table filter --append INPUT --in-interface tun-mihomo --jump ACCEPT
      $IP6TABLES --table filter --append INPUT --in-interface tun-tailscale --jump ACCEPT
      $IP6TABLES --table filter --append INPUT --in-interface bridge-vm --jump ACCEPT
      $IP6TABLES --table filter --append INPUT --protocol icmpv6 --jump ACCEPT # IPv6 必需的 ICMPv6 (邻居发现/PMTU)

      $IPTABLES --table filter --append INPUT --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT # 已建立/相关连接
      $IPTABLES --table filter --append FORWARD --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT

      $IP6TABLES --table filter --append INPUT --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT
      $IP6TABLES --table filter --append FORWARD --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT

      # =========================
      # 4. 允许局域网流量
      # =========================
      $IPTABLES --table filter --append INPUT --source 192.168.0.0/16 --jump ACCEPT          # 局域网
      $IPTABLES --table filter --append INPUT --source 10.42.0.0/24 --jump ACCEPT            # 热点子网
      $IPTABLES --table filter --append INPUT --destination 224.0.0.0/4 --jump ACCEPT        # IPv4 多播

      $IP6TABLES --table filter --append INPUT --source fe80::/10 --jump ACCEPT        # IPv6 链路本地地址
      $IP6TABLES --table filter --append INPUT --destination ff00::/8 --jump ACCEPT    # IPv6 组播地址

      # =========================
      # 5. 放行DHCP广播
      # =========================
      $IPTABLES --table filter --append INPUT --protocol udp --sport 67 --dport 68 --jump ACCEPT
      $IPTABLES --table filter --append INPUT --protocol udp --sport 68 --dport 67 --jump ACCEPT

      # =========================
      # 6. 热点转发与 NAT
      # =========================
      $IPTABLES --table filter --append FORWARD --source 10.42.0.0/24 --jump ACCEPT # 允许热点设备新建连接
      $IPTABLES --table nat --append POSTROUTING --source 10.42.0.0/24 --jump MASQUERADE

      # =========================
      # 7. DNS 劫持到 mihomo:10053
      # =========================
      # 局域网、热点设备 DNS
      $IPTABLES --table nat --append PREROUTING --source 192.168.0.0/16 --protocol udp --dport 53 --jump REDIRECT --to-port 10053
      $IPTABLES --table nat --append PREROUTING --source 192.168.0.0/16 --protocol tcp --dport 53 --jump REDIRECT --to-port 10053
      $IPTABLES --table nat --append PREROUTING --source 10.42.0.0/24 --protocol udp --dport 53 --jump REDIRECT --to-port 10053
      $IPTABLES --table nat --append PREROUTING --source 10.42.0.0/24 --protocol tcp --dport 53 --jump REDIRECT --to-port 10053

      # 本机 DNS
      $IPTABLES --table nat --append OUTPUT --protocol udp --dport 53 --jump REDIRECT --to-port 10053
      $IPTABLES --table nat --append OUTPUT --protocol tcp --dport 53 --jump REDIRECT --to-port 10053

      $IP6TABLES --table nat --append OUTPUT --protocol udp --dport 53 --jump REDIRECT --to-port 10053 2>/dev/null || true
      $IP6TABLES --table nat --append OUTPUT --protocol tcp --dport 53 --jump REDIRECT --to-port 10053 2>/dev/null || true

      # =========================
      # 8. 公网允许的端口 (经过过滤)
      # =========================
      ${lib.concatStringsSep "\n" (
        map (p: ''
          $IPTABLES --table filter --append INPUT --protocol udp --dport ${toString p} --jump ACCEPT
          $IPTABLES --table filter --append INPUT --protocol tcp --dport ${toString p} --jump ACCEPT

          $IP6TABLES --table filter --append INPUT --protocol udp --dport ${toString p} --jump ACCEPT
          $IP6TABLES --table filter --append INPUT --protocol tcp --dport ${toString p} --jump ACCEPT
        '') (builtins.filter (p: !(builtins.elem p lanOnlyPortsFull)) allowedPortsFull)
      )}

      # =========================
      # 9. LOGGING 链 (统一丢弃 & 日志记录)
      # =========================
      $IPTABLES --table filter --new-chain LOGGING || true
      $IP6TABLES --table filter --new-chain LOGGING || true

      # SSH 端口监控:每个源IP 3条/分钟,突发最多5条
      $IPTABLES --table filter --append LOGGING --protocol tcp --dport 22 \
        --match hashlimit --hashlimit 3/min --hashlimit-burst 5 \
        --hashlimit-mode srcip --hashlimit-name ssh_log \
        --jump LOG --log-prefix "SSH-DROP: " --log-level 4

      $IP6TABLES --table filter --append LOGGING --protocol tcp --dport 22 \
        --match hashlimit --hashlimit 3/min --hashlimit-burst 5 \
        --hashlimit-mode srcip --hashlimit-name ssh_log_v6 \
        --jump LOG --log-prefix "SSH-DROP6: " --log-level 4

      # 其它未知流量：全局 2条/分钟
      $IPTABLES --table filter --append LOGGING \
        --match limit --limit 2/min --limit-burst 5 \
        --jump LOG --log-prefix "DROP: " --log-level 4

      $IP6TABLES --table filter --append LOGGING \
        --match limit --limit 2/min --limit-burst 5 \
        --jump LOG --log-prefix "DROP6: " --log-level 4

      # 最终丢弃
      $IPTABLES --table filter --append LOGGING --jump DROP

      $IP6TABLES --table filter --append LOGGING --jump DROP

      # 把 INPUT/OUTPUT/FORWARD 最终未匹配的流量都送去 LOGGING
      $IPTABLES --table filter --append INPUT --jump LOGGING
      $IPTABLES --table filter --append FORWARD --jump LOGGING

      $IP6TABLES --table filter --append INPUT --jump LOGGING
      $IP6TABLES --table filter --append FORWARD --jump LOGGING
    '';
    postStop = ''
      IPTABLES="${pkgs.iptables}/bin/iptables --wait"
      IP6TABLES="${pkgs.iptables}/bin/ip6tables --wait"

      # =========================
      # IPv4 清空并恢复默认
      # =========================
      $IPTABLES --table filter --flush
      $IPTABLES --table nat --flush
      $IPTABLES --table mangle --flush
      $IPTABLES --table raw --flush
      $IPTABLES --table filter --delete-chain
      $IPTABLES --table nat --delete-chain
      $IPTABLES --table mangle --delete-chain
      $IPTABLES --table raw --delete-chain

      $IPTABLES --table filter --policy INPUT ACCEPT
      $IPTABLES --table filter --policy FORWARD ACCEPT
      $IPTABLES --table filter --policy OUTPUT ACCEPT

      # =========================
      # IPv6 清空并恢复默认
      # =========================
      $IP6TABLES --table filter --flush
      $IP6TABLES --table nat --flush 2>/dev/null || true
      $IP6TABLES --table mangle --flush 2>/dev/null || true
      $IP6TABLES --table raw --flush 2>/dev/null || true
      $IP6TABLES --table filter --delete-chain
      $IP6TABLES --table nat --delete-chain 2>/dev/null || true
      $IP6TABLES --table mangle --delete-chain 2>/dev/null || true
      $IP6TABLES --table raw --delete-chain 2>/dev/null || true

      $IP6TABLES --table filter --policy INPUT ACCEPT
      $IP6TABLES --table filter --policy FORWARD ACCEPT
      $IP6TABLES --table filter --policy OUTPUT ACCEPT
    '';
  };
}
