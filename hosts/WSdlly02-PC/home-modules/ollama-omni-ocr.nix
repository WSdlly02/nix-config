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
  systemd.user.sockets.ollama-omni-ocr-proxy = {
    Unit.Description = "Socket for Ollama Omni OCR Proxy with IP Filtering";
    Socket = {
      ListenStream = "[::]:7443";
      IPAddressAllow = [
        "127.0.0.1"
        "::1"
        "192.168.0.0/16"
        "fd00::/8"
        "fe80::/10"
        "100.64.16.0/24"
        "fd7a:115c:a1e0::/48"
      ];
      IPAddressDeny = "any";
    };
    Install.WantedBy = [ "sockets.target" ];
  };
  systemd.user.services.ollama-omni-ocr-proxy = {
    Unit = {
      Description = "Proxy for Ollama with IP Filtering";
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
