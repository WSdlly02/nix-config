{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation.quadlet.pods.ollama-pod = {
    podConfig.publishPorts = [
      "127.0.0.1:11433:11434"
      "127.0.0.1:7442:443"
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
      volumes = [ "%h/.ollama:/root/.ollama" ];
      devices = [
        "/dev/kfd"
        "/dev/dri"
      ];
      environments = {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
        OLLAMA_ORIGINS = "*";
        OLLAMA_HOST = "0.0.0.0";
        OLLAMA_FLASH_ATTENTION = "1";
      };
      autoUpdate = "registry";
    };
    serviceConfig = {
      Delegate = true;
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/.ollama";
      Restart = "on-failure";
      TimeoutStartSec = "300";
    };
    unitConfig = {
      Description = "Ollama ROCm in Podman container";
      StopWhenUnneeded = true;
    };
  };
  systemd.user.sockets.ollama-proxy = {
    Unit.Description = "Socket for Ollama Proxy with IP Filtering";
    Socket = {
      ListenStream = "[::]:11434";
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
  systemd.user.services.ollama-proxy = {
    Unit = {
      Description = "Proxy for Ollama with IP Filtering";
      # Shared backends stay needed while either proxy is active.
      Requires = [
        "ollama-proxy.socket"
        "ollama-pod-pod.service"
        "ollama.service"
      ];
      After = [
        "ollama-proxy.socket"
        "ollama-pod-pod.service"
        "ollama.service"
      ];
    };
    Service = {
      TimeoutStartSec = 300;
      # Probe the backend directly; keep incoming connections queued on the socket.
      ExecStartPre = pkgs.utils-self.systemd-user-waitHTTP {
        name = "ollama";
        url = "http://127.0.0.1:11433/api/version";
      };
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:11433";
    };
  };
  systemd.user.services = {
    ollama.Install.WantedBy = lib.mkForce [ ];
    ollama-omni-ocr.Install.WantedBy = lib.mkForce [ ];
    ollama-pod-pod.Install.WantedBy = lib.mkForce [ ];
  };
}
