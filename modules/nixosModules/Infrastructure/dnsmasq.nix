{
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
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
lib.mkIf enableInfrastructure {
  # 确保防火墙允许 DNS 流量
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  virtualisation.quadlet.containers.dnsmasq = {
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
}
