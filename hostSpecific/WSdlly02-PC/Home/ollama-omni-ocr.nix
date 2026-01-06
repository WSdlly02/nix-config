{
  config,
  pkgs,
  ...
}:
{
  virtualisation.quadlet.containers.ollama-omni-ocr = {
    containerConfig = {
      image = "ghcr.io/wsdlly02/ollama-omni-ocr/ollama-omni-ocr:latest";
      pod = config.virtualisation.quadlet.pods.ollama-pod.ref;
      environments = {
        OLLAMA_HOST = "http://127.0.0.1:11434";
      };
      autoUpdate = "registry";
    };
    serviceConfig = {
      Delegate = true;
      Restart = "on-failure";
      TimeoutStartSec = "300";
    };
    unitConfig = {
      Description = "Ollama Omni OCR in Podman container";
      After = [
        "ollama-pod-pod.service"
        "ollama.service"
      ]; # 确保 Ollama 服务在此服务之前启动
      Requires = [
        "ollama-pod-pod.service"
        "ollama.service"
      ];
      BindsTo = [ "ollama-omni-ocr-proxy.service" ];
      StopWhenUnneeded = true;
    };
  };
  # 1. Systemd Socket 监听 7443 端口并进行 IP 过滤
  systemd.user.sockets.ollama-omni-ocr-proxy = {
    Unit.Description = "Socket for Ollama Omni OCR Proxy with IP Filtering";
    Socket = {
      ListenStream = "0.0.0.0:7443";
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

  # 2. Socket Proxy 服务：转发流量到容器监听的 7442 端口
  systemd.user.services.ollama-omni-ocr-proxy = {
    Unit = {
      Description = "Proxy for Ollama with IP Filtering";
      # 确保容器服务在代理启动时也启动
      Requires = [ "ollama-omni-ocr.service" ];
      After = [ "ollama-omni-ocr.service" ];
    };
    Service = {
      ExecStart = ''
        ${pkgs.systemd}/lib/systemd/systemd-socket-proxyd \
          # --exit-idle-time=600 \ # 可选：空闲10分钟后退出
          127.0.0.1:7442
      '';
    };
  };
}
/*
  启动依赖说明：
  ollama-proxy.socket
    |-> ollama-proxy.service
          |-<-> ollama.service
                  |-> ollama-pod-pod.service
  ollama-omni-ocr-proxy.socket
    |-> ollama-omni-ocr-proxy.service
          |-<-> ollama-omni-ocr.service
                  |-> ollama-pod-pod.service
                  |-> ollama.service
                        |-> ollama-pod-pod.service
*/
