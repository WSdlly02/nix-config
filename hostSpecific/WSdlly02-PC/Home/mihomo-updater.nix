{ config, pkgs, ... }:
{
  virtualisation.quadlet = {
    enable = true;
    autoUpdate.enable = true;
    autoEscape = true;
    pods.mihomo-updater-pod.podConfig.publishPorts = [ "127.0.0.1:8087:8088" ];
    containers = {
      mihomo-updater = {
        containerConfig = {
          image = "ghcr.io/wsdlly02/my-codes/mihomo-updater:latest";
          pod = config.virtualisation.quadlet.pods.mihomo-updater-pod.ref;
          volumes = [ "${config.home.homeDirectory}/Documents/my-codes/SOPs/mihomo-updater/.env:/.env:ro" ];
          autoUpdate = "registry";
        };
        serviceConfig = {
          Delegate = true;
          Restart = "on-failure";
        };
        unitConfig = {
          Description = "Mihomo Updater in Podman container";
          # 必须在 subconverter 之后启动，因为它要加入后者的网络
          BindsTo = [ "mihomo-updater-proxy.service" ];
          Requires = [ "subconverter.service" ];
          After = [ "subconverter.service" ];
          StopWhenUnneeded = true;
        };
      };
      subconverter = {
        containerConfig = {
          image = "docker.io/tindy2013/subconverter:latest";
          pod = config.virtualisation.quadlet.pods.mihomo-updater-pod.ref;
          autoUpdate = "registry";
        };
        serviceConfig = {
          Delegate = true;
          Restart = "on-failure";
          # 保证subconverter能访问网络
          ExecStartPre = pkgs.writeShellScript "wait-for-mihomo-up" ''
            until ${pkgs.iproute2}/bin/ip link show mihomo0; do
              ${pkgs.coreutils}/bin/sleep 1
            done
            echo "Mihomo is ready, network is accessible."
          '';
        };
        unitConfig = {
          Description = "Subconverter in Podman container";
          # 当不再被需要时（即 mihomo-updater 停止后），自动停止
          BindsTo = [ "mihomo-updater.service" ];
          StopWhenUnneeded = true;
        };
      };
    };
  };

  # 1. Systemd Socket 监听 8088 端口
  systemd.user.sockets.mihomo-updater-proxy = {
    Unit.Description = "Socket for Mihomo Updater Proxy";
    Socket = {
      ListenStream = "0.0.0.0:8088";
      # 限制访问来源
      IPAddressAllow = [
        "127.0.0.1"
        "::1"
        "192.168.0.0/16"
        "100.64.16.0/24"
      ];
      IPAddressDeny = "any";
    };
    Install.WantedBy = [ "sockets.target" ];
  };

  # 2. Socket Proxy 服务：转发流量并管理空闲退出
  systemd.user.services.mihomo-updater-proxy = {
    Unit = {
      Description = "Proxy for Mihomo Updater with Idle Timeout";
      Requires = [ "mihomo-updater.service" ];
      After = [ "mihomo-updater.service" ];
    };
    Service = {
      # 转发到本地 18088
      # --exit-idle-time=600s (10分钟) 无流量自动退出 Proxy
      # Proxy 退出后，由于 StopWhenUnneeded=true，后端容器也会自动停止
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=600 127.0.0.1:8087";
    };
  };
}
