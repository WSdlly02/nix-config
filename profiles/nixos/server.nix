{ lib, pkgs, ... }:
{
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.core.netdev_max_backlog" = 16384;
    "net.core.optmem_max" = 65536;
    "net.core.rmem_default" = 1048576;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_default" = 1048576;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.bootp_relay" = 0;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.default.bootp_relay" = 0;
    "net.ipv4.conf.default.rp_filter" = 2;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.ping_group_range" = "0 2147483647";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_rmem" = "4096 1048576 2097152";
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.ipv4.udp_rmem_min" = 8192;
    "net.ipv4.udp_wmem_min" = 8192;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.disable_ipv6" = 0;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.default.disable_ipv6" = 0;
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 1;
    "kernel.randomize_va_space" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "vm.max_map_count" = 1048576;
    "vm.swappiness" = 10;
  };

  services.openssh = {
    enable = true;
    ports = [ 10022 ];
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      GatewayPorts = "yes";
      PrintMotd = true;
    };
  };

  services.logind.settings.Login = {
    NAutoVTs = 1;
    ReserveVT = 1;
  };

  environment.systemPackages = with pkgs; [
    python3
    unzip
  ];
}
