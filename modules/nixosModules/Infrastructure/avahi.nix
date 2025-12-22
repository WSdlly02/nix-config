{
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
lib.mkIf enableInfrastructure {
  # services.avahi = {
  #   enable = true;
  #   publish.enable = true;
  #   nssmdns6 = true;
  #   nssmdns4 = true;
  #   ipv6 = true;
  #   ipv4 = true;
  #   extraConfig = ''
  #     [server]
  #     disallow-other-stacks=yes
  #   '';
  # };
  system = {
    nssModules = lib.optional true pkgs.nssmdns;
    nssDatabases.hosts = lib.mkForce [
      "files"
      "myhostname"
      "mdns4_minimal"
      "[NOTFOUND=return]"
      "resolve"
      "[!UNAVAIL=return]"
      "dns"
    ];
  };
  virtualisation.quadlet.containers.avahi = {
    containerConfig = {
      image = "docker.io/flungo/avahi";
      networks = [ "host" ]; # 等价于 --network host
      volumes = [ "/run/avahi-daemon:/run/avahi-daemon" ];
      user = "0";
      autoUpdate = "registry";
      environments = {
        SERVER_ALLOW_INTERFACES = "enp14s0,wlp15s0";
        #SERVER_DISALLOW_OTHER_STACKS = "true";
        #SERVER_ENABLE_DBUS = "true";
        #SERVER_USE_IPV6 = "false";
      };
      # 可选：添加环境变量等
    };

    serviceConfig = {
      Delegate = true;
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /run/avahi-daemon";
      ExecStopPost = "${pkgs.coreutils}/bin/rm -rf /run/avahi-daemon";
      Restart = "always";
      TimeoutStartSec = "300"; # 可选，延长启动超时
    };

    # 关键：启动前创建目录（/run 是 tmpfs，重启后消失）
    unitConfig = {
      Description = "Avahi mDNS daemon in Podman container";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
  };
}
