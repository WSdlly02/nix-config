{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation.quadlet.pods.ollama-pod = {
    podConfig.publishPorts = [
      "127.0.0.1:11433:11434" # Ollama 主服务端口
      "127.0.0.1:7442:443" # Ollama Omni OCR HTTPS 端口
    ];
    unitConfig = {
      Description = "Pod for Ollama ROCm and Ollama Omni OCR";
      StopWhenUnneeded = true;
    };
  };
  virtualisation.quadlet.containers.ollama = {
    containerConfig = {
      image = "docker.io/ollama/ollama:rocm";
      pod = config.virtualisation.quadlet.pods.ollama-pod.ref;
      volumes = [ "${config.home.homeDirectory}/.ollama:/root/.ollama" ];
      devices = [
        "/dev/kfd"
        "/dev/dri"
      ];
      environments = {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
        OLLAMA_ORIGINS = "*";
        OLLAMA_HOST = "0.0.0.0";
        # Ollama configuration envs
        OLLAMA_FLASH_ATTENTION = "1";
      };
      autoUpdate = "registry";
    };
    serviceConfig = {
      Delegate = true;
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.ollama";
      Restart = "on-failure";
      TimeoutStartSec = "300";
    };
    unitConfig = {
      Description = "Ollama ROCm in Podman container";
      Requires = [ "ollama-pod-pod.service" ];
      After = [ "ollama-pod-pod.service" ];
      BindsTo = [ "ollama-proxy.service" ];
      StopWhenUnneeded = true;
    };
  };
  # 1. Systemd Socket 监听 11434 端口并进行 IP 过滤
  systemd.user.sockets.ollama-proxy = {
    Unit.Description = "Socket for Ollama Proxy with IP Filtering";
    Socket = {
      ListenStream = "0.0.0.0:11434";
      # 限制访问来源：本地、LAN、Tailscale
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

  # 2. Socket Proxy 服务：转发流量到容器监听的 11435 端口
  systemd.user.services.ollama-proxy = {
    Unit = {
      Description = "Proxy for Ollama with IP Filtering";
      # 确保容器服务在代理启动时也启动
      Requires = [ "ollama.service" ];
      After = [ "ollama.service" ];
    };
    Service = {
      ExecStart = ''
        ${pkgs.systemd}/lib/systemd/systemd-socket-proxyd \
          # --exit-idle-time=600 \ # 可选：空闲10分钟后退出
          127.0.0.1:11433
      '';
    };
  };
  systemd.user.services = {
    ollama.Install.WantedBy = lib.mkForce [ ];
    ollama-omni-ocr.Install.WantedBy = lib.mkForce [ ];
    ollama-pod-pod.Install.WantedBy = lib.mkForce [ ];
  };
}
