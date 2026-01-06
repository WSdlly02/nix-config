{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation.quadlet = {
    enable = true;
    autoUpdate.enable = true;
    autoEscape = true;
    pods.mihomo-updater-pod = {
      podConfig.publishPorts = [ "127.0.0.1:8087:8088" ];
      unitConfig = {
        Description = "Pod for Mihomo Updater and Subconverter";
        StopWhenUnneeded = true;
      };
    };
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
      Requires = [ "mihomo-updater-proxy.socket" ];
      After = [ "mihomo-updater-proxy.socket" ];
    };
    Service = {
      Environment = [
        "SERVICES_START_ORDER=\"mihomo-updater-pod-pod.service subconverter.service mihomo-updater.service\""
        "SERVICES_STOP_ORDER=\"mihomo-updater.service subconverter.service mihomo-updater-pod-pod.service\""
      ];
      TimeoutStartSec = 300;
      ExecStartPre = pkgs.utils-self.systemd-user-serializedStarter "mihomo-updater-proxy";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=600 127.0.0.1:8087";
      # 10分钟无流量则退出
      ExecStopPost = pkgs.utils-self.systemd-user-serializedStopper "mihomo-updater-proxy";
    };
  };
  systemd.user.services = {
    mihomo-updater.Install.WantedBy = lib.mkForce [ ];
    subconverter.Install.WantedBy = lib.mkForce [ ];
    mihomo-updater-pod-pod.Install.WantedBy = lib.mkForce [ ];
  };
}
/*
  启动依赖说明：
  只有socket服务自启动
  mihomo-updater-proxy.socket
    |-> mihomo-updater-proxy.service
          |-> mihomo-updater-pod-pod.service
          |-> subconverter.service
          |-> mihomo-updater.service
          |-> systemd-socket-proxyd

  停止依赖说明：
  mihomo-updater-proxy.service
    |-> mihomo-updater.service
    |-> subconverter.service
    |-> mihomo-updater-pod-pod.service
*/
