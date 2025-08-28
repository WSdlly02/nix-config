{
  config,
  lib,
  enableInfrastructure,
  ...
}:
{
  config = lib.mkIf enableInfrastructure {
    boot.kernel.sysctl = {
      # Network performance
      "net.core.netdev_max_backlog" = 16384;
      "net.core.rmem_default" = 1048576;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_default" = 1048576;
      "net.core.wmem_max" = 16777216;
      "net.core.optmem_max" = 65536;
      "net.core.default_qdisc" = "cake";
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
      # System
      "vm.max_map_count" = 2147483642;
      "vm.swappiness" = config.hostSystemSpecific.boot.kernel.sysctl."vm.swappiness";
    };
  };
}
