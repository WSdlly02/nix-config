{ lib, ... }:
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
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_rmem" = "4096 1048576 2097152";
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.ipv4.udp_rmem_min" = 8192;
    "net.ipv4.udp_wmem_min" = 8192;
    "net.ipv6.conf.all.accept_redirects" = 0; # 禁止 IPv6 Redirect
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "kernel.randomize_va_space" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;

    "vm.swappiness" = lib.mkDefault 20;
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
}
