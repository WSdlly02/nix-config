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
      Requires = [ "ollama-omni-ocr-proxy.socket" ];
      After = [ "ollama-omni-ocr-proxy.socket" ];
    };
    Service = {
      Environment = [
        "SERVICES_START_ORDER=\"ollama-pod-pod.service ollama.service ollama-omni-ocr.service\""
        "SERVICES_STOP_ORDER=\"ollama-omni-ocr.service\""
      ];
      TimeoutStartSec = 300;
      ExecStartPre = pkgs.utils-self.systemd-user-serializedStarter "ollama-omni-ocr-proxy";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:7442";
      ExecStopPost = pkgs.utils-self.systemd-user-serializedStopper "ollama-omni-ocr-proxy";
    };
  };
}
/*
  启动依赖说明：
  只有socket服务自启动
  ollama-proxy.socket
    |-> ollama-proxy.service
          |-> ollama-pod-pod.service
          |-> ollama.service
          |-> systemd-socket-proxyd
  ollama-omni-ocr-proxy.socket
    |-> ollama-omni-ocr-proxy.service
          |-> ollama-pod-pod.service
          |-> ollama.service
          |-> ollama-omni-ocr.service
          |-> systemd-socket-proxyd

  停止依赖说明：
  ollama-proxy.service
    |-> ollama.service
    |-> ollama-pod-pod.service
  ollama-omni-ocr-proxy.service
    |-> ollama-omni-ocr.service
        ollama.service 独立停止，不在这里处理
*/
