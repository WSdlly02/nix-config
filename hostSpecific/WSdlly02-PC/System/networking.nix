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
      # 定义 iptables 命令路径，--wait 参数防止锁竞争导致规则应用失败
      IPTABLES="${pkgs.iptables}/bin/iptables --wait"
      IP6TABLES="${pkgs.iptables}/bin/ip6tables --wait"

      # =========================
      # 1. 清空旧规则
      # =========================
      # 清空 filter 表的所有规则
      $IPTABLES --table filter --flush
      # 清空 nat 表的所有规则
      $IPTABLES --table nat --flush
      # 清空 mangle 表的所有规则
      $IPTABLES --table mangle --flush
      # 清空 raw 表的所有规则
      $IPTABLES --table raw --flush
      # 删除 filter 表中的自定义链
      $IPTABLES --table filter --delete-chain
      # 删除 nat 表中的自定义链
      $IPTABLES --table nat --delete-chain
      # 删除 mangle 表中的自定义链
      $IPTABLES --table mangle --delete-chain
      # 删除 raw 表中的自定义链
      $IPTABLES --table raw --delete-chain

      # IPv6: 清空 filter 表
      $IP6TABLES --table filter --flush
      # IPv6: 清空 nat 表 (如果内核不支持可能报错，所以忽略错误)
      $IP6TABLES --table nat --flush 2>/dev/null || true
      # IPv6: 清空 mangle 表
      $IP6TABLES --table mangle --flush 2>/dev/null || true
      # IPv6: 清空 raw 表
      $IP6TABLES --table raw --flush 2>/dev/null || true
      # IPv6: 删除自定义链
      $IP6TABLES --table filter --delete-chain
      $IP6TABLES --table nat --delete-chain 2>/dev/null || true
      $IP6TABLES --table mangle --delete-chain 2>/dev/null || true
      $IP6TABLES --table raw --delete-chain 2>/dev/null || true

      # =========================
      # 2. 设置默认策略
      # =========================
      # 默认丢弃进入本机的数据包 (白名单模式)
      $IPTABLES --table filter --policy INPUT DROP
      # 默认丢弃经过本机转发的数据包
      $IPTABLES --table filter --policy FORWARD DROP
      # 默认允许本机发出的数据包
      $IPTABLES --table filter --policy OUTPUT ACCEPT

      # IPv6: 同样的默认策略
      $IP6TABLES --table filter --policy INPUT DROP
      $IP6TABLES --table filter --policy FORWARD DROP
      $IP6TABLES --table filter --policy OUTPUT ACCEPT

      # =========================
      # 3. 基础状态与安全检查 (通用)
      # =========================
      # 丢弃状态为 INVALID (无效) 的包，防止畸形包攻击或无效连接占用资源
      $IPTABLES --table filter --append INPUT --match conntrack --ctstate INVALID --jump DROP
      $IPTABLES --table filter --append FORWARD --match conntrack --ctstate INVALID --jump DROP

      # 允许已建立 (ESTABLISHED) 和相关 (RELATED) 的连接通过 INPUT 链 (回包)
      $IPTABLES --table filter --append INPUT --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT
      # 允许已建立 (ESTABLISHED) 和相关 (RELATED) 的连接通过 FORWARD 链 (转发回包)
      $IPTABLES --table filter --append FORWARD --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT

      # IPv6: 同样的状态检查
      $IP6TABLES --table filter --append INPUT --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT
      $IP6TABLES --table filter --append FORWARD --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT

      # =========================
      # 4. 本机接口放行 (INPUT)
      # =========================
      # 允许本地回环接口 (localhost) 的所有流量
      $IPTABLES --table filter --append INPUT --in-interface lo --jump ACCEPT
      # 允许 mihomo (Clash) 虚拟网卡的入站流量
      $IPTABLES --table filter --append INPUT --in-interface tun-mihomo --jump ACCEPT
      # 允许 tailscale VPN 接口的入站流量
      $IPTABLES --table filter --append INPUT --in-interface tun-tailscale --jump ACCEPT
      # 允许虚拟机网桥的入站流量
      $IPTABLES --table filter --append INPUT --in-interface bridge-vm --jump ACCEPT
      # 允许 ICMP 协议 (Ping)，方便网络诊断
      $IPTABLES --table filter --append INPUT --protocol icmp --jump ACCEPT

      # IPv6: 接口放行
      $IP6TABLES --table filter --append INPUT --in-interface lo --jump ACCEPT
      $IP6TABLES --table filter --append INPUT --in-interface tun-mihomo --jump ACCEPT
      $IP6TABLES --table filter --append INPUT --in-interface tun-tailscale --jump ACCEPT
      $IP6TABLES --table filter --append INPUT --in-interface bridge-vm --jump ACCEPT
      # IPv6: 必须允许 ICMPv6，因为它承载了邻居发现(NDP)等核心功能，否则 IPv6 会断网
      $IP6TABLES --table filter --append INPUT --protocol icmpv6 --jump ACCEPT

      # =========================
      # 5. 局域网访问本机 (INPUT)
      # =========================
      # 允许局域网 (192.168.0.0/16) 访问本机 (如 SSH, DNS, Web后台)
      $IPTABLES --table filter --append INPUT --source 192.168.0.0/16 --jump ACCEPT
      # 允许热点子网 (10.42.0.0/24) 访问本机
      $IPTABLES --table filter --append INPUT --source 10.42.0.0/24 --jump ACCEPT
      # 允许 IPv4 组播流量 (DLNA/Bonjour 等发现协议需要)
      $IPTABLES --table filter --append INPUT --destination 224.0.0.0/4 --jump ACCEPT

      # IPv6: 允许链路本地地址通信
      $IP6TABLES --table filter --append INPUT --source fe80::/10 --jump ACCEPT
      # IPv6: 允许组播
      $IP6TABLES --table filter --append INPUT --destination ff00::/8 --jump ACCEPT

      # =========================
      # 6. DHCP 服务放行 (INPUT)
      # =========================
      # 允许 DHCP 请求：UDP 67(Server) <-> 68(Client)
      $IPTABLES --table filter --append INPUT --protocol udp --sport 67 --dport 68 --jump ACCEPT
      $IPTABLES --table filter --append INPUT --protocol udp --sport 68 --dport 67 --jump ACCEPT

      # =========================
      # 7. 转发与 NAT
      # =========================
      # 允许局域网 (192.168.x.x) 发起转发请求 (访问互联网)
      $IPTABLES --table filter --append FORWARD --source 192.168.0.0/16 --jump ACCEPT
      # 对局域网流量进行 NAT 伪装 (MASQUERADE)，使其能通过本机公网接口上网
      $IPTABLES --table nat --append POSTROUTING --source 192.168.0.0/16 --jump MASQUERADE

      # 允许热点子网发起转发请求
      $IPTABLES --table filter --append FORWARD --source 10.42.0.0/24 --jump ACCEPT
      # 对热点流量进行 NAT 伪装
      $IPTABLES --table nat --append POSTROUTING --source 10.42.0.0/24 --jump MASQUERADE

      # =========================
      # 8. DNS 透明代理/劫持 (REDIRECT)
      # =========================

      # 劫持局域网 UDP 53 到本机 10053
      $IPTABLES --table nat --append PREROUTING --source 192.168.0.0/16 --protocol udp --dport 53 --jump REDIRECT --to-port 10053
      # 劫持局域网 TCP 53 到本机 10053
      $IPTABLES --table nat --append PREROUTING --source 192.168.0.0/16 --protocol tcp --dport 53 --jump REDIRECT --to-port 10053

      # 劫持热点 UDP 53 到本机 10053
      $IPTABLES --table nat --append PREROUTING --source 10.42.0.0/24 --protocol udp --dport 53 --jump REDIRECT --to-port 10053
      # 劫持热点 TCP 53 到本机 10053
      $IPTABLES --table nat --append PREROUTING --source 10.42.0.0/24 --protocol tcp --dport 53 --jump REDIRECT --to-port 10053

      # 劫持本机发出的 DNS 请求 (慎用：需防止 Mihomo 自身死循环)
      # 逻辑：如果是 mihomo 用户发出的包，不进行 REDIRECT (隐式 ACCEPT)
      # 如果是其他用户 (root, your_user, etc)，则执行 REDIRECT

      # 排除 mihomo 用户
      # ! --uid-owner mihomo 表示 "不是 mihomo 用户时"
      $IPTABLES --table nat --append OUTPUT --protocol udp --dport 53 \
        --match owner ! --uid-owner mihomo \
        --jump REDIRECT --to-port 10053
        
      $IPTABLES --table nat --append OUTPUT --protocol tcp --dport 53 \
        --match owner ! --uid-owner mihomo \
        --jump REDIRECT --to-port 10053
        
      # IPv6 处理 (如果有 IPv6 需求)
      $IP6TABLES --table nat --append OUTPUT --protocol udp --dport 53 \
        --match owner ! --uid-owner mihomo \
        --jump REDIRECT --to-port 10053 2>/dev/null || true

      $IP6TABLES --table nat --append OUTPUT --protocol tcp --dport 53 \
        --match owner ! --uid-owner mihomo \
        --jump REDIRECT --to-port 10053 2>/dev/null || true

      # =========================
      # 9. 放行特定公网端口 (INPUT)
      # =========================
      # 使用 Nix 语法遍历 finalAllowedPortsFull 列表，为每个端口生成 ACCEPT 规则
      # 允许公网访问的端口: ${toString finalAllowedPortsFull}
      ${lib.concatStringsSep "\n" (
        map (p: ''
          $IPTABLES --table filter --append INPUT --protocol udp --dport ${toString p} --jump ACCEPT
          $IPTABLES --table filter --append INPUT --protocol tcp --dport ${toString p} --jump ACCEPT

          $IP6TABLES --table filter --append INPUT --protocol udp --dport ${toString p} --jump ACCEPT
          $IP6TABLES --table filter --append INPUT --protocol tcp --dport ${toString p} --jump ACCEPT
        '') finalAllowedPortsFull
      )}

      # =========================
      # 10. 日志与最终丢弃 (LOGGING)
      # =========================
      # 新建 LOGGING 链，如果已存在则忽略错误
      $IPTABLES --table filter --new-chain LOGGING || true
      $IP6TABLES --table filter --new-chain LOGGING || true

      # SSH (端口22) 防爆破日志：限制记录频率为每分钟3条，突发5条，按源IP记录
      $IPTABLES --table filter --append LOGGING --protocol tcp --dport 22 \
        --match hashlimit --hashlimit 3/min --hashlimit-burst 5 \
        --hashlimit-mode srcip --hashlimit-name ssh_log \
        --jump LOG --log-prefix "SSH-DROP: " --log-level 4

      # IPv6 SSH 日志
      $IP6TABLES --table filter --append LOGGING --protocol tcp --dport 22 \
        --match hashlimit --hashlimit 3/min --hashlimit-burst 5 \
        --hashlimit-mode srcip --hashlimit-name ssh_log_v6 \
        --jump LOG --log-prefix "SSH-DROP6: " --log-level 4

      # 其他被丢弃流量的日志：全局限制每分钟2条，防止日志刷屏
      $IPTABLES --table filter --append LOGGING \
        --match limit --limit 2/min --limit-burst 5 \
        --jump LOG --log-prefix "DROP: " --log-level 4

      # IPv6 其他丢弃日志
      $IP6TABLES --table filter --append LOGGING \
        --match limit --limit 2/min --limit-burst 5 \
        --jump LOG --log-prefix "DROP6: " --log-level 4

      # 记录日志后，执行丢弃 (DROP) 动作
      $IPTABLES --table filter --append LOGGING --jump DROP
      $IP6TABLES --table filter --append LOGGING --jump DROP

      # 将 INPUT 链中未匹配的流量转到 LOGGING 链处理
      $IPTABLES --table filter --append INPUT --jump LOGGING
      # 将 FORWARD 链中未匹配的流量转到 LOGGING 链处理 (防止未授权转发)
      $IPTABLES --table filter --append FORWARD --jump LOGGING

      # IPv6: 同样的末尾处理
      $IP6TABLES --table filter --append INPUT --jump LOGGING
      $IP6TABLES --table filter --append FORWARD --jump LOGGING
    '';
    postStop = ''
      IPTABLES="${pkgs.iptables}/bin/iptables --wait"
      IP6TABLES="${pkgs.iptables}/bin/ip6tables --wait"

      # =========================
      # 1. 优先恢复默认策略为 ACCEPT (防止清空规则时断网)
      # =========================
      # 必须最先执行，确保接下来的 flush 操作不会因为默认 DROP 策略而切断连接
      $IPTABLES --table filter --policy INPUT ACCEPT
      $IPTABLES --table filter --policy FORWARD ACCEPT
      $IPTABLES --table filter --policy OUTPUT ACCEPT

      $IP6TABLES --table filter --policy INPUT ACCEPT
      $IP6TABLES --table filter --policy FORWARD ACCEPT
      $IP6TABLES --table filter --policy OUTPUT ACCEPT

      # =========================
      # 2. IPv4 清空规则与链
      # =========================
      # 只有在策略已经是 ACCEPT 的情况下，flush 才是安全的
      $IPTABLES --table filter --flush
      $IPTABLES --table nat --flush
      $IPTABLES --table mangle --flush
      $IPTABLES --table raw --flush

      $IPTABLES --table filter --delete-chain
      $IPTABLES --table nat --delete-chain
      $IPTABLES --table mangle --delete-chain
      $IPTABLES --table raw --delete-chain

      # =========================
      # 3. IPv6 清空规则与链
      # =========================
      $IP6TABLES --table filter --flush
      $IP6TABLES --table nat --flush 2>/dev/null || true
      $IP6TABLES --table mangle --flush 2>/dev/null || true
      $IP6TABLES --table raw --flush 2>/dev/null || true

      $IP6TABLES --table filter --delete-chain
      $IP6TABLES --table nat --delete-chain 2>/dev/null || true
      $IP6TABLES --table mangle --delete-chain 2>/dev/null || true
      $IP6TABLES --table raw --delete-chain 2>/dev/null || true
    '';
  };
}
