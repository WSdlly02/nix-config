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
        "10.144.144.0/24"
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
      # Shared backends stay needed while either proxy is active.
      Requires = [
        "ollama-omni-ocr-proxy.socket"
        "ollama-pod-pod.service"
        "ollama.service"
        "ollama-omni-ocr.service"
      ];
      After = [
        "ollama-omni-ocr-proxy.socket"
        "ollama-pod-pod.service"
        "ollama.service"
        "ollama-omni-ocr.service"
      ];
    };
    Service = {
      TimeoutStartSec = 300;
      # Probe the backend directly; keep incoming connections queued on the socket.
      ExecStartPre = pkgs.utils-self.systemd-user-waitHTTP {
        name = "omni-ocr";
        url = "https://127.0.0.1:7442/ollama/api/version";
        insecure = true; # Caddy uses its internal CA on this loopback endpoint.
      };
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:7442";
    };
  };
}
